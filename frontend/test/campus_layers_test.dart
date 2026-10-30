import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/mapas/domain/campus_layers.dart';
import 'package:frontend/features/mapas/infrastructure/api/campus_layers_repository.dart';
import 'package:frontend/features/mapas/infrastructure/storage/glb_node_names.dart';

void main() {
  final layers = CampusLayers({
    'cafeteria': {'Cafeteria', 'Esquina_del_Pandebono'},
    'canchas': {'Cancha_Futbol_6126m2'},
    'estacionamientos': {'Parqueadero_A1'},
  });
  const nodes = [
    'Plano_Referencia',
    'Terreno',
    'Cafeteria',
    'Cancha_Futbol_6126m2',
    'Det_Futbol_lineas',
    'Parqueadero_A1',
    'Etq_Cafetería',
    'Etq_Cancha de Fútbol',
    'Etq_Entrada',
  ];

  group('CampusLayers.hiddenNodes', () {
    test('sin filtro muestra todo salvo el plano de referencia', () {
      expect(layers.hiddenNodes(nodes, {}), {'Plano_Referencia'});
    });

    test('con categoria oculta las demas y deja la base visible', () {
      final hidden = layers.hiddenNodes(nodes, {'cafeteria'});
      expect(hidden, {
        'Plano_Referencia',
        'Cancha_Futbol_6126m2',
        'Det_Futbol_lineas',
        'Parqueadero_A1',
        'Etq_Cancha de Fútbol',
        'Etq_Entrada',
      });
      expect(hidden, isNot(contains('Terreno')));
    });

    test('con varias categorias oculta solo las no seleccionadas', () {
      final hidden = layers.hiddenNodes(nodes, {'cafeteria', 'canchas'});
      expect(hidden, {'Plano_Referencia', 'Parqueadero_A1', 'Etq_Entrada'});
    });

    test('con filtro, edificios sin categoria se ocultan y la base queda', () {
      final hidden = layers.hiddenNodes(
        const ['Terreno', 'Via_Interna', 'Anden_Entrada', 'Carreteable',
          'Talleres', 'Edif_Ingenieria_1', 'UTB_Ventanas', 'Cafeteria'],
        {'cafeteria'},
      );
      expect(hidden, {
        'Plano_Referencia',
        'Talleres',
        'Edif_Ingenieria_1',
        'UTB_Ventanas',
      });
    });

    test('detalles Det_* y etiquetas siguen a su categoria', () {
      expect(layers.categoryOf('Det_Basket_piso'), 'canchas');
      expect(layers.categoryOf('Etq_Cafetería'), 'cafeteria');
      expect(layers.categoryOf('Etq_Bloque A3'), 'salones');
      expect(layers.categoryOf('Etq_Entrada'), isNull);
    });

    test('hasLayer distingue categorias sin nodos', () {
      expect(layers.hasLayer('cafeteria'), isTrue);
      expect(layers.hasLayer('banos'), isFalse);
    });
  });

  test('sanitizeNodeName replica el saneado de three.js', () {
    expect(CampusLayers.sanitizeNodeName('Etq_Bloque A5'), 'Etq_Bloque_A5');
    expect(CampusLayers.sanitizeNodeName('Etq_Edif. Ingeniería'),
        'Etq_Edif_Ingeniería');
  });

  test('CampusLayersRepository.parse agrupa filas por categoria', () {
    final parsed = CampusLayersRepository.parse(jsonEncode([
      {'categoria': 'canchas', 'nodo': 'Cancha_A'},
      {'categoria': 'canchas', 'nodo': 'Cancha_B'},
    ]));
    expect(parsed.categoryOf('Cancha_B'), 'canchas');
  });

  test('GlbNodeNames lee los nombres del bloque JSON', () async {
    final json = utf8.encode(jsonEncode({
      'nodes': [
        {'name': 'Terreno'},
        {'name': 'Etq_Bloque A1'},
        {'mesh': 0},
      ],
    }));
    final padded = Uint8List.fromList([...json, ...List.filled((4 - json.length % 4) % 4, 0x20)]);
    final header = ByteData(20)
      ..setUint32(0, 0x46546C67, Endian.little)
      ..setUint32(4, 2, Endian.little)
      ..setUint32(8, 20 + padded.length, Endian.little)
      ..setUint32(12, padded.length, Endian.little)
      ..setUint32(16, 0x4E4F534A, Endian.little);
    final dir = await Directory.systemTemp.createTemp('glb_test');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/m.glb')
      ..writeAsBytesSync([...header.buffer.asUint8List(), ...padded]);

    expect(await GlbNodeNames.read(file.path), ['Terreno', 'Etq_Bloque A1']);
  });
}
