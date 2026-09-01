// lib/shared/locale/locale_cubit.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/storage/local_storage.dart';

class LocaleCubit extends Cubit<Locale> {
  static const _localeKey = 'app_locale';
  static const supportedLocales = [Locale('es'), Locale('en')];

  final LocalStorage _localStorage;

  LocaleCubit(this._localStorage) : super(_initialLocale(_localStorage));

  static Locale _initialLocale(LocalStorage storage) {
    final saved = storage.getString(_localeKey);
    final match = supportedLocales.where((l) => l.languageCode == saved);
    return match.isNotEmpty ? match.first : const Locale('es');
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) return;
    await _localStorage.setString(_localeKey, locale.languageCode);
    emit(locale);
  }

  Future<void> toggle() {
    final next = state.languageCode == 'es' ? const Locale('en') : const Locale('es');
    return setLocale(next);
  }
}
