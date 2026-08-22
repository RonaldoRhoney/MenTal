import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/feedback_service.dart';
import '../theme/app_theme.dart';
import '../visual_options.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/pulse_in.dart';
import '../widgets/share_achievement_button.dart';

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
    this.relampago = false,
    this.battleId,
    this.prefetchedChallenge,
  });

  final ApiClient client;
  final String territoryId;
  final String territoryLabel;
  // V2 item 15 — Palavras Relâmpago (PALAVRAS_RELAMPAGO.md). Só tem
  // efeito real quando territoryId == 'palavras'; o backend também
  // ignora o modo pra qualquer outro território (defesa em profundidade,
  // nunca confia só no client pra isso).
  final bool relampago;
  // V2 item 14 — Batalha assíncrona (ASYNC_BATTLE.md). Quando não-nulo,
  // esta tela serve o desafio de UMA batalha específica (nunca "próximo
  // desafio" em sequência — é um evento único por lado). prefetchedChallenge
  // evita uma chamada de rede redundante pro desafiante, que já recebeu o
  // próprio desafio na resposta de POST /battles.
  final String? battleId;
  final Map<String, dynamic>? prefetchedChallenge;

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

  // V2 item 15 — Palavras Relâmpago. Contagem regressiva controlada
  // aqui (não no backend) — o backend só recebe o tempo de resposta em
  // milissegundos ao submeter, é a única autoridade sobre XP/bônus. O
  // client decide QUANDO estourou o tempo (pra dar feedback visual
  // imediato), mas quem CALCULA o bônus de velocidade é sempre o
  // backend, com o mesmo response_time_ms enviado aqui.
  Timer? _countdownTimer;
  int? _remainingMs;
  int? _timeLimitMs;
  DateTime? _challengeShownAt;
  bool _submitted = false;

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
    _countdownTimer?.cancel();
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
    final timedOut = result['timed_out'] as bool? ?? false;
    final levelUp = result['level_up'] as bool? ?? false;
    final territoryJustConquered = result['territory_just_conquered'] as bool? ?? false;
    final territoryDetentorGained = result['territory_detentor_gained'] as bool? ?? false;
    final worldJustCompleted = result['world_just_completed'] as bool? ?? false;
    final newlyAwardedBadges = (result['newly_awarded_badges'] as List?) ?? const [];
    final streakJustExtended = result['streak_just_extended'] as bool? ?? false;

    final isStrongEvent = levelUp || territoryJustConquered || territoryDetentorGained || worldJustCompleted || newlyAwardedBadges.isNotEmpty;

    if (isStrongEvent) {
      FeedbackService.instance.play(FeedbackSound.celebration);
      if (!MediaQuery.of(context).disableAnimations) {
        _celebration.celebrate();
      }
    } else if (streakJustExtended) {
      FeedbackService.instance.play(FeedbackSound.streak);
    } else if (isCorrect) {
      FeedbackService.instance.play(FeedbackSound.correct);
    } else if (timedOut) {
      // V2 item 15 — Princípio de Não-Humilhação (PALAVRAS_RELAMPAGO.md
      // §3): tempo esgotado não é "saber errado", nunca toca o som de
      // erro padrão.
    } else {
      FeedbackService.instance.play(FeedbackSound.incorrect);
    }
  }

  Future<void> _loadNextChallenge() async {
    _countdownTimer?.cancel();
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
      _remainingMs = null;
      _timeLimitMs = null;
      _challengeShownAt = null;
      _submitted = false;
    });
    try {
      final challenge = widget.battleId != null
          ? (widget.prefetchedChallenge ?? await widget.client.getMyBattleChallenge(widget.battleId!))
          : await widget.client.nextChallenge(
              widget.territoryId,
              mode: widget.relampago ? 'relampago' : 'normal',
            );
      if (mounted) {
        setState(() => _challenge = challenge);
        final timeLimitSeconds = challenge['time_limit_seconds'] as int?;
        if (timeLimitSeconds != null) _startCountdown(timeLimitSeconds);
      }
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

  void _startCountdown(int timeLimitSeconds) {
    _timeLimitMs = timeLimitSeconds * 1000;
    _remainingMs = _timeLimitMs;
    _challengeShownAt = DateTime.now();
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || _submitted) {
        timer.cancel();
        return;
      }
      final elapsed = DateTime.now().difference(_challengeShownAt!).inMilliseconds;
      final remaining = _timeLimitMs! - elapsed;
      if (remaining <= 0) {
        timer.cancel();
        setState(() => _remainingMs = 0);
        _submitTimedOut();
      } else {
        setState(() => _remainingMs = remaining);
      }
    });
  }

  /// V2 item 15 — no modo relâmpago, tocar numa opção já submete na
  /// hora (sem o passo separado de "Confirmar resposta" do formato
  /// digitado) — é uma reação rápida, não uma escolha deliberada.
  Future<void> _submitOption(String option) async {
    if (_submitted) return;
    final challenge = _challenge;
    final attemptId = _attemptId;
    if (challenge == null || attemptId == null) return;

    _countdownTimer?.cancel();
    final responseTimeMs = _challengeShownAt != null
        ? DateTime.now().difference(_challengeShownAt!).inMilliseconds
        : null;

    setState(() {
      _submitted = true;
      _selectedOption = option;
      _loading = true;
    });
    try {
      final result = await widget.client.submitAnswer(
        challenge['challenge_id'],
        attemptId,
        option,
        responseTimeMs: responseTimeMs,
      );
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

  Future<void> _submitTimedOut() async {
    if (_submitted) return;
    final challenge = _challenge;
    final attemptId = _attemptId;
    if (challenge == null || attemptId == null) return;

    setState(() {
      _submitted = true;
      _loading = true;
    });
    try {
      final result = await widget.client.submitAnswer(
        challenge['challenge_id'],
        attemptId,
        '',
        timedOut: true,
      );
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

    if (widget.relampago && options != null) {
      return _buildRelampagoChallenge(challenge, options);
    }

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

  /// V2 item 15 — Palavras Relâmpago (PALAVRAS_RELAMPAGO.md). Tocar numa
  /// opção submete na hora (_submitOption), sem passo de "Confirmar
  /// resposta" — é reação rápida, não escolha deliberada. Sem UI de
  /// dica (não faz sentido dentro de uma contagem regressiva curta).
  Widget _buildRelampagoChallenge(Map<String, dynamic> challenge, List<String> options) {
    final l10n = AppLocalizations.of(context)!;
    final timeLimitMs = _timeLimitMs ?? 1;
    final remainingMs = _remainingMs ?? timeLimitMs;
    final remainingSeconds = (remainingMs / 1000).ceil();
    final progress = (remainingMs / timeLimitMs).clamp(0.0, 1.0);
    // Verde/teal com tempo sobrando, terracota suave nos últimos 30% —
    // reforço visual da pressão sem soar de alarme (DESIGN_SYSTEM.md).
    final urgent = progress <= 0.3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.bg2,
                  color: urgent ? AppColors.error : AppColors.teal,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.relampagoSecondsRemainingLabel(remainingSeconds),
              style: AppTheme.technicalStyle(
                color: urgent ? AppColors.error : AppColors.teal,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(challenge['prompt'] as String, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                for (final option in options) ...[
                  OutlinedButton(
                    onPressed: _submitted ? null : () => _submitOption(option),
                    child: Text(option),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
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
    final timedOut = result['timed_out'] as bool? ?? false;
    final speedBonusXp = result['speed_bonus_xp'] as int? ?? 0;
    final levelUp = result['level_up'] as bool? ?? false;
    final newLevel = result['new_level'] as int?;
    final territoryJustConquered = result['territory_just_conquered'] as bool? ?? false;
    final territoryDetentorGained = result['territory_detentor_gained'] as bool? ?? false;
    final worldJustCompleted = result['world_just_completed'] as bool? ?? false;
    final completedWorldName = result['completed_world_name'] as String?;
    final worldCompletionBonusXp = result['world_completion_bonus_xp'] as int? ?? 0;
    final newlyAwardedBadges = ((result['newly_awarded_badges'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    final streakJustExtended = result['streak_just_extended'] as bool? ?? false;
    final currentStreak = (result['streak'] as Map<String, dynamic>)['current_streak'] as int;

    // V2 item 15 — tempo esgotado nunca mostra a copy padrão de erro
    // (Princípio de Não-Humilhação, PALAVRAS_RELAMPAGO.md §3) — texto e
    // cor mais suaves, nem tão neutros quanto acerto nem tão duros
    // quanto erro de verdade.
    final feedbackText = Text(
      timedOut
          ? l10n.relampagoTimedOutFeedback
          : (isCorrect ? l10n.correctAnswerFeedback : l10n.incorrectAnswerFeedback),
      // Celebração em teal (acerto) vs. terracota suave (erro, nunca
      // vermelho vivo) — DESIGN_SYSTEM.md §4.
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: timedOut ? AppColors.muted : (isCorrect ? AppColors.success : AppColors.error),
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
                if (speedBonusXp > 0) ...[
                  const SizedBox(height: 8),
                  PulseIn(
                    intensity: 0.3,
                    child: Text(
                      l10n.relampagoSpeedBonusMessage(speedBonusXp),
                      style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
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
                  ShareAchievementButton(message: l10n.shareLevelUpMessage(newLevel), client: widget.client),
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
                  ShareAchievementButton(message: l10n.shareTerritoryConqueredMessage(widget.territoryLabel), client: widget.client),
                ],
                if (territoryDetentorGained) ...[
                  const SizedBox(height: 16),
                  PulseIn(
                    intensity: 0.3,
                    child: Text(
                      l10n.territoryDetentorGainedMessage(widget.territoryLabel),
                      style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
                    ),
                  ),
                  ShareAchievementButton(message: l10n.shareTerritoryDetentorMessage(widget.territoryLabel), client: widget.client),
                ],
                if (worldJustCompleted && completedWorldName != null) ...[
                  const SizedBox(height: 16),
                  PulseIn(
                    intensity: 0.3,
                    child: Text(
                      l10n.worldCompletedCelebrationMessage(completedWorldName, worldCompletionBonusXp),
                      style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
                    ),
                  ),
                  ShareAchievementButton(message: l10n.shareWorldCompletedMessage(completedWorldName), client: widget.client),
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
                  ShareAchievementButton(message: l10n.shareBadgeUnlockedMessage(badge['name'] as String), client: widget.client),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // V2 item 14 — batalha é um evento único por lado: depois de
        // responder, não há "próximo desafio" da mesma batalha, então o
        // botão volta pra tela anterior em vez de tentar buscar de novo.
        FilledButton(
          onPressed: widget.battleId != null ? () => Navigator.of(context).pop() : _loadNextChallenge,
          child: Text(widget.battleId != null ? l10n.backButton : l10n.nextChallengeButton),
        ),
      ],
    );
  }
}
