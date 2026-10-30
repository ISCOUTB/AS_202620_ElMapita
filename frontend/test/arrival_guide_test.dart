import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/mapas/domain/arrival_guide.dart';
import 'package:frontend/features/mapas/domain/campus_geo_reference.dart';
import 'package:frontend/features/mapas/domain/campus_layers.dart';
import 'package:frontend/features/mapas/infrastructure/storage/glb_node_names.dart';

void main() {
  const bounds = NodeBounds(minX: 0, maxX: 10, minZ: 0, maxZ: 20);

  group('NodeBounds.distanceTo', () {
    test('dentro de la caja la distancia es 0', () {
      expect(bounds.distanceTo(const ModelPoint(5, 10)), 0);
    });

    test('al costado se mide hasta el borde, no hasta el centro', () {
      expect(bounds.distanceTo(const ModelPoint(25, 10)), 15);
    });

    test('en diagonal se mide hasta la esquina', () {
      expect(bounds.distanceTo(const ModelPoint(13, 24)), 5);
    });
  });

  group('ArrivalGuide.phaseFor', () {
    const guide = ArrivalGuide();

    test('lejos, cerca y llegada segun los umbrales', () {
      expect(guide.phaseFor(200), ArrivalPhase.far);
      expect(guide.phaseFor(60.1), ArrivalPhase.far);
      expect(guide.phaseFor(60), ArrivalPhase.near);
      expect(guide.phaseFor(15.1), ArrivalPhase.near);
      expect(guide.phaseFor(15), ArrivalPhase.arrived);
      expect(guide.phaseFor(0), ArrivalPhase.arrived);
    });
  });

  test('Destination.label deja un nombre legible', () {
    const b = NodeBounds(minX: 0, maxX: 1, minZ: 0, maxZ: 1);
    expect(const Destination(node: 'Bloque_A1', category: 'salones', bounds: b).label,
        'Bloque A1');
    expect(
        const Destination(
                node: 'Cancha_Futbol_6126m2', category: 'canchas', bounds: b)
            .label,
        'Cancha Futbol');
  });

  test('CampusLayers expone categorias y nodos con capa', () {
    final layers = CampusLayers({
      'cafeteria': {'Cafeteria'},
      'canchas': {'Cancha_A', 'Cancha_B'},
    });
    expect(layers.categories, {'cafeteria', 'canchas'});
    expect(layers.nodesOf('canchas'), unorderedEquals(['Cancha_A', 'Cancha_B']));
    expect(layers.nodesOf('banos'), isEmpty);
  });

  test('GlbNodeBounds aplica la traslacion del nodo a la caja de su malla', () async {
    final json = utf8.encode(jsonEncode({
      'nodes': [
        {'name': 'Edificio', 'mesh': 0, 'translation': [100, 0, -50]},
        {'name': 'SinMalla'},
      ],
      'meshes': [
        {'primitives': [{'attributes': {'POSITION': 0}}]},
      ],
      'accessors': [
        {'min': [-5, 0, -10], 'max': [5, 3, 10]},
      ],
    }));
    final padded = Uint8List.fromList(
        [...json, ...List.filled((4 - json.length % 4) % 4, 0x20)]);
    final header = ByteData(20)
      ..setUint32(0, 0x46546C67, Endian.little)
      ..setUint32(4, 2, Endian.little)
      ..setUint32(8, 20 + padded.length, Endian.little)
      ..setUint32(12, padded.length, Endian.little)
      ..setUint32(16, 0x4E4F534A, Endian.little);
    final dir = await Directory.systemTemp.createTemp('glb_bounds');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/m.glb')
      ..writeAsBytesSync([...header.buffer.asUint8List(), ...padded]);

    final result = await GlbNodeBounds.read(file.path);

    expect(result.keys, ['Edificio']);
    expect(result['Edificio']!.minX, 95);
    expect(result['Edificio']!.maxX, 105);
    expect(result['Edificio']!.minZ, -60);
    expect(result['Edificio']!.maxZ, -40);
  });
}
