import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/guest_api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/guest_challenge_service.dart';
import '../theme/app_theme.dart';
import 'partial_result_screen.dart';

/// MENTAL_FLUXO_GUEST_3_QUESTOES_DIAGNOSTICO_TECNICO_V1.md §3.4 — versão
/// deliberadamente simples de challenge_screen.dart: só múltipla escolha,
/// sem dicas, sem timer, sem Constelação de Palavras — o objetivo é dar
/// uma amostra rápida e honesta do jogo, não replicar toda a riqueza da
/// experiência autenticada. 3 questões no máximo
/// (GuestChallengeService.maxQuestions), depois segue pra
/// PartialResultScreen.
class GuestChallengeScreen extends StatefulWidget {
  const GuestChallengeScreen({super.key, required this.baseUrl, required this.territoryId});

  final String baseUrl;
  final String territoryId;

  @override
  State<GuestChallengeScreen> createState() => _GuestChallengeScreenState();
}

class _GuestChallengeScreenState extends State<GuestChallengeScreen> {
  late final GuestApiClient _guestClient = GuestApiClient(baseUrl: widget.baseUrl);

  Map<String, dynamic>? _challenge;
  String? _error;
  String? _selectedOption;
  Map<String, dynamic>? _result;
  int _answeredCount = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadNext();
  }

  Future<void> _loadNext() async {
    setState(() {
      _error = null;
      _challenge = null;
      _selectedOption = null;
      _result = null;
    });
    try {
      final challenge = await _guestClient.nextChallenge(widget.territoryId);
      if (mounted) setState(() => _challenge = challenge);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _submit() async {
    final challenge = _challenge;
    final selected = _selectedOption;
    if (challenge == null || selected == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      final result = await _guestClient.submitAnswer(
        challenge['challenge_id'] as String,
        selected,
        serveToken: challenge['serve_token'] as String,
      );
      await GuestChallengeService.addAnswer(GuestAnswer(
        challengeId: challenge['challenge_id'] as String,
        submittedAnswer: selected,
        isCorrect: result['is_correct'] as bool,
        xpPreview: result['xp_preview'] as int,
        completionToken: result['completion_token'] as String,
      ));
      if (!mounted) return;
      setState(() {
        _result = result;
        _answeredCount += 1;
        _submitting = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _submitting = false;
        });
      }
    }
  }

  void _next() {
    if (_answeredCount >= GuestChallengeService.maxQuestions) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PartialResultScreen()),
      );
      return;
    }
    _loadNext();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.guestQuestionCounter(_answeredCount + 1, GuestChallengeService.maxQuestions)),
      ),
      body: SafeArea(child: _buildBody(context, l10n)),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadNext, child: Text(l10n.tryAgainButton)),
            ],
          ),
        ),
      );
    }
    final challenge = _challenge;
    if (challenge == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final options = (challenge['options'] as List?)?.cast<String>() ?? const <String>[];
    final result = _result;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(challenge['prompt'] as String, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          for (final option in options) ...[
            _OptionTile(
              label: option,
              selected: _selectedOption == option,
              correct: result == null ? null : option == result['correct_answer'],
              wasSelectedWrong: result != null && _selectedOption == option && result['is_correct'] != true,
              onTap: result == null ? () => setState(() => _selectedOption = option) : null,
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          if (result == null)
            FilledButton(
              onPressed: (_selectedOption == null || _submitting) ? null : _submit,
              child: _submitting
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.guestAnswerSubmit),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (result['is_correct'] as bool) ? AppColors.success.withValues(alpha: 0.12) : AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (result['is_correct'] as bool) ? l10n.guestCorrectFeedback : l10n.guestIncorrectFeedback,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (result['is_correct'] != true) ...[
                    const SizedBox(height: 4),
                    Text(l10n.guestCorrectAnswerLabel(result['correct_answer'] as String)),
                  ],
                  if ((result['explanation'] as String?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(result['explanation'] as String, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _next, child: Text(l10n.guestAnswerContinue)),
          ],
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.correct,
    required this.wasSelectedWrong,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool? correct;
  final bool wasSelectedWrong;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.muted.withValues(alpha: 0.3);
    Color? fillColor;
    if (correct == true) {
      borderColor = AppColors.success;
      fillColor = AppColors.success.withValues(alpha: 0.12);
    } else if (wasSelectedWrong) {
      borderColor = AppColors.error;
      fillColor = AppColors.error.withValues(alpha: 0.12);
    } else if (selected) {
      borderColor = AppColors.gold;
      fillColor = AppColors.gold.withValues(alpha: 0.12);
    }
    return Material(
      color: fillColor ?? AppColors.bg2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ),
    );
  }
}
