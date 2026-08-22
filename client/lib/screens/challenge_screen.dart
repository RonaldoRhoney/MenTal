import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/feedback_service.dart';
import '../theme/app_theme.dart';
import '../visual_options.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/pulse_in.dart';

/// Ciclo completo de um desafio: busca → responde → resultado → próximo.
/// Uma ação primária por vez (Clareza Imediata, PRODUCT_PRINCIPLES.md §1):
/// enquanto o desafio está aberto, o CTA é "Confirmar resposta"; depois de
/// respondido, vira "Próximo desafio". Dica é sempre secundária/opcional.
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({
    super.key,
    required this.client,
    required this.territoryId,
    required this.territoryLabel,
  });

  final ApiClient client;
  final String territoryId;
  final String territoryLabel;

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  static const _uuid = Uuid();

  bool _loading = true;
  String? _error;
  String? _errorCode;
  Map<String, dynamic>? _challenge;
  String? _attemptId;
  String? _selectedOption;
  List<String> _hintsShown = [];
  bool _hintsExhausted = false;
  Map<String, dynamic>? _result;

  // MICROINTERACTIONS.md §3 — celebração forte (território/badge/level
  // up) usa confete + fogos + balões (pedido explícito: algo que remeta a
  // comemoração de verdade, não só confete); sons e o pulso sutil/
  // moderado não precisam de controller próprio.
  late final CelebrationController _celebration;

  @override
  void initState() {
    super.initState();
    _celebration = CelebrationController();
    _loadNextChallenge();
  }

  @override
  void dispose() {
    _celebration.dispose();
    super.dispose();
  }

  /// Decide som + celebração visual a partir dos sinais que o backend
  /// calculou (única autoridade sobre "isso é um evento raro" — client
  /// nunca deriva isso sozinho). Calibração por evento,
  /// MICROINTERACTIONS.md §3: forte (level up/conquista/badge) > moderado
  /// (streak) > sutil (acerto).
  void _triggerFeedback(Map<String, dynamic> result) {
    final isCorrect = result['is_correct'] as bool;
    final levelUp = result['level_up'] as bool? ?? false;
    final territoryJustConquered = result['territory_just_conquered'] as bool? ?? false;
    final worldJustCompleted = result['world_just_completed'] as bool? ?? false;
    final newlyAwardedBadges = (result['newly_awarded_badges'] as List?) ?? const [];
    final streakJustExtended = result['streak_just_extended'] as bool? ?? false;

    final isStrongEvent = levelUp || territoryJustConquered || worldJustCompleted || newlyAwardedBadges.isNotEmpty;

    if (isStrongEvent) {
      FeedbackService.instance.play(FeedbackSound.celebration);
      if (!MediaQuery.of(context).disableAnimations) {
        _celebration.celebrate();
      }
    } else if (streakJustExtended) {
      FeedbackService.instance.play(FeedbackSound.streak);
    } else if (isCorrect) {
      FeedbackService.instance.play(FeedbackSound.correct);
    } else {
      FeedbackService.instance.play(FeedbackSound.incorrect);
    }
  }

  Future<void> _loadNextChallenge() async {
    setState(() {
      _loading = true;
      _error = null;
      _errorCode = null;
      _challenge = null;
      _result = null;
      _selectedOption = null;
      _hintsShown = [];
      _hintsExhausted = false;
      _attemptId = _uuid.v4();
    });
    try {
      final challenge = await widget.client.nextChallenge(widget.territoryId);
      if (mounted) setState(() => _challenge = challenge);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorCode = e.code;
          if (e.code == 'DAILY_LIMIT_REACHED') {
            // Tom celebratório, não de bloqueio — MONETIZATION_UPDATE_FREE_LAUNCH.md
            // §3, coerente com o Princípio de Não-Humilhação (PRODUCT_PRINCIPLES.md).
            _error = AppLocalizations.of(context)!.dailyLimitReachedMessage;
          } else if (e.code == 'TERRITORY_LOCKED') {
            _error = AppLocalizations.of(context)!.territoryLockedMessage;
          } else {
            _error = e.message;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestHint() async {
    final challenge = _challenge;
    final attemptId = _attemptId;
    if (challenge == null || attemptId == null) return;
    try {
      final hint = await widget.client.requestHint(challenge['challenge_id'], attemptId);
      setState(() => _hintsShown = [..._hintsShown, hint['content'] as String]);
    } on ApiException catch (e) {
      // NO_MORE_HINTS não é um erro que trava a tela — o jogador só não
      // tem mais dica pra pedir nesse desafio. Achado testando no
      // celular real: sem esse tratamento, o botão "Pedir uma dica"
      // ficava clicável sem nenhum feedback visual do que aconteceu.
      if (e.code == 'NO_MORE_HINTS') {
        setState(() => _hintsExhausted = true);
      } else {
        setState(() => _error = e.message);
      }
    }
  }

  Future<void> _submitAnswer() async {
    final challenge = _challenge;
    final attemptId = _attemptId;
    final answer = _selectedOption;
    if (challenge == null || attemptId == null || answer == null) return;

    setState(() => _loading = true);
    try {
      final result = await widget.client.submitAnswer(challenge['challenge_id'], attemptId, answer);
      if (mounted) {
        setState(() => _result = result);
        _triggerFeedback(result);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.territoryLabel)),
      body: SafeArea(
        child: CelebrationOverlay(
          controller: _celebration,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      // Feedback explícito durante possível cold start do backend
      // (ARCHITECTURE.md §3) — nunca tela em branco.
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.preparingChallenge),
          ],
        ),
      );
    }

    if (_error != null && _challenge == null) {
      // DAILY_LIMIT_REACHED e TERRITORY_LOCKED não são erros transitórios
      // — reenviar a mesma requisição nunca vai funcionar (limite só
      // libera no dia seguinte, ou é fora do escopo deste slice destravar
      // via assinatura). "Tentar de novo" nesses casos é uma promessa
      // falsa; achado testando no celular real. Só oferece retry de
      // verdade para erros que podem mesmo ter sido transitórios (rede,
      // backend acordando de cold start).
      final isPermanentForToday = _errorCode == 'DAILY_LIMIT_REACHED' || _errorCode == 'TERRITORY_LOCKED';
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              // Erro/limite em terracota suave, nunca vermelho vivo —
              // DESIGN_SYSTEM.md §1/§4, coerente com não-humilhação.
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            if (isPermanentForToday)
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.backToHomeButton),
              )
            else
              FilledButton(onPressed: _loadNextChallenge, child: Text(l10n.tryAgainButton)),
          ],
        ),
      );
    }

    final result = _result;
    if (result != null) {
      return _buildResult(result);
    }

    return _buildChallenge();
  }

  Widget _buildChallenge() {
    final l10n = AppLocalizations.of(context)!;
    final challenge = _challenge!;
    final options = (challenge['options'] as List?)?.cast<String>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Expanded + SingleChildScrollView (em vez de Column solta com
        // Spacer): os parágrafos-base do território "textos" (V2 item 3)
        // são bem mais longos que um enunciado de charada/pergunta direta
        // e estouravam a tela em telas menores — achado antes de gerar o
        // conteúdo, corrigido aqui para qualquer território, não só esse.
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(challenge['prompt'] as String, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                if (widget.territoryId == 'visual' && options != null)
                  _buildVisualOptions(options)
                else if (options != null)
                  RadioGroup<String>(
                    groupValue: _selectedOption,
                    onChanged: (value) => setState(() => _selectedOption = value),
                    child: Column(
                      children: options
                          .map((option) => RadioListTile<String>(title: Text(option), value: option))
                          .toList(),
                    ),
                  )
                else
                  TextField(
                    decoration: InputDecoration(labelText: l10n.yourAnswerLabel),
                    // Bug achado testando no celular real: sem setState aqui, o
                    // botão "Confirmar resposta" (que depende de
                    // _selectedOption != null) não reavaliava ao digitar — só
                    // reabilitava quando algum outro evento forçava rebuild.
                    onChanged: (value) => setState(() => _selectedOption = value.trim().isEmpty ? null : value),
                  ),
                const SizedBox(height: 16),
                ..._hintsShown.map(
                  (hint) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      l10n.hintPrefix(hint),
                      style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.muted),
                    ),
                  ),
                ),
                if (_hintsExhausted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      l10n.noMoreHintsMessage,
                      style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.muted),
                    ),
                  )
                else
                  TextButton(onPressed: _requestHint, child: Text(l10n.requestHintButton)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _selectedOption == null ? null : _submitAnswer,
          child: Text(l10n.confirmAnswerButton),
        ),
      ],
    );
  }

  /// Território "visual" (V2 item 4): opções são ícones vetoriais, não
  /// texto — grade de tiles selecionáveis em vez de RadioListTile. Sem
  /// imagem real (decisão Free-First registrada em backend/app/seed.py e
  /// client/lib/visual_options.dart): custo zero com certeza absoluta.
  Widget _buildVisualOptions(List<String> options) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: options.map((option) {
        final spec = parseVisualOption(option);
        final selected = _selectedOption == option;
        return Semantics(
          label: spec?.description ?? option,
          selected: selected,
          button: true,
          child: GestureDetector(
            onTap: () => setState(() => _selectedOption = option),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.gold : AppColors.muted,
                  width: selected ? 3 : 1,
                ),
              ),
              child: Icon(
                spec?.icon ?? Icons.help_outline,
                color: spec?.color ?? AppColors.muted,
                size: 48,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Achado testando no celular real: a tela de resultado exibia o id
  /// bruto da opção visual (ex.: "square_filled_gold_3") em vez de uma
  /// descrição legível — vaza detalhe interno e quebra a Clareza Imediata
  /// (DESIGN_SYSTEM.md §1) para o território "visual" (V2 item 4).
  String _displayAnswer(String rawAnswer) {
    if (widget.territoryId != 'visual') return rawAnswer;
    return parseVisualOption(rawAnswer)?.description ?? rawAnswer;
  }

  Widget _buildResult(Map<String, dynamic> result) {
    final l10n = AppLocalizations.of(context)!;
    final isCorrect = result['is_correct'] as bool;
    final levelUp = result['level_up'] as bool? ?? false;
    final newLevel = result['new_level'] as int?;
    final territoryJustConquered = result['territory_just_conquered'] as bool? ?? false;
    final worldJustCompleted = result['world_just_completed'] as bool? ?? false;
    final completedWorldName = result['completed_world_name'] as String?;
    final newlyAwardedBadges = ((result['newly_awarded_badges'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    final streakJustExtended = result['streak_just_extended'] as bool? ?? false;
    final currentStreak = (result['streak'] as Map<String, dynamic>)['current_streak'] as int;

    final feedbackText = Text(
      isCorrect ? l10n.correctAnswerFeedback : l10n.incorrectAnswerFeedback,
      // Celebração em teal (acerto) vs. terracota suave (erro, nunca
      // vermelho vivo) — DESIGN_SYSTEM.md §4.
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: isCorrect ? AppColors.success : AppColors.error,
          ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pulso sutil só no acerto (MICROINTERACTIONS.md §3, "Erro:
                // nenhuma celebração" — texto de erro fica estático).
                isCorrect ? PulseIn(child: feedbackText) : feedbackText,
                const SizedBox(height: 8),
                Text(l10n.correctAnswerLabel(_displayAnswer(result['correct_answer'] as String))),
                const SizedBox(height: 12),
                Text(result['explanation'] as String),
                const SizedBox(height: 12),
                Text(
                  l10n.xpEarnedLabel(
                    result['xp_awarded'] as int,
                    result['xp_base'] as int,
                    result['hints_used'] as int,
                  ),
                  style: AppTheme.technicalStyle(color: AppColors.gold, fontSize: 14),
                ),
                // Sinais de evento raro calculados pelo backend (nunca
                // derivados aqui) — texto sempre presente, nunca só
                // som/animação (acessibilidade, AUDIO_FEEDBACK.md §4).
                if (streakJustExtended) ...[
                  const SizedBox(height: 16),
                  PulseIn(
                    intensity: 0.3,
                    child: Text(
                      l10n.streakExtendedCelebrationMessage(currentStreak),
                      style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                if (levelUp && newLevel != null) ...[
                  const SizedBox(height: 16),
                  PulseIn(
                    intensity: 0.3,
                    child: Text(
                      l10n.levelUpMessage(newLevel),
                      style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                if (territoryJustConquered) ...[
                  const SizedBox(height: 16),
                  PulseIn(
                    intensity: 0.3,
                    child: Text(
                      l10n.territoryConqueredCelebrationMessage,
                      style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                if (worldJustCompleted && completedWorldName != null) ...[
                  const SizedBox(height: 16),
                  PulseIn(
                    intensity: 0.3,
                    child: Text(
                      l10n.worldCompletedCelebrationMessage(completedWorldName),
                      style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                for (final badge in newlyAwardedBadges) ...[
                  const SizedBox(height: 16),
                  PulseIn(
                    intensity: 0.3,
                    child: Text(
                      l10n.badgeUnlockedCelebrationMessage(badge['name'] as String),
                      style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _loadNextChallenge, child: Text(l10n.nextChallengeButton)),
      ],
    );
  }
}
