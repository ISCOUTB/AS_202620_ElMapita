import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/campus/data/mock_places.dart';
import 'package:frontend/l10n/app_localizations_en.dart';
import 'package:frontend/l10n/app_localizations_es.dart';

void main() {
  Map<String, dynamic> arb(String lang) => jsonDecode(
        File('lib/l10n/app_$lang.arb').readAsStringSync(),
      ) as Map<String, dynamic>;

  test('el ARB en ingles tiene exactamente las claves del español', () {
    final es = arb('es').keys.where((k) => !k.startsWith('@')).toSet();
    final en = arb('en').keys.where((k) => !k.startsWith('@')).toSet();
    expect(en.difference(es), isEmpty, reason: 'sobran en EN');
    expect(es.difference(en), isEmpty, reason: 'faltan en EN');
  });

  test('los mensajes de la guia cambian con el idioma', () {
    final es = AppLocalizationsEs();
    final en = AppLocalizationsEn();
    expect(es.guideArrived('Cafeteria'), '¡Llegaste a Cafeteria!');
    expect(en.guideArrived('Cafeteria'), 'You have arrived at Cafeteria!');
    expect(es.guideNear('Auditorio', 42), 'Cerca de Auditorio · 42 m');
    expect(en.guideNear('Auditorio', 42), 'Near Auditorio · 42 m');
    expect(en.statusOutside, 'Position far from the area');
  });

  test('cada lugar de ejemplo tiene texto en ambos idiomas y distinto', () {
    for (final place in mockCampusPlaces) {
      expect(place.nameFor('es'), place.name);
      expect(place.nameFor('en'), place.nameEn);
      expect(place.nameEn, isNotEmpty);
      expect(place.locationEn, isNotEmpty);
    }
    final first = mockCampusPlaces.first;
    expect(first.nameFor('en'), isNot(first.nameFor('es')));
  });
}
