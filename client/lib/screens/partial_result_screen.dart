import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/guest_challenge_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

/// MENTAL_FLUXO_GUEST_3_QUESTOES_DIAGNOSTICO_TECNICO_V1.md §3.4 — tela
/// mostrada logo após a 3ª questão do fluxo guest. Acertos + XP
/// provisório (nunca persistido, só somado localmente das 3 respostas já
/// guardadas por GuestChallengeService) e CTA pro cadastro/login — sem
/// ranking, igual ao doc original pede (seção 3.2 do documento base).
class PartialResultScreen extends StatefulWidget {
  const PartialResultScreen({super.key});

  @override
  State<PartialResultScreen> createState() => _PartialResultScreenState();
}

class _PartialResultScreenState extends State<PartialResultScreen> {
  int _correct = 0;
  int _total = 0;
  int _xpTotal = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    final answers = await GuestChallengeService.getAnswers();
    if (!mounted) return;
    setState(() {
      _total = answers.length;
      _correct = answers.where((a) => a.isCorrect).length;
      _xpTotal = answers.fold(0, (sum, a) => sum + a.xpPreview);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 56),
                    const SizedBox(height: 16),
                    Text(l10n.partialResultTitle, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text(
                      l10n.partialResultScore(_correct, _total),
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.bg2,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            l10n.partialResultXpProvisional(_xpTotal),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.gold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.partialResultXpNote,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.partialResultRankingNote,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      child: Text(l10n.partialResultCta),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.partialResultExplanation,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
