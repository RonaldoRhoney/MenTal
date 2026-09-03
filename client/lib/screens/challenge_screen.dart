import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/feedback_service.dart';
import '../theme/app_theme.dart';
import '../visual_options.dart';
import 'learning_pause_screen.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/coins_rise_overlay.dart';
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

  // FEEDBACK_POS_NIVEL.md (aprovado) — coleta pura de opinião pós-nível,
  // nunca afeta hint_penalty_factor nem qualquer mecânica adaptativa.
  // _feedbackHandled evita disparo duplo (ex.: dois taps rápidos nos
  // blocos) já navegando/enviando de novo.
  String? _feedbackAction;
  String? _feedbackDifficulty;
  bool _feedbackHandled = false;
  final TextEditingController _feedbackCommentController = TextEditingController();

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

  // V4 — Detetive Mental (V4/V4_NOVOS_TERRITORIOS.md §4). Pistas
  // reveladas em etapas ANTES da pergunta/opções aparecerem —
  // _cluesRevealedCount conta quantas já foram mostradas (1 = só a
  // primeira, visível assim que o desafio carrega); _showingQuestion
  // vira true depois que o jogador pede pra ver a pergunta final, só
  // então o corpo normal do desafio (prompt + options) é renderizado.
  int _cluesRevealedCount = 0;
  bool _showingQuestion = false;

  // V4 — Ouvido Afiado (V4/V4_NOVOS_TERRITORIOS.md §3). Um único
  // AudioPlayer reaproveitado durante a vida da tela (mesmo padrão de
  // instância única já usado em FeedbackService) — reprodução via URL
  // (UrlSource), nunca asset embutido no app (o conteúdo curado vem do
  // backend, mesma autoridade de servidor de todo o resto do app).
  late final AudioPlayer _audioPlayer;
  bool _audioPlaying = false;
  bool _audioLoadFailed = false;
  bool _audioHasPlayedOnce = false;

  // MICROINTERACTIONS.md §3 — celebração forte (território/badge/level
  // up) usa confete + fogos + balões (pedido explícito: algo que remeta a
  // comemoração de verdade, não só confete); sons e o pulso sutil/
  // moderado não precisam de controller próprio.
  late final CelebrationController _celebration;

  // Pedido de Rhoney (2026-09-02): moedas sobem na tela ao cruzar 100 XP
  // ou 50 MentalCoins (services.crossed_coin_milestone) — reforço visual
  // leve, independente da celebração forte acima (pode disparar junto ou
  // sozinho, dependendo do que o backend sinalizar).
  late final CoinsRiseController _coinsRise;

  @override
  void initState() {
    super.initState();
    _celebration = CelebrationController();
    _coinsRise = CoinsRiseController();
    _audioPlayer = AudioPlayer();
    _loadNextChallenge();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _celebration.dispose();
    _coinsRise.dispose();
    _feedbackCommentController.dispose();
    _audioPlayer.dispose();
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
    final coinMilestoneReached = result['coin_milestone_reached'] as bool? ?? false;

    final isStrongEvent = levelUp || territoryJustConquered || territoryDetentorGained || worldJustCompleted || newlyAwardedBadges.isNotEmpty;

    if (coinMilestoneReached && !MediaQuery.of(context).disableAnimations) {
      _coinsRise.play();
    }

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
      _attemptId = null;
      _remainingMs = null;
      _timeLimitMs = null;
      _challengeShownAt = null;
      _submitted = false;
      _feedbackAction = null;
      _feedbackDifficulty = null;
      _feedbackHandled = false;
      _feedbackCommentController.clear();
      _cluesRevealedCount = 0;
      _showingQuestion = false;
      _audioPlaying = false;
      _audioLoadFailed = false;
      _audioHasPlayedOnce = false;
    });
    unawaited(_audioPlayer.stop());
    try {
      final challenge = widget.battleId != null
          ? (widget.prefetchedChallenge ?? await widget.client.getMyBattleChallenge(widget.battleId!))
          : await widget.client.nextChallenge(
              widget.territoryId,
              mode: widget.relampago ? 'relampago' : 'normal',
            );
      if (mounted) {
        final clues = (challenge['clues'] as List?)?.cast<String>();
        setState(() {
          _challenge = challenge;
          // Achado de auditoria de segurança (28/08/2026): attempt_id
          // agora nasce no servidor junto do served_at usado pro bônus
          // de velocidade (GET /challenges/next) — só o fluxo de
          // Batalha (getMyBattleChallenge/prefetchedChallenge) ainda não
          // devolve um, e mantém a geração local como estava.
          _attemptId = challenge['attempt_id'] as String? ?? _uuid.v4();
          // V4 — Detetive Mental: a primeira pista já aparece assim que
          // o caso carrega, sem exigir um toque extra pra "começar".
          if (clues != null && clues.isNotEmpty) _cluesRevealedCount = 1;
        });
        final timeLimitSeconds = challenge['time_limit_seconds'] as int?;
        // V4 — Detetive Mental: quando há pistas, o cronômetro (modo
        // Relâmpago) só começa depois que o jogador pede pra ver a
        // pergunta (_revealQuestion) — ler as pistas com calma não pode
        // consumir o tempo da decisão final.
        if (timeLimitSeconds != null && (clues == null || clues.isEmpty)) {
          _startCountdown(timeLimitSeconds);
        }
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

  /// Achado de investigação de bug (28/08/2026, U.I/BUG_DESAFIO_NAO_AVANCA.md):
  /// _submitOption/_submitTimedOut/_requestHint/_submitAnswer tratavam erro
  /// da API escrevendo em `_error`, mas esse campo só é exibido quando
  /// `_challenge == null` (tela de erro fatal, ex.: falha ao CARREGAR um
  /// desafio) — no meio de uma resposta `_challenge` já está preenchido,
  /// então a mensagem nunca aparecia: a tela ficava parada sem nenhum
  /// aviso, indistinguível de "travou". Ficou mais fácil de acontecer
  /// depois da correção de segurança que passou a checar o limite diário
  /// também em POST /answer (antes só GET /next checava). SnackBar é
  /// transiente e não deixa a tela presa em nenhum estado — o usuário
  /// pode tentar de novo imediatamente.
  void _showAnswerApiError(ApiException e) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final message = switch (e.code) {
      'DAILY_LIMIT_REACHED' => l10n.dailyLimitReachedMessage,
      'TERRITORY_LOCKED' => l10n.territoryLockedMessage,
      _ => e.message,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
      // _submitted precisa voltar a false aqui — diferente de
      // _submitAnswer (digitado), os botões de opção do relâmpago
      // dependem de `_submitted` pra reabilitar (linha ~602). Sem isso,
      // uma falha deixava TODAS as opções permanentemente desabilitadas,
      // sem nenhum jeito de tentar de novo a não ser sair da tela.
      if (mounted) setState(() => _submitted = false);
      _showAnswerApiError(e);
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
      if (mounted) setState(() => _submitted = false);
      _showAnswerApiError(e);
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
        _showAnswerApiError(e);
      }
    }
  }

  /// V4 — Ouvido Afiado (V4/V4_NOVOS_TERRITORIOS.md §3). Reprodução via
  /// URL nunca é requisito garantido (rede instável, formato não
  /// suportado no aparelho) — uma falha aqui mostra erro + permite
  /// tentar de novo, mas nunca trava o resto da tela (mesmo princípio de
  /// "som é reforço, nunca bloqueio" já usado em FeedbackService).
  Future<void> _playChallengeAudio(String url) async {
    setState(() {
      _audioPlaying = true;
      _audioLoadFailed = false;
    });
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
      if (mounted) setState(() => _audioHasPlayedOnce = true);
    } catch (_) {
      if (mounted) setState(() => _audioLoadFailed = true);
    } finally {
      if (mounted) setState(() => _audioPlaying = false);
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
      _showAnswerApiError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// FEEDBACK_POS_NIVEL.md §3 — "Repetir este nível" precisa de fato
  /// refazer o MESMO desafio, não buscar um novo (_loadNextChallenge
  /// sorteia outro). Mantém `_challenge` intacto, só reseta o estado de
  /// resposta/tentativa.
  Future<void> _repeatSameChallenge() async {
    _countdownTimer?.cancel();
    final clues = (_challenge?['clues'] as List?)?.cast<String>();
    setState(() {
      _attemptId = _uuid.v4();
      _selectedOption = null;
      _hintsShown = [];
      _hintsExhausted = false;
      _result = null;
      _submitted = false;
      _remainingMs = null;
      _feedbackAction = null;
      _feedbackDifficulty = null;
      _feedbackHandled = false;
      _feedbackCommentController.clear();
      _cluesRevealedCount = (clues != null && clues.isNotEmpty) ? 1 : 0;
      _showingQuestion = false;
      _audioPlaying = false;
      _audioLoadFailed = false;
      _audioHasPlayedOnce = false;
    });
    unawaited(_audioPlayer.stop());
    final timeLimitSeconds = _challenge?['time_limit_seconds'] as int?;
    if (timeLimitSeconds != null && (clues == null || clues.isEmpty)) {
      _startCountdown(timeLimitSeconds);
    }
  }

  /// V4 — Detetive Mental: chamado pelo botão "Ver pergunta" depois da
  /// última pista. Se o desafio também estiver no modo Relâmpago
  /// (time_limit_seconds presente), é só AGORA que o cronômetro começa
  /// — nunca durante a leitura das pistas.
  void _revealQuestion() {
    setState(() => _showingQuestion = true);
    final timeLimitSeconds = _challenge?['time_limit_seconds'] as int?;
    if (timeLimitSeconds != null) _startCountdown(timeLimitSeconds);
  }

  /// Dispara assim que os dois blocos obrigatórios (ação + dificuldade)
  /// estiverem escolhidos — 1 toque por bloco, sem passo extra de
  /// "confirmar" (FEEDBACK_POS_NIVEL.md §3, "sem fricção"). O comentário
  /// livre é opcional e nunca bloqueia esse disparo. Envio ao backend é
  /// melhor esforço: uma falha de rede aqui não deve travar a navegação
  /// do jogador (é coleta de opinião, não uma ação crítica do core loop).
  void _maybeSubmitLevelFeedback() {
    if (_feedbackHandled || _feedbackAction == null || _feedbackDifficulty == null) return;
    _feedbackHandled = true;

    final challengeId = _challenge?['challenge_id'] as String?;
    final action = _feedbackAction!;
    final difficulty = _feedbackDifficulty!;
    final comment = _feedbackCommentController.text.trim();
    if (challengeId != null) {
      unawaited(
        widget.client
            .submitLevelFeedback(
              challengeId: challengeId,
              action: action,
              difficultyRating: difficulty,
              comment: comment.isEmpty ? null : comment,
            )
            .catchError((_) => <String, dynamic>{}),
      );
    }

    if (action == 'repeat') {
      _repeatSameChallenge();
    } else {
      _loadNextChallenge();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.territoryLabel),
        // V3.2 (V3/V3.2_TECNOLOGIA.md §3) — acesso à Pausa para Aprender
        // como ação alternativa dentro do território (mesmo espírito do
        // botão Relâmpago), nunca uma interrupção aleatória do fluxo
        // normal de desafios. Sempre visível — territórios sem Pausa
        // curada ainda mostram uma mensagem de "ainda não há" ao tocar,
        // em vez de a checagem de disponibilidade atrasar esta tela.
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.learningPauseButtonTooltip,
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LearningPauseScreen(
                  client: widget.client,
                  territoryId: widget.territoryId,
                  territoryLabel: widget.territoryLabel,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: CelebrationOverlay(
          controller: _celebration,
          child: CoinsRiseOverlay(
            controller: _coinsRise,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildBody(),
            ),
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
              style: TextStyle(color: AppColors.error),
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

  /// Pedido de Rhoney (29/08/2026): "as perguntas e respostas estão muito
  /// acima na tela... deixe um pouco no centro". Antes, o Expanded +
  /// SingleChildScrollView deixava o conteúdo colado no topo sempre que
  /// ele coubesse na tela, sobrando um vazio de fundo escuro embaixo.
  /// Center dentro de um ConstrainedBox(minHeight: altura do viewport)
  /// resolve os dois casos: quando o conteúdo cabe, centraliza
  /// verticalmente; quando não cabe (parágrafos longos de "Textos", por
  /// exemplo), o ConstrainedBox cresce além do minHeight e o scroll
  /// funciona normalmente, sem cortar nada. SizedBox(width: infinity)
  /// preserva o "stretch" horizontal que o Column original já tinha
  /// (botões/RadioListTile ocupando a largura toda).
  Widget _verticallyCenteredScroll(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: SizedBox(width: double.infinity, child: child)),
          ),
        );
      },
    );
  }

  /// V4 — Detetive Mental (V4/V4_NOVOS_TERRITORIOS.md §4): revelação
  /// progressiva das pistas, uma de cada vez, antes da pergunta final.
  /// "Próxima pista" avança _cluesRevealedCount; ao chegar na última
  /// pista, o botão vira "Ver pergunta" (_revealQuestion), que é quando
  /// o corpo normal do desafio (prompt + options, e o cronômetro do
  /// Relâmpago, se houver) passa a ser mostrado.
  Widget _buildDetectiveClues(List<String> clues) {
    final l10n = AppLocalizations.of(context)!;
    final revealed = clues.take(_cluesRevealedCount);
    final isLastClueRevealed = _cluesRevealedCount >= clues.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _verticallyCenteredScroll(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, clue) in revealed.indexed) ...[
                  Text(
                    l10n.detectiveClueLabel(index + 1),
                    style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(clue, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: isLastClueRevealed
              ? _revealQuestion
              : () => setState(() => _cluesRevealedCount++),
          child: Text(isLastClueRevealed ? l10n.detectiveRevealQuestionButton : l10n.detectiveNextClueButton),
        ),
      ],
    );
  }

  /// V4 — Ouvido Afiado (V4/V4_NOVOS_TERRITORIOS.md §3). Botão único de
  /// tocar/tocar de novo + crédito de atribuição da fonte (mesma
  /// disciplina de transparência de origem já usada nos vídeos da Pausa
  /// para Aprender de Libras, video_url/source_name/source_url).
  Widget _buildAudioPlayerSection(String audioUrl, String? sourceName) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        FilledButton.icon(
          onPressed: _audioPlaying ? null : () => _playChallengeAudio(audioUrl),
          icon: Icon(_audioHasPlayedOnce ? Icons.replay : Icons.play_arrow),
          label: Text(_audioHasPlayedOnce ? l10n.audioReplayButton : l10n.audioPlayButton),
        ),
        if (_audioLoadFailed) ...[
          const SizedBox(height: 8),
          Text(l10n.audioLoadErrorMessage, style: TextStyle(color: AppColors.error)),
        ],
        if (sourceName != null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.audioSourceCreditLabel(sourceName),
            textAlign: TextAlign.center,
            style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildChallenge() {
    final l10n = AppLocalizations.of(context)!;
    final challenge = _challenge!;
    final options = (challenge['options'] as List?)?.cast<String>();

    // V4 — Detetive Mental (V4/V4_NOVOS_TERRITORIOS.md §4): enquanto o
    // jogador ainda não pediu pra ver a pergunta final, a tela mostra só
    // as pistas reveladas até agora — prompt/options ficam escondidos.
    final clues = (challenge['clues'] as List?)?.cast<String>();
    if (clues != null && clues.isNotEmpty && !_showingQuestion) {
      return _buildDetectiveClues(clues);
    }

    // CONHECIMENTO_EXPANSAO_GERAL.md (aprovado 2026-08-22): quem decide
    // "este desafio tem tempo" é o SERVIDOR (time_limit_seconds na
    // resposta), nunca um flag local — generaliza pra além de Palavras
    // (widget.relampago só controla se PEDIMOS o modo opcional; o
    // backend pode mandar tempo mesmo sem isso, caso de Conhecimento,
    // onde o formato é obrigatório).
    if (_timeLimitMs != null && options != null) {
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
          child: _verticallyCenteredScroll(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (challenge['prompt_image'] != null) ...[
                  Text(challenge['prompt_image'] as String, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                ],
                if (challenge['audio_url'] != null)
                  _buildAudioPlayerSection(challenge['audio_url'] as String, challenge['audio_source_name'] as String?),
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
                      style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.muted),
                    ),
                  ),
                ),
                if (_hintsExhausted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      l10n.noMoreHintsMessage,
                      style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.muted),
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
          child: _verticallyCenteredScroll(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (challenge['prompt_image'] != null) ...[
                  Text(challenge['prompt_image'] as String, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                ],
                if (challenge['audio_url'] != null)
                  _buildAudioPlayerSection(challenge['audio_url'] as String, challenge['audio_source_name'] as String?),
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
    // BUG_PERGUNTAS_REPETINDO_SEQUENCIA.md §2.3 — este era o último item
    // do lote sem repetição deste território+dificuldade: não existe
    // "próximo" real até o backend reembaralhar, então a tela volta à
    // Home em vez de oferecer repetir/seguir.
    final batchExhausted = result['batch_exhausted'] as bool? ?? false;

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
          child: _verticallyCenteredScroll(
            Column(
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
                      style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600),
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
                      style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                if (levelUp && newLevel != null) ...[
                  const SizedBox(height: 16),
                  PulseIn(
                    intensity: 0.3,
                    child: Text(
                      l10n.levelUpMessage(newLevel),
                      style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
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
                      style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
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
                      style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
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
                      style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
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
                      style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
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
        // botão volta pra tela anterior em vez de mostrar o bloco de
        // feedback (que fala em "nível", conceito que não existe numa
        // batalha pontual entre dois jogadores).
        if (widget.battleId != null)
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.backButton))
        else if (batchExhausted) ...[
          Text(
            l10n.batchCompletedMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: Text(l10n.batchCompletedBackToHomeButton),
          ),
        ] else if (levelUp)
          // FEEDBACK_POS_NIVEL.md §3 — "aparece sempre que um nível é
          // concluído", não a cada resposta. Achado real (2026-08-26,
          // teste fechado): mostrar em toda resposta causava fricção e
          // risco de abandono. "Nível" aqui é o Nível geral do jogador
          // (profile.level, por XP) — o mesmo já exibido na Home — não o
          // desafio individual. O backend já calcula level_up/new_level
          // pra decidir a celebração; reaproveita o mesmo sinal aqui.
          _buildLevelFeedback()
        else
          FilledButton(onPressed: _loadNextChallenge, child: Text(l10n.nextChallengeButton)),
      ],
    );
  }

  /// FEEDBACK_POS_NIVEL.md — 3 blocos na mesma tela de resultado: ação,
  /// avaliação de dificuldade (1 toque cada) e comentário livre opcional.
  /// Assim que ação + dificuldade estiverem escolhidas, dispara o envio e
  /// já navega (_maybeSubmitLevelFeedback) — sem botão extra de "confirmar
  /// feedback", pra não parecer formulário burocrático.
  Widget _buildLevelFeedback() {
    final l10n = AppLocalizations.of(context)!;

    Widget actionChip(String value, String label) {
      final selected = _feedbackAction == value;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: selected ? AppColors.gold.withValues(alpha: 0.15) : null,
              side: BorderSide(color: selected ? AppColors.gold : AppColors.muted),
            ),
            onPressed: () {
              setState(() => _feedbackAction = value);
              _maybeSubmitLevelFeedback();
            },
            child: Text(label, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    Widget difficultyChip(String value, String label) {
      final selected = _feedbackDifficulty == value;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: AppColors.teal.withValues(alpha: 0.25),
        side: BorderSide(color: selected ? AppColors.teal : AppColors.muted),
        onSelected: (_) {
          setState(() => _feedbackDifficulty = value);
          _maybeSubmitLevelFeedback();
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.levelFeedbackHeading,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            actionChip('repeat', l10n.levelFeedbackRepeatAction),
            actionChip('continue', l10n.levelFeedbackContinueAction),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            difficultyChip('facil', l10n.levelFeedbackDifficultyFacil),
            difficultyChip('medio', l10n.levelFeedbackDifficultyMedio),
            difficultyChip('dificil', l10n.levelFeedbackDifficultyDificil),
            difficultyChip('muito_dificil', l10n.levelFeedbackDifficultyMuitoDificil),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _feedbackCommentController,
          decoration: InputDecoration(hintText: l10n.levelFeedbackCommentHint),
          minLines: 1,
          maxLines: 3,
        ),
      ],
    );
  }
}
