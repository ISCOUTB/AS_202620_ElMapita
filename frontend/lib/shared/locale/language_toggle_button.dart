// lib/shared/locale/language_toggle_button.dart
//
// Boton ES/EN de la barra superior. Usa el LocaleCubit, que guarda el idioma.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'locale_cubit.dart';

class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleCubit>().state;
    return IconButton(
      tooltip: AppLocalizations.of(context)!.languageToggleTooltip,
      onPressed: () => context.read<LocaleCubit>().toggle(),
      icon: Text(
        locale.languageCode.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.onPrimary,
        ),
      ),
    );
  }
}
