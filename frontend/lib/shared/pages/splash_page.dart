// lib/shared/pages/splash_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/injector.dart';
import '../../core/storage/local_storage.dart';
import '../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const _acceptedNoticeKey = 'legal_notice_accepted';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final alreadyAccepted = getIt<LocalStorage>().getBool(_acceptedNoticeKey);
    if (alreadyAccepted) {
      context.go('/map');
      return;
    }

    final agreed = await _showNoticeDialog();
    if (agreed == true) {
      await getIt<LocalStorage>().setBool(_acceptedNoticeKey, true);
      if (!mounted) return;
      context.go('/map');
    }
  }

  Future<bool?> _showNoticeDialog() {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.noticeTitle),
          content: Text(l10n.noticeBody),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.noticeAccept),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logoutb.jpg',
              width: 220,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
