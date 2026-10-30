// lib/features/mapas/infrastructure/storage/glb_node_names.dart
//
// Lee el bloque JSON de un .glb sin cargar el archivo completo (el binario del
// modelo pesa varios MB) y extrae de el los nombres y las cajas de los nodos.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../../domain/arrival_guide.dart';

class GlbJson {
  static const int _glbMagic = 0x46546C67; // 'glTF'
  static const int _jsonChunk = 0x4E4F534A; // 'JSON'

  static Future<Map<String, dynamic>> read(String filePath) async {
    final file = await File(filePath).open();
    try {
      final head = await file.read(20);
      if (head.length < 20) throw const FormatException('GLB incompleto');
      final data = ByteData.sublistView(head);
      if (data.getUint32(0, Endian.little) != _glbMagic ||
          data.getUint32(16, Endian.little) != _jsonChunk) {
        throw const FormatException('No es un .glb valido');
      }
      final jsonBytes = await file.read(data.getUint32(12, Endian.little));
      return jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;
    } finally {
      await file.close();
    }
  }
}

class GlbNodeNames {
  static Future<List<String>> read(String filePath) async {
    final json = await GlbJson.read(filePath);
    return [
      for (final node in (json['nodes'] as List? ?? const []))
        if ((node as Map)['name'] is String) node['name'] as String,
    ];
  }
}

/// Caja sobre el plano del terreno (ejes X y Z de glTF) de cada nodo con malla.
/// Supone nodos planos (sin jerarquia), como los exporta `utb_campus.glb`.
class GlbNodeBounds {
  static Future<Map<String, NodeBounds>> read(String filePath) async {
    final json = await GlbJson.read(filePath);
    final accessors = json['accessors'] as List? ?? const [];
    final meshes = json['meshes'] as List? ?? const [];
    final result = <String, NodeBounds>{};
    for (final node in (json['nodes'] as List? ?? const [])) {
      final map = node as Map;
      final name = map['name'];
      final meshIndex = map['mesh'];
      if (name is! String || meshIndex is! int) continue;
      final primitives = (meshes[meshIndex] as Map)['primitives'] as List;
      final position = ((primitives.first as Map)['attributes'] as Map)['POSITION'];
      final accessor = accessors[position as int] as Map;
      final matrix = _matrixOf(map);
      var minX = double.infinity, maxX = -double.infinity;
      var minZ = double.infinity, maxZ = -double.infinity;
      final lo = _doubles(accessor['min']), hi = _doubles(accessor['max']);
      for (var i = 0; i < 8; i++) {
        final corner = [
          i & 1 == 0 ? lo[0] : hi[0],
          i & 2 == 0 ? lo[1] : hi[1],
          i & 4 == 0 ? lo[2] : hi[2],
        ];
        final x = _transform(matrix, corner, 0);
        final z = _transform(matrix, corner, 2);
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (z < minZ) minZ = z;
        if (z > maxZ) maxZ = z;
      }
      result[name] = NodeBounds(minX: minX, maxX: maxX, minZ: minZ, maxZ: maxZ);
    }
    return result;
  }

  static List<double> _doubles(Object? value) =>
      [for (final v in value as List) (v as num).toDouble()];

  static double _transform(List<double> m, List<double> p, int row) =>
      p[0] * m[row] + p[1] * m[4 + row] + p[2] * m[8 + row] + m[12 + row];

  /// Matriz 4x4 en orden de columnas, desde `matrix` o desde TRS.
  static List<double> _matrixOf(Map node) {
    if (node['matrix'] != null) return _doubles(node['matrix']);
    final t = node['translation'] != null ? _doubles(node['translation']) : [0.0, 0.0, 0.0];
    final q = node['rotation'] != null ? _doubles(node['rotation']) : [0.0, 0.0, 0.0, 1.0];
    final s = node['scale'] != null ? _doubles(node['scale']) : [1.0, 1.0, 1.0];
    final x = q[0], y = q[1], z = q[2], w = q[3];
    return [
      (1 - 2 * (y * y + z * z)) * s[0], 2 * (x * y + z * w) * s[0], 2 * (x * z - y * w) * s[0], 0,
      2 * (x * y - z * w) * s[1], (1 - 2 * (x * x + z * z)) * s[1], 2 * (y * z + x * w) * s[1], 0,
      2 * (x * z + y * w) * s[2], 2 * (y * z - x * w) * s[2], (1 - 2 * (x * x + y * y)) * s[2], 0,
      t[0], t[1], t[2], 1,
    ];
  }
}
