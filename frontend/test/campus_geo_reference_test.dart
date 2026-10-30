import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/mapas/domain/campus_geo_reference.dart';

void main() {
  const geo = CampusGeoReference.utbTernera;

  test('el centro del campus cae en el centro del terreno del modelo', () {
    final p = geo.toModel(10.369413, -75.465826);
    expect(p.x, closeTo(138.6, 10));
    expect(p.z, closeTo(-154.7, 10));
    expect(geo.isInside(p), isTrue);
  });

  test('las esquinas del terreno quedan dentro con el margen', () {
    for (final corner in const [
      (10.369336, -75.463669),
      (10.367278, -75.465927),
      (10.369491, -75.467984),
      (10.371549, -75.465725),
    ]) {
      expect(geo.isInside(geo.toModel(corner.$1, corner.$2)), isTrue);
    }
  });

  test('una posicion lejana (centro de Cartagena) queda fuera', () {
    expect(geo.isInside(geo.toModel(10.4236, -75.5486)), isFalse);
  });

  test('a mas de 30 m del terreno queda fuera; con margen mayor, dentro', () {
    const p = ModelPoint(150, 4.4 + 50);
    expect(geo.isInside(p), isFalse);
    expect(geo.isInside(p, marginMeters: 60), isTrue);
  });
}
