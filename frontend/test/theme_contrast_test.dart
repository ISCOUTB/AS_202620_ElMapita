import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/shared/theme/app_theme.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // Text pairs must reach WCAG AA (4.5:1) for normal text.
  Map<String, (Color, Color)> pairs(AppPalette p) => {
        'text/background': (p.text, p.background),
        'text/surface': (p.text, p.surface),
        'text/field': (p.text, p.field),
        'textSecondary/background': (p.textSecondary, p.background),
        'textSecondary/surface': (p.textSecondary, p.surface),
        'textSecondary/field': (p.textSecondary, p.field),
        'onAction/action': (p.onAction, p.action),
        'accent/background': (p.accent, p.background),
        'accent/surface': (p.accent, p.surface),
        'onHeader/headerStart': (p.onHeader, p.headerStart),
        'onHeader/headerEnd': (p.onHeader, p.headerEnd),
        'error/surface': (p.error, p.surface),
        'warning/surface': (p.warning, p.surface),
        'success/surface': (p.success, p.surface),
      };

  for (final entry in {
    'light': AppPalette.light,
    'dark': AppPalette.dark,
  }.entries) {
    for (final pair in pairs(entry.value).entries) {
      test('${entry.key} ${pair.key} meets AA', () {
        final (fg, bg) = pair.value;
        expect(_ratio(fg, bg), greaterThanOrEqualTo(4.5));
      });
    }
  }

  test('light palette uses the requested brand values', () {
    expect(AppPalette.light.background, const Color(0xFFEEF1FA));
    expect(AppPalette.light.surface, const Color(0xFFFFFFFF));
    expect(AppPalette.light.field, const Color(0xFFF1F3FA));
    expect(AppPalette.light.text, const Color(0xFF0B1024));
    expect(AppPalette.light.action, const Color(0xFF093AD8));
  });

  test('dark palette uses the requested brand values', () {
    expect(AppPalette.dark.background, const Color(0xFF000000));
    expect(AppPalette.dark.surface, const Color(0xFF1C1C1E));
    expect(AppPalette.dark.accent, const Color(0xFF4D8BFF));
    expect(AppPalette.dark.action, const Color(0xFF005BFF));
  });
}
