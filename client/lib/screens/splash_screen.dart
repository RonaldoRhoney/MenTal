import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// BRAND.md §3 — sequência obrigatória de splash:
/// 1) wordmark "MENTAL" sozinho (~1.2s)
/// 2) slogan aparece abaixo, mais discreto (~+1s)
/// 3) transição direta pro próximo destino — sem terceira tela.
///
/// Esta tela não decide login/Age Gate/Home: [onDone] é chamado ao fim
/// da sequência e quem chamou (main.dart) decide o destino real.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showSlogan = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showSlogan = true);
    });
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.loginTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            AnimatedOpacity(
              opacity: _showSlogan ? 1 : 0,
              duration: const Duration(milliseconds: 500),
              child: Text(
                l10n.loginSlogan,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
