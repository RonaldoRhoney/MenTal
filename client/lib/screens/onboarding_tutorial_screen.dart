import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// "Como usar o MENTAL" — 6 telas diretas (29/08/2026, pedido de
/// Rhoney: "muito bem explicada e direta"). Aparece uma vez, logo após
/// o splash, antes do login (main.dart) — e fica disponível de novo em
/// Ajuste, pra quem quiser rever. `onDone` é chamado tanto ao concluir
/// quanto ao pular; quem chama decide se marca como "já visto" (main.dart
/// marca, settings_screen.dart não precisa — reabrir não deve mexer na
/// flag de primeira vez).
class OnboardingTutorialScreen extends StatefulWidget {
  const OnboardingTutorialScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingTutorialScreen> createState() => _OnboardingTutorialScreenState();
}

class _OnboardingTutorialScreenState extends State<OnboardingTutorialScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pageCount = 6;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _pageCount - 1) {
      widget.onDone();
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = [
      (Icons.auto_awesome_rounded, l10n.tutorialPage1Title, l10n.tutorialPage1Body),
      (Icons.public_rounded, l10n.tutorialPage2Title, l10n.tutorialPage2Body),
      (Icons.bolt_rounded, l10n.tutorialPage3Title, l10n.tutorialPage3Body),
      (Icons.local_fire_department_rounded, l10n.tutorialPage4Title, l10n.tutorialPage4Body),
      (Icons.emoji_events_rounded, l10n.tutorialPage5Title, l10n.tutorialPage5Body),
      (Icons.tune_rounded, l10n.tutorialPage6Title, l10n.tutorialPage6Body),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: TextButton(
                  onPressed: widget.onDone,
                  child: Text(l10n.tutorialSkipButton),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  for (final (icon, title, body) in pages) _TutorialPage(icon: icon, title: title, body: body),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pageCount; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _page ? AppColors.gold : AppColors.muted.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: FilledButton(
                onPressed: _next,
                child: Text(_page == _pageCount - 1 ? l10n.tutorialStartButton : l10n.tutorialNextButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialPage extends StatelessWidget {
  const _TutorialPage({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.14),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: AppColors.gold, size: 44),
          ),
          const SizedBox(height: 32),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
