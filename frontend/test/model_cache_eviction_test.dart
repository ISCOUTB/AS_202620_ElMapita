import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/storage/local_storage.dart';
import 'package:frontend/features/mapas/infrastructure/storage/model_cache.dart';
import 'package:path/path.dart' as path;

/// Índice en memoria con la misma semántica que LocalStorage para los modelos.
class _FakeStorage extends Fake implements LocalStorage {
  final Map<String, String> index = {};

  @override
  Future<void> cacheModel(String b, String v, String p) async =>
      index['model_${b}_$v'] = p;

  @override
  String? getCachedModelPath(String b, String v) => index['model_${b}_$v'];

  @override
  Map<String, String> getCachedModelsOf(String b) => {
        for (final e in index.entries)
          if (e.key.startsWith('model_${b}_'))
            e.key.substring('model_${b}_'.length): e.value,
      };

  @override
  Set<String> getCachedBuildingIds() =>
      index.keys.map((k) => k.substring(6).split('_').first).toSet();

  @override
  Future<void> removeCachedModel(String b, String v) async =>
      index.remove('model_${b}_$v');
}

class _BytesAdapter implements HttpClientAdapter {
  bool fail = false;
  int requests = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s,
      Future<void>? c) async {
    requests++;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (fail) throw DioException(requestOptions: o, message: 'sin red');
    return ResponseBody.fromBytes([1, 2, 3], 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory tmp;
  late _FakeStorage storage;
  late _BytesAdapter adapter;
  late ModelCache cache;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('model_cache_test');
    storage = _FakeStorage();
    adapter = _BytesAdapter();
    cache = ModelCache(
      storage,
      dio: Dio(BaseOptions(responseType: ResponseType.bytes))
        ..httpClientAdapter = adapter,
      documentsDir: () async => tmp,
    );
  });

  tearDown(() => tmp.delete(recursive: true));

  Future<void> download(String version) => cache.getOrDownloadModel(
      buildingId: 'b1', version: version, downloadUrl: 'http://x/$version');

  File fileOf(String version) =>
      File(path.join(tmp.path, 'models', 'b1', '$version.glb'));

  test('tras descargar la v2, la v1 se borra del disco y del índice', () async {
    await download('v1');
    expect(fileOf('v1').existsSync(), isTrue);

    await download('v2');

    expect(fileOf('v1').existsSync(), isFalse);
    expect(fileOf('v2').existsSync(), isTrue);
    expect(storage.getCachedModelsOf('b1').keys, ['v2']);
  });

  test('si la descarga de la v2 falla, se conserva la v1 (uso sin red)',
      () async {
    await download('v1');
    adapter.fail = true;

    await download('v2');

    expect(fileOf('v1').existsSync(), isTrue);
    expect(storage.getCachedModelsOf('b1').keys, ['v1']);
  });

  test('dos pedidos simultáneos de la misma version hacen una sola descarga',
      () async {
    await Future.wait([download('v1'), download('v1')]);

    expect(adapter.requests, 1);
    expect(fileOf('v1').existsSync(), isTrue);
  });

  test('si la descarga compartida falla, el siguiente pedido reintenta',
      () async {
    adapter.fail = true;
    await Future.wait([download('v1'), download('v1')]);
    adapter.fail = false;
    await download('v1');

    expect(fileOf('v1').existsSync(), isTrue);
  });

  test('clearAllCache vacía disco e índice', () async {
    await download('v1');
    await cache.clearAllCache();

    expect(fileOf('v1').existsSync(), isFalse);
    expect(storage.index, isEmpty);
  });
}
