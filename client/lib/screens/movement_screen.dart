import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/feedback_service.dart';
import '../services/movement_service.dart';
import '../theme/app_theme.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/mentalcoin.dart';
import '../widgets/pulse_in.dart';
import '../widgets/share_achievement_button.dart';

/// V2 item 9 — Contador de passos (STEP_COUNTER_MOVIMENTO.md). O backend
/// é sempre a autoridade sobre o estado do ciclo e o XP convertido —
/// esta tela só lê o sensor local para saber QUANTOS passos ainda não
/// foram enviados, nunca decide o bônus sozinha.
///
/// Redesign (U.I/MOVIMENTO_REDESIGN_V1.md, 29/08/2026): bloco Hero
/// compacto (anel + estatísticas de Passos/XP/MentalCoins lado a lado),
/// regra "100 passos = +2 XP" sempre visível, seletor de meta diária em
/// chips + meta customizada com confirmação via botão "Go" (pedido de
/// Rhoney, 29/08/2026: "existem pessoas que... facilmente vão além de
/// 20k diário"). Layout em Column com Expanded nos gráficos — nenhum
/// SingleChildScrollView — pra caber inteiro sem rolagem.
class MovementScreen extends StatefulWidget {
  const MovementScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<MovementScreen> createState() => _MovementScreenState();
}

class _MovementScreenState extends State<MovementScreen> {
  bool _loading = true;
  String? _error;
  bool _movementEnabled = false;
  int? _dailyGoalSteps;
  Map<String, dynamic>? _currentCycle;
  Map<String, dynamic>? _pendingReportCycle;
  List<Map<String, dynamic>> _recentCycles = [];
  int _detectedUncollectedSteps = 0;
  String? _goalReachedMessage;
  String? _checkpointReachedMessage;
  int? _lastRawStepsSinceBoot;
  int _streakDays = 0;
  int? _mentalCoinsBalance;
  // Achado real (29/08/2026): reinstalar o app (ou trocar de aparelho)
  // com Movimento já ativado na conta reseta a permissão do Android,
  // mas a flag do servidor (_movementEnabled) continua true — sem essa
  // checagem à parte, a tela mostrava o painel inteiro normalmente e só
  // dizia "sensor indisponível", sem nunca oferecer um jeito de resolver.
  bool _permissionMissing = false;
  // Começa true: só vira false quando o primeiro evento REAL do sensor
  // chegar. Achado real testando no Moto G22 (2026-08-21):
  // TYPE_STEP_COUNTER não entrega uma leitura imediata ao registrar o
  // listener — só emite quando um passo de verdade acontece depois
  // disso. Por isso a tela precisa manter a assinatura viva (nunca uma
  // leitura pontual com timeout) e mostrar "indisponível" até o
  // primeiro passo real ser detectado.
  bool _sensorUnavailable = true;
  bool _busy = false;
  StreamSubscription<int>? _stepSub;
  // Coleta automática (V3, achado real de campo 29/08/2026, doc
  // BUG_MOVIMENTO_XP_GRAFICOS.md): antes, XP e os dois gráficos só
  // existiam depois de uma coleta manual, e coleta manual só era
  // possível ao atingir pelo menos 5k passos — uma caminhada real de
  // ~800 passos nunca disparava nada no backend. Agora a tela coleta
  // sozinha em segundo plano, em pequenos intervalos, sem esperar
  // nenhum patamar — collect_steps() no backend já foi desenhado pra
  // aceitar deltas pequenos repetidos (soma cumulativa, reavalia faixa/
  // checkpoint a cada chamada), só nunca tinha sido chamado assim.
  DateTime? _lastAutoCollectAt;
  bool _autoCollecting = false;
  static const _autoCollectMinInterval = Duration(seconds: 20);

  late final CelebrationController _celebration;

  // O 4º slot da meta diária (U.I) virou o card editável (29/08/2026,
  // pedido de Rhoney: "o último card deve ser editável, isso resolve o
  // problema do jogador estabelecer sua própria meta") — substitui o
  // antigo tier fixo de 20k.
  static const _goalTiers = [5000, 10000, 15000];

  @override
  void initState() {
    super.initState();
    _celebration = CelebrationController();
    // Recebe leituras do sensor capturadas pelo foreground service
    // (movement_task_handler.dart) mesmo com esta tela fechada — é essa
    // via, e não a stream direta abaixo, que sustenta a contagem com o
    // app em segundo plano/tela apagada.
    FlutterForegroundTask.addTaskDataCallback(_onForegroundTaskData);
    _load();
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    FlutterForegroundTask.removeTaskDataCallback(_onForegroundTaskData);
    _celebration.dispose();
    super.dispose();
  }

  void _onForegroundTaskData(Object data) {
    final cycleId = _currentCycle?['id'] as String?;
    if (cycleId == null || data is! Map || data['steps'] is! int) return;
    _handleRawSteps(cycleId, data['steps'] as int);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final status = await widget.client.movementStatus();
      _movementEnabled = status['movement_enabled'] as bool;
      _dailyGoalSteps = status['daily_goal_steps'] as int?;
      _currentCycle = status['current_cycle'] as Map<String, dynamic>?;
      _pendingReportCycle = status['pending_report_cycle'] as Map<String, dynamic>?;
      // Backend devolve mais recente primeiro — inverte pra ordem
      // cronológica (esquerda→direita) esperada num gráfico de barras.
      _recentCycles = ((status['recent_cycles'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .reversed
          .toList();
      if (_movementEnabled && _currentCycle != null) {
        final cycleId = _currentCycle!['id'] as String;
        await MovementService.instance.ensureBaselineFor(cycleId);
        final cachedLast = await MovementService.instance.lastKnownRawSteps();
        if (cachedLast != null) {
          _lastRawStepsSinceBoot = cachedLast;
          final delta = await MovementService.instance.pendingDeltaFor(cycleId, cachedLast);
          _detectedUncollectedSteps = delta.uncollectedSteps;
          // Já temos uma leitura de uma sessão anterior — mostra o total
          // certo (inclui passos dados com o app fechado) sem esperar um
          // evento novo do sensor chegar nesta sessão.
          _sensorUnavailable = false;
        }
        _listenToSensor(cycleId);
        unawaited(_ensurePermissionAndStartTracking());
      } else {
        _stepSub?.cancel();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    // Chip de streak no header + saldo de MentalCoins no Hero
    // (U.I/MOVIMENTO_REDESIGN_V1.md §3, pedido de Rhoney 29/08/2026:
    // "dê maior destaque aos passos, XP, MentalCoins") — reforço visual,
    // nunca bloqueia a tela se falhar.
    try {
      final progress = await widget.client.progress();
      if (mounted) setState(() => _streakDays = progress['streak']['current_streak'] as int);
    } on ApiException catch (_) {}
    try {
      final balance = await widget.client.getMentalCoinsBalance();
      if (mounted) setState(() => _mentalCoinsBalance = balance['balance'] as int);
    } on ApiException catch (_) {}
  }

  void _listenToSensor(String cycleId) {
    _stepSub?.cancel();
    // Além da leitura em tempo real do foreground service (via
    // _onForegroundTaskData), mantém também a assinatura local — cobre o
    // intervalo entre ativar a permissão e o serviço terminar de subir,
    // e serve de fallback se o serviço falhar ao iniciar em algum
    // aparelho (startForegroundTracking nunca derruba o app).
    _stepSub = MovementService.instance.stepCountStream().listen(
      (steps) => _handleRawSteps(cycleId, steps),
      onError: (_) {
        if (mounted) setState(() => _sensorUnavailable = true);
      },
    );
  }

  /// Checa a permissão REAL do Android (não só a flag do servidor) antes
  /// de subir o foreground service — achado real (29/08/2026):
  /// reinstalar o app (ou trocar de aparelho) com Movimento já ativado
  /// na conta reseta a permissão do Android, mas movement_enabled
  /// continua true; sem isso, a tela ficava travada em "sensor
  /// indisponível" pra sempre, sem nenhuma ação possível. Tenta pedir de
  /// novo automaticamente; só se a resposta continuar negada é que
  /// mostra o aviso com o botão pra abrir as Configurações do Android
  /// (único jeito de reverter um "não perguntar de novo").
  Future<void> _ensurePermissionAndStartTracking() async {
    final hasPermission = await MovementService.instance.hasPermission();
    final granted = hasPermission || await MovementService.instance.requestPermission();
    if (mounted) setState(() => _permissionMissing = !granted);
    if (!granted) return;
    await MovementService.instance.startForegroundTracking();
  }

  Future<void> _handleRawSteps(String cycleId, int steps) async {
    _lastRawStepsSinceBoot = steps;
    final delta = await MovementService.instance.pendingDeltaFor(cycleId, steps);
    if (mounted) {
      setState(() {
        _sensorUnavailable = false;
        _detectedUncollectedSteps = delta.uncollectedSteps;
      });
    }
    unawaited(_maybeAutoCollect(cycleId));
  }

  /// Coleta automática do ciclo ATUAL — nunca do ciclo anterior pendente
  /// (isso continua manual, ver _doCollectPending). Throttle de
  /// _autoCollectMinInterval evita um POST a cada passo detectado
  /// (TYPE_STEP_COUNTER pode emitir bem mais de um evento por segundo
  /// andando); falha de rede é silenciosa de propósito — a próxima
  /// leitura de passo tenta nesse ciclo, ou o próximo tenta de novo,
  /// nunca interrompe a caminhada por causa disso.
  Future<void> _maybeAutoCollect(String cycleId) async {
    if (_autoCollecting || _detectedUncollectedSteps <= 0 || _currentCycle == null) return;
    final last = _lastAutoCollectAt;
    if (last != null && DateTime.now().difference(last) < _autoCollectMinInterval) return;
    _autoCollecting = true;
    _lastAutoCollectAt = DateTime.now();
    try {
      final localDelta = _detectedUncollectedSteps;
      final result = await widget.client.collectMovementSteps(steps: localDelta, cycleId: cycleId);
      final updatedCycle = result['cycle'] as Map<String, dynamic>;
      await _handleCollectResponse(result, cycleId, updatedCycle['steps_collected'] as int);
      if (mounted) {
        setState(() {
          _currentCycle = updatedCycle;
          _detectedUncollectedSteps = 0;
        });
      }
    } on ApiException catch (_) {
    } finally {
      _autoCollecting = false;
    }
  }

  Future<void> _enable() async {
    setState(() => _busy = true);
    try {
      final granted = await MovementService.instance.requestPermission();
      if (!granted) {
        if (mounted) {
          final message = AppLocalizations.of(context)!.movementPermissionDeniedMessage;
          setState(() {
            _error = message;
            _busy = false;
          });
        }
        return;
      }
      await widget.client.enableMovement();
      await MovementService.instance.startForegroundTracking();
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disable() async {
    setState(() => _busy = true);
    try {
      await widget.client.disableMovement();
      await MovementService.instance.stopForegroundTracking();
      await MovementService.instance.clear();
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleCollectResponse(Map<String, dynamic> result, String cycleId, int totalStepsInCycle) async {
    await MovementService.instance.markCollected(cycleId, totalStepsInCycle);
    final xpAwarded = result['xp_awarded'] as int;
    final levelUp = result['level_up'] as bool? ?? false;
    final goalReached = result['goal_reached'] as bool? ?? false;
    final checkpointsReached = result['checkpoints_reached'] as int? ?? 0;
    // MentalCoins por passo (29/08/2026: "a cada 1000 passos = 5
    // MentalCoins") — vem direto na resposta da coleta, sem chamada de
    // rede extra (a coleta ficou muito mais frequente com a coleta
    // automática em segundo plano).
    final mentalCoinsAwarded = result['mentalcoins_awarded'] as int? ?? 0;
    if (mentalCoinsAwarded > 0 && mounted) {
      setState(() => _mentalCoinsBalance = (_mentalCoinsBalance ?? 0) + mentalCoinsAwarded);
    }
    if (xpAwarded > 0) {
      FeedbackService.instance.play(FeedbackSound.correct);
    }
    if (goalReached && mounted) {
      setState(() => _goalReachedMessage = AppLocalizations.of(context)!.movementGoalReachedMessage(xpAwarded));
    }
    if (checkpointsReached > 0 && mounted) {
      // O backend não separa quanto do XP desta chamada veio de
      // checkpoint vs. faixa normal vs. meta — mostra o total ganho
      // nesta coleta, não um valor isolado por checkpoint.
      setState(
        () => _checkpointReachedMessage = AppLocalizations.of(context)!.movementCheckpointReachedMessage(
          checkpointsReached,
          xpAwarded,
        ),
      );
    }
    if (levelUp || goalReached || checkpointsReached > 0) {
      FeedbackService.instance.play(FeedbackSound.celebration);
      if (mounted && !MediaQuery.of(context).disableAnimations) {
        _celebration.celebrate();
      }
    }
  }

  Future<void> _setGoal(int steps) async {
    if (_dailyGoalSteps == steps || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.client.setMovementGoal(steps);
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _hasStepsToCollect => _detectedUncollectedSteps > 0 || _pendingReportCycle != null;

  /// Coleta disparada ao tocar num nível de meta aceso no seletor
  /// (29/08/2026, pedido de Rhoney: "a coleta de ciclo deve ser ao
  /// tocar cada nível diário alcançado") — substitui os antigos botões
  /// "Coletar"/"Coletar ciclo anterior". Um único toque resolve os dois:
  /// se existir ciclo anterior pendente, ele entra primeiro, sem UI
  /// dedicada.
  Future<void> _collectReachedLevel() async {
    if (_busy || !_hasStepsToCollect) return;
    setState(() => _busy = true);
    try {
      if (_pendingReportCycle != null) await _doCollectPending();
      if (_detectedUncollectedSteps > 0) await _doCollectCurrent();
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _doCollectCurrent() async {
    final cycle = _currentCycle;
    if (cycle == null) return;
    final localDelta = _detectedUncollectedSteps;
    final result = await widget.client.collectMovementSteps(steps: localDelta);
    final updatedCycle = result['cycle'] as Map<String, dynamic>;
    await _handleCollectResponse(result, cycle['id'] as String, updatedCycle['steps_collected'] as int);
  }

  Future<void> _doCollectPending() async {
    final pending = _pendingReportCycle;
    if (pending == null) return;
    final pendingId = pending['id'] as String;
    // Usa a última leitura do sensor recebida pela assinatura viva do
    // ciclo atual (mesmo valor absoluto de hardware serve pra
    // calcular o delta de QUALQUER ciclo — o baseline é que muda).
    // Se nenhum passo real foi detectado ainda nesta sessão da tela,
    // envia 0 — nunca bloqueia a coleta do que já está registrado no
    // servidor.
    final lastReading = _lastRawStepsSinceBoot;
    final localDelta = lastReading == null
        ? 0
        : (await MovementService.instance.pendingDeltaFor(pendingId, lastReading)).uncollectedSteps;
    final result = await widget.client.collectMovementSteps(steps: localDelta, cycleId: pendingId);
    final updatedCycle = result['cycle'] as Map<String, dynamic>;
    await _handleCollectResponse(result, pendingId, updatedCycle['steps_collected'] as int);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      // O layout é fixo, sem SingleChildScrollView (pedido de Rhoney,
      // 29/08/2026: "sem precisar de rolagem") — com
      // resizeToAvoidBottomInset padrão (true), o teclado do campo de
      // meta personalizada encolhe a área disponível e a Column
      // estoura por alguns pixels. false mantém o layout intacto; o
      // teclado só sobrepõe a parte de baixo, que já não tem nada
      // essencial de ler enquanto se digita a meta.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(l10n.movementScreenTitle),
        actions: [
          if (_movementEnabled && _streakDays > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded, color: AppColors.gold, size: 16),
                    const SizedBox(width: 4),
                    Text('$_streakDays', style: AppTheme.technicalStyle(color: AppColors.gold, fontSize: 13).copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: CelebrationOverlay(
          controller: _celebration,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: _loading ? const Center(child: CircularProgressIndicator()) : _buildBody(l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (!_movementEnabled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
          ],
          Text(l10n.movementIntro, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          FilledButton(onPressed: _busy ? null : _enable, child: Text(l10n.movementEnableButton)),
        ],
      );
    }

    final currentCycle = _currentCycle;
    // Coluna sem SingleChildScrollView (U.I/MOVIMENTO_REDESIGN_V1.md §8:
    // "requisito funcional, não só estético") — cada seção tem altura
    // compacta e fixa, os dois gráficos dividem o espaço restante via
    // Expanded, proporcionalmente ao conteúdo de cada um.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          Text(_error!, style: TextStyle(color: AppColors.error), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
        ],
        if (_permissionMissing) ...[
          Text(l10n.movementPermissionDeniedMessage, style: TextStyle(color: AppColors.error), maxLines: 3),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => MovementService.instance.openSettings(),
              child: Text(l10n.movementOpenSettingsButton),
            ),
          ),
          const SizedBox(height: 4),
        ],
        if (_pendingReportCycle != null) ...[
          // O ciclo anterior pendente pode não ter caminho nenhum até um
          // nível de meta do dia atual (ex.: usuário ainda não andou o
          // suficiente hoje) — sem isso, o saldo fica preso indefinidamente.
          // Aviso tocável (30/08/2026, bug encontrado ao investigar coleta
          // travada) + botão explícito ao lado (30/08/2026, pedido de
          // Rhoney: um botão visível, não só o texto tocável) — os dois
          // chamam a mesma _collectReachedLevel.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _busy ? null : _collectReachedLevel,
                  child: PulseIn(
                    intensity: 0.2,
                    child: Text(
                      l10n.movementPendingReportLabel(_pendingReportCycle!['steps_collected'] as int),
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.gold.withValues(alpha: 0.5),
                      ),
                      maxLines: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.bg,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                onPressed: _busy ? null : _collectReachedLevel,
                child: Text(l10n.movementCollectPendingButton),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        if (currentCycle != null) ...[
          _HeroBlock(
            // Anel + número precisam refletir o total AO VIVO (badge
            // "LIVE" promete "atualiza em tempo real conforme o usuário
            // anda" — U.I/MOVIMENTO_REDESIGN_V1.md §4), não só o que já
            // foi coletado no servidor. Achado real (29/08/2026,
            // caminhada de teste com meta 15k): sem somar o delta local
            // ainda não coletado, o valor fica parado em 0 até o
            // jogador tocar num card de meta atingido — parecendo que
            // nenhum passo foi contabilizado.
            stepsCollected: (currentCycle['steps_collected'] as int) + _detectedUncollectedSteps,
            xpAwarded: currentCycle['xp_awarded'] as int,
            mentalCoinsBalance: _mentalCoinsBalance,
            goal: _dailyGoalSteps,
          ),
          const SizedBox(height: 8),
          _GoalSelector(
            tiers: _goalTiers,
            currentGoal: _dailyGoalSteps,
            busy: _busy,
            onConfirm: _setGoal,
            // Cada card também funciona como checkpoint de coleta
            // (29/08/2026, pedido de Rhoney): quando o total de passos
            // de hoje alcança o valor do card, ele acende e tocar nele
            // coleta em vez de trocar a meta.
            totalStepsToday: (currentCycle['steps_collected'] as int) + _detectedUncollectedSteps,
            canCollect: _hasStepsToCollect,
            onCollect: _collectReachedLevel,
          ),
          if (_goalReachedMessage != null || _checkpointReachedMessage != null) ...[
            const SizedBox(height: 6),
            if (_goalReachedMessage != null)
              PulseIn(intensity: 0.3, child: Text(_goalReachedMessage!, style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center, maxLines: 2)),
            if (_goalReachedMessage != null) ShareAchievementButton(message: l10n.shareMovementGoalMessage, client: widget.client),
            if (_checkpointReachedMessage != null)
              PulseIn(intensity: 0.3, child: Text(_checkpointReachedMessage!, style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center, maxLines: 2)),
          ],
          const SizedBox(height: 8),
          // Métricas de oscilação diária (29/08/2026, pedido de Rhoney:
          // no lugar dos botões de coletar) — a coleta em si agora
          // acontece ao tocar num nível de meta aceso no seletor acima.
          _OscillationMetricsRow(
            l10n: l10n,
            sensorUnavailable: _sensorUnavailable,
            snapshots: (currentCycle['snapshots'] as List?)?.cast<Map<String, dynamic>>() ?? const [],
            cycleStart: DateTime.parse(currentCycle['cycle_start_at'] as String),
          ),
          const SizedBox(height: 8),
        ],
        // Gráfico intradiário — sempre visível quando o ciclo de hoje
        // existe (30/08/2026, pedido de Rhoney: "crie o gráfico de
        // progresso diário", que antes só aparecia com 2+ registros —
        // na prática quase nunca, já que a coleta ficava presa antes da
        // correção do ciclo pendente). _intradayPoints sempre inclui o
        // ponto inicial (0,0), então mesmo sem nenhum snapshot ainda o
        // gráfico mostra a linha começando do zero.
        if (currentCycle != null)
          Expanded(
            flex: 6,
            // RepaintBoundary (achado real, 29/08/2026 — Rhoney: "telas
            // saltando"): com a coleta automática em segundo plano, esta
            // tela agora recebe um setState a cada passo detectado
            // (_handleRawSteps) — sem isolar o repaint, os dois gráficos
            // (canvas custom do fl_chart, mais pesados que o resto da
            // árvore) repintavam de novo a cada evento, mesmo sem seus
            // próprios dados terem mudado.
            child: RepaintBoundary(
              child: _ChartCard(
                dotColor: AppColors.gold,
                title: l10n.movementTodayChartTitle,
                trailing: l10n.movementTodayChartSubtitle,
                child: _IntradayStepsLineChart(
                  points: _intradayPoints(
                    (currentCycle['snapshots'] as List?)?.cast<Map<String, dynamic>>() ?? const [],
                    DateTime.parse(currentCycle['cycle_start_at'] as String),
                  ),
                ),
              ),
            ),
          ),
        if (currentCycle != null) const SizedBox(height: 8),
        // Gráfico semanal — precisa de pelo menos 2 ciclos.
        if (_recentCycles.length >= 2)
          Expanded(
            flex: 5,
            child: RepaintBoundary(
              child: _ChartCard(
                dotColor: AppColors.teal,
                title: l10n.movementWeeklyChartTitle,
                trailing: l10n.movementWeeklyChartSubtitle,
                child: _WeeklyStepsBarChart(cycles: _recentCycles),
              ),
            ),
          ),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 12)),
            onPressed: _busy ? null : _disable,
            child: Text(l10n.movementDisableButton, style: const TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }
}

/// Bloco Hero (U.I/MOVIMENTO_REDESIGN_V1.md §4) — anel de progresso +
/// estatísticas de Passos/XP/MentalCoins lado a lado num único card
/// compacto. A regra de conversão "100 passos = +2 XP" fica sempre
/// visível aqui, nunca implícita. MentalCoins adicionado (29/08/2026,
/// pedido de Rhoney: "dê maior destaque aos passos, XP, MentalCoins") —
/// reforça a ligação entre passos e a moeda de prestígio semanal
/// (campeão/recordista de passos ganham MentalCoins, ver
/// U.I/MENTALCOINS_V1.md §3.2).
class _HeroBlock extends StatelessWidget {
  const _HeroBlock({required this.stepsCollected, required this.xpAwarded, required this.mentalCoinsBalance, required this.goal});

  final int stepsCollected;
  final int xpAwarded;
  final int? mentalCoinsBalance;
  final int? goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.bg2, Color.lerp(AppColors.bg2, AppColors.gold, 0.08)!]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ProgressRing(stepsCollected: stepsCollected, goal: goal),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: _HeroStat(icon: Icons.directions_walk_rounded, color: AppColors.gold, value: '$stepsCollected')),
                    Expanded(child: _HeroStat(icon: Icons.bolt_rounded, color: AppColors.teal, value: '$xpAwarded')),
                    Expanded(child: _HeroStat(icon: null, coin: true, color: AppColors.gold, value: '${mentalCoinsBalance ?? 0}')),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Text.rich(
                    textAlign: TextAlign.center,
                    TextSpan(
                      style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 10),
                      children: [
                        TextSpan(text: '100 passos', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
                        const TextSpan(text: ' = '),
                        TextSpan(text: '+2 XP', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Estatística compacta e destacada dentro do Hero — ícone/moeda + valor
/// grande, sem label textual (economiza espaço vertical; o significado
/// já é óbvio pelo ícone/cor: passos, raio de XP, moeda).
class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.color, required this.value, this.icon, this.coin = false});

  final IconData? icon;
  final bool coin;
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        coin ? const MentalCoin(size: 16) : Icon(icon, color: color, size: 16),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: AppTheme.technicalStyle(color: color, fontSize: 17).copyWith(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

/// Anel de progresso compacto (~78px, U.I/MOVIMENTO_REDESIGN_V1.md §4)
/// com badge "AO VIVO" pulsante — versão reduzida do donut anterior
/// (148px), agora ao lado das estatísticas em vez de sozinho centralizado.
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.stepsCollected, required this.goal});

  final int stepsCollected;
  final int? goal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final goal = this.goal;
    final hasGoal = goal != null && goal > 0;
    final progress = hasGoal ? (stepsCollected / goal).clamp(0.0, 1.0) : 0.0;
    final goalReached = hasGoal && stepsCollected >= goal;
    final percent = (progress * 100).round();
    final ringColor = hasGoal ? (goalReached ? AppColors.gold : AppColors.teal) : AppColors.muted;

    return SizedBox(
      height: 82,
      width: 82,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.bg, width: 9)),
          ),
          if (hasGoal)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, animatedProgress, _) => SizedBox(
                width: 78,
                height: 78,
                child: PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 0,
                    centerSpaceRadius: 30,
                    sections: [
                      PieChartSectionData(value: animatedProgress > 0 ? animatedProgress : 0.001, color: ringColor, showTitle: false, radius: 9),
                      PieChartSectionData(value: 1 - animatedProgress, color: Colors.transparent, showTitle: false, radius: 9),
                    ],
                  ),
                ),
              ),
            ),
          SizedBox(
            width: 54,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    hasGoal ? l10n.movementGoalProgressLabel(percent) : '$stepsCollected',
                    style: AppTheme.technicalStyle(color: ringColor, fontSize: hasGoal ? 13 : 16).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (!hasGoal)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(l10n.movementNoGoalProgressLabel, style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 8)),
                  ),
              ],
            ),
          ),
          Positioned(
            top: -2,
            right: -6,
            child: _LiveBadge(),
          ),
        ],
      ),
    );
  }
}

/// Badge "AO VIVO" com ponto pulsante — indica que o valor atualiza em
/// tempo real conforme o usuário anda (leitura contínua do sensor, não
/// uma foto estática do último request).
class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.teal.withValues(alpha: 0.5))),
      child: FadeTransition(
        opacity: Tween(begin: 0.4, end: 1.0).animate(_controller),
        child: SizedBox(width: 5, height: 5, child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.teal))),
      ),
    );
  }
}

/// Seletor de meta diária — chips (5k/10k/15k/20k) + meta customizada
/// (29/08/2026, pedido de Rhoney: "existem pessoas que... facilmente
/// vão além de 20k diário"). Confirmação via botão "Go" em vez de
/// salvar na hora do toque — permite trocar de ideia entre chip e valor
/// customizado antes de gastar uma chamada de rede, e dá o momento
/// explícito de "começar a valer" que Rhoney pediu.
class _GoalSelector extends StatefulWidget {
  const _GoalSelector({
    required this.tiers,
    required this.currentGoal,
    required this.busy,
    required this.onConfirm,
    required this.totalStepsToday,
    required this.canCollect,
    required this.onCollect,
  });

  final List<int> tiers;
  final int? currentGoal;
  final bool busy;
  final void Function(int steps) onConfirm;
  // Checkpoints de coleta (29/08/2026) — cada card acende quando o
  // total de passos de hoje alcança o próprio valor do card, e passa a
  // coletar (em vez de trocar a meta) ao ser tocado nesse estado.
  final int totalStepsToday;
  final bool canCollect;
  final VoidCallback onCollect;

  @override
  State<_GoalSelector> createState() => _GoalSelectorState();
}

class _GoalSelectorState extends State<_GoalSelector> {
  int? _pendingGoal;
  late final _customController = TextEditingController(text: _isCustomGoal(widget.currentGoal) ? '${widget.currentGoal}' : '');
  // Destaque temporário do botão "Ir" ao confirmar (29/08/2026, pedido
  // de Rhoney: "botão ir deve ficar em destaque ao ser clicado,
  // sinalizando que está ativo") — sem isso, a única confirmação visual
  // de que a meta foi de fato salva era o chip mudar de estado, fácil de
  // não notar.
  bool _justConfirmed = false;
  Timer? _confirmedTimer;

  bool _isCustomGoal(int? goal) => goal != null && !widget.tiers.contains(goal);

  @override
  void didUpdateWidget(covariant _GoalSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Meta customizada confirmada pelo backend (ex.: depois de um
    // _load() após o "Ir") — mantém o valor visível no campo em vez de
    // deixá-lo vazio (29/08/2026, pedido de Rhoney: "ao digitar uma
    // meta ela deve ser adicionada e ficar visível na tela").
    if (widget.currentGoal != oldWidget.currentGoal && _isCustomGoal(widget.currentGoal)) {
      _customController.text = '${widget.currentGoal}';
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    _confirmedTimer?.cancel();
    super.dispose();
  }

  String _chipLabel(AppLocalizations l10n, int steps) {
    switch (steps) {
      case 5000:
        return l10n.movementGoalChipLight;
      case 10000:
        return l10n.movementGoalChipStandard;
      default:
        return l10n.movementGoalChipIntense;
    }
  }

  String _chipSubLabel(AppLocalizations l10n, int steps) {
    switch (steps) {
      case 5000:
        return l10n.movementGoalChipLightLabel;
      case 10000:
        return l10n.movementGoalChipStandardLabel;
      default:
        return l10n.movementGoalChipIntenseLabel;
    }
  }

  void _confirm() {
    final pending = _pendingGoal;
    if (pending == null || pending <= 0) return;
    widget.onConfirm(pending);
    _confirmedTimer?.cancel();
    setState(() {
      _pendingGoal = null;
      _justConfirmed = true;
      // Meta customizada continua visível no campo depois de confirmada
      // — só limpa quando o valor confirmado é um dos chips fixos.
      if (widget.tiers.contains(pending)) _customController.clear();
    });
    _confirmedTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _justConfirmed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasPendingChange = _pendingGoal != null && _pendingGoal != widget.currentGoal;
    final customGoalActive = _pendingGoal == null && _isCustomGoal(widget.currentGoal) && int.tryParse(_customController.text) == widget.currentGoal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold)),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.movementGoalSelectorTitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 13))),
              Text(l10n.movementGoalSelectorSubtitle, style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 9)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final steps in widget.tiers) ...[
                Expanded(
                  child: _GoalChip(
                    label: _chipLabel(l10n, steps),
                    subLabel: _chipSubLabel(l10n, steps),
                    selected: (_pendingGoal ?? widget.currentGoal) == steps,
                    // Checkpoint atingido (29/08/2026, pedido de Rhoney):
                    // acende numa cor chamativa e passa a coletar em vez
                    // de trocar a meta.
                    reached: widget.canCollect && widget.totalStepsToday >= steps,
                    reachedLabel: l10n.movementGoalChipCollectHint,
                    onTap: widget.busy
                        ? null
                        : (widget.canCollect && widget.totalStepsToday >= steps)
                            ? widget.onCollect
                            : () => setState(() {
                                  _pendingGoal = steps;
                                  _customController.clear();
                                }),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              // Último card é editável (29/08/2026, pedido de Rhoney: "o
              // último card deve ser editável, isso resolve o problema
              // do jogador estabelecer sua própria meta") — quem anda,
              // corre ou treina facilmente passa dos tiers fixos acima.
              // Também vira checkpoint de coleta quando a meta ativa é
              // alcançada, igual aos 3 cards fixos.
              Expanded(
                child: _CustomGoalChip(
                  controller: _customController,
                  active: customGoalActive,
                  reached: widget.canCollect &&
                      _isCustomGoal(widget.currentGoal) &&
                      widget.currentGoal != null &&
                      widget.totalStepsToday >= widget.currentGoal!,
                  reachedLabel: l10n.movementGoalChipCollectHint,
                  busy: widget.busy,
                  label: l10n.movementGoalChipCustomLabel,
                  hint: l10n.movementCustomGoalHint,
                  onChanged: (value) => setState(() => _pendingGoal = int.tryParse(value)),
                  onCollect: widget.onCollect,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Botão "Ir" só aparece quando existe de fato uma mudança de
          // meta a confirmar (29/08/2026, achado real de campo — V3/
          // BUG_MOVIMENTO_XP_GRAFICOS.md item 4: com a meta salva já
          // selecionada, o botão ficava cinza/desabilitado, parecendo
          // quebrado). Sem mudança pendente, mostra a meta atual como
          // texto simples no lugar — mesma altura fixa do slot, nunca um
          // botão morto.
          Center(
            child: hasPendingChange || _justConfirmed
                ? FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _justConfirmed ? AppColors.victory : null,
                      minimumSize: const Size(144, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onPressed: widget.busy ? null : _confirm,
                    child: _justConfirmed
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded, size: 18),
                              SizedBox(width: 6),
                              Text('Ativo!', style: TextStyle(fontWeight: FontWeight.w800)),
                            ],
                          )
                        : Text(l10n.movementGoalGoButton, style: const TextStyle(fontWeight: FontWeight.w800)),
                  )
                : SizedBox(
                    height: 40,
                    child: Center(
                      child: Text(
                        l10n.movementCurrentGoalLabel,
                        style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.label, required this.subLabel, required this.selected, required this.reached, required this.reachedLabel, required this.onTap});

  final String label;
  final String subLabel;
  final bool selected;
  // Checkpoint atingido (29/08/2026) — acende numa cor chamativa
  // (victory green) e some sobrepõe o estado "selecionado como meta",
  // já que nesse momento o toque coleta, não muda a meta.
  final bool reached;
  final String reachedLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = reached ? AppColors.victory : (selected ? AppColors.gold : AppColors.bone);
    final bgAlpha = reached ? 0.22 : (selected ? 0.16 : 0.0);
    return Material(
      color: (reached || selected) ? color.withValues(alpha: bgAlpha) : AppColors.bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: reached ? AppColors.victory : (selected ? AppColors.gold : AppColors.muted.withValues(alpha: 0.25)))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppTheme.technicalStyle(color: color, fontSize: 13).copyWith(fontWeight: FontWeight.w700)),
              Text(reached ? reachedLabel : subLabel, style: AppTheme.technicalStyle(color: reached ? AppColors.victory : AppColors.muted, fontSize: 8).copyWith(fontWeight: reached ? FontWeight.w700 : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Último card do seletor de meta — em vez de um tier fixo, é o próprio
/// campo editável (29/08/2026, pedido de Rhoney: "o último card deve
/// ser editável, isso resolve o problema do jogador estabelecer sua
/// própria meta"). Visualmente segue o mesmo container/borda dos outros
/// 3 chips — só o conteúdo troca de Text estático pra um TextField.
class _CustomGoalChip extends StatelessWidget {
  const _CustomGoalChip({
    required this.controller,
    required this.active,
    required this.reached,
    required this.reachedLabel,
    required this.busy,
    required this.label,
    required this.hint,
    required this.onChanged,
    required this.onCollect,
  });

  final TextEditingController controller;
  final bool active;
  // Meta customizada ativa e atingida (29/08/2026) — mesma semântica do
  // checkpoint dos 3 chips fixos: o card acende e o toque passa a
  // coletar em vez de abrir o teclado pra editar.
  final bool reached;
  final String reachedLabel;
  final bool busy;
  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onCollect;

  @override
  Widget build(BuildContext context) {
    final color = reached ? AppColors.victory : (active ? AppColors.gold : AppColors.bone);
    final content = Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: reached ? AppColors.victory.withValues(alpha: 0.22) : (active ? AppColors.gold.withValues(alpha: 0.16) : AppColors.bg),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: reached ? AppColors.victory : (active ? AppColors.gold : AppColors.muted.withValues(alpha: 0.25))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 18,
            child: reached
                ? FittedBox(fit: BoxFit.scaleDown, child: Text(controller.text, style: AppTheme.technicalStyle(color: color, fontSize: 13).copyWith(fontWeight: FontWeight.w700)))
                : TextField(
                    controller: controller,
                    enabled: !busy,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: AppTheme.technicalStyle(color: color, fontSize: 13).copyWith(fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      isDense: true,
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: hint,
                      hintStyle: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 11),
                    ),
                    onChanged: onChanged,
                  ),
          ),
          const SizedBox(height: 2),
          Text(reached ? reachedLabel : label, style: AppTheme.technicalStyle(color: reached ? AppColors.victory : (active ? AppColors.gold : AppColors.muted), fontSize: 8).copyWith(fontWeight: reached ? FontWeight.w700 : FontWeight.w400)),
        ],
      ),
    );
    if (!reached) return content;
    // Atingida: o card inteiro vira botão de coleta — intercepta o
    // toque antes que ele chegue ao TextField (que já não é o widget
    // visível nesse estado, mas evita qualquer foco residual).
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(borderRadius: BorderRadius.circular(12), onTap: busy ? null : onCollect, child: content),
    );
  }
}

/// Card container comum aos dois gráficos — cabeçalho com ponto
/// indicador + título à esquerda, texto pequeno à direita, mesma
/// linguagem visual do resto do redesign (fundo bg2, cantos
/// arredondados) em vez do texto solto direto na tela.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.dotColor, required this.title, required this.trailing, required this.child});

  final Color dotColor;
  final String title;
  final String trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor)),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 13))),
              Flexible(child: Text(trailing, style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 9), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Gráfico semanal (barras) — pedido explícito do redesign (2026-08-26):
/// desempenho de cada um dos últimos dias, destacando visualmente o dia
/// de maior (dourado) e o de menor (tom neutro) volume de passos, pra
/// dar uma visão de desempenho ao longo do tempo, não só o ciclo atual.
/// Animação de entrada (29/08/2026, pedido de Rhoney: gráficos "muito
/// dinâmicos") via swapAnimationDuration nativo do fl_chart.
class _WeeklyStepsBarChart extends StatelessWidget {
  const _WeeklyStepsBarChart({required this.cycles});

  /// Em ordem cronológica (mais antigo primeiro).
  final List<Map<String, dynamic>> cycles;

  static const _weekdayLabels = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

  @override
  Widget build(BuildContext context) {
    final values = cycles.map((c) => c['steps_collected'] as int).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxY = maxValue <= 0 ? 10.0 : maxValue * 1.25;
    final hasVariation = maxValue != minValue;

    return BarChart(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 3,
          getDrawingHorizontalLine: (_) => FlLine(color: AppColors.bg, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.bg,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem('${rod.toY.round()}', AppTheme.technicalStyle(color: AppColors.bone, fontSize: 11)),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= cycles.length) return const SizedBox.shrink();
                final start = DateTime.parse(cycles[index]['cycle_start_at'] as String);
                final isRecordDay = values[index] == maxValue && hasVariation;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _weekdayLabels[start.weekday - 1],
                    style: AppTheme.technicalStyle(color: isRecordDay ? AppColors.gold : AppColors.bone, fontSize: 13).copyWith(fontWeight: FontWeight.w700),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i].toDouble(),
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                  color: !hasVariation
                      ? AppColors.teal
                      : values[i] == maxValue
                          ? AppColors.gold
                          : values[i] == minValue
                              ? AppColors.muted
                              : AppColors.teal,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Converte os snapshots do ciclo (backend) em pontos (hora, passos)
/// pro gráfico de linha e pros cards de pico/vale — compartilhado entre
/// `_OscillationMetricsRow` (topo da tela) e o gráfico intradiário
/// completo (mais abaixo), já que os dois derivam do mesmo dado.
List<(double hour, int steps)> _intradayPoints(List<Map<String, dynamic>> snapshots, DateTime cycleStart) {
  return [
    (0, 0),
    for (final s in snapshots) (DateTime.parse(s['recorded_at'] as String).difference(cycleStart).inMinutes / 60.0, s['steps_total'] as int),
  ];
}

/// Métricas de oscilação diária (U.I/MOVIMENTO_REDESIGN_V1.md §5.2,
/// reposicionadas em 29/08/2026 — pedido de Rhoney: "no lugar dos dois
/// botões abaixo deve aparecer as métricas de oscilações diário do
/// jogador") — pico e vale de passos por hora, no lugar de onde ficavam
/// os botões manuais de coleta. Precisa de pelo menos 2 snapshots pra
/// fazer sentido comparar; com menos, mostra um aviso neutro.
class _OscillationMetricsRow extends StatelessWidget {
  const _OscillationMetricsRow({required this.l10n, required this.sensorUnavailable, required this.snapshots, required this.cycleStart});

  final AppLocalizations l10n;
  final bool sensorUnavailable;
  final List<Map<String, dynamic>> snapshots;
  final DateTime cycleStart;

  @override
  Widget build(BuildContext context) {
    if (snapshots.length < 2) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          sensorUnavailable ? l10n.movementSensorUnavailableMessage : l10n.movementOscillationPendingMessage,
          style: TextStyle(color: AppColors.muted, fontSize: 11),
          maxLines: 1,
        ),
      );
    }
    final points = _intradayPoints(snapshots, cycleStart);
    final peak = points.reduce((a, b) => a.$2 >= b.$2 ? a : b);
    final valley = points.reduce((a, b) => a.$2 <= b.$2 ? a : b);
    return Row(
      children: [
        Expanded(child: _PeakValleyCard(icon: '🔥', label: l10n.movementPeakLabel, hour: peak.$1, steps: peak.$2, color: AppColors.gold)),
        const SizedBox(width: 6),
        Expanded(child: _PeakValleyCard(icon: '💤', label: l10n.movementValleyLabel, hour: valley.$1, steps: valley.$2, color: AppColors.muted)),
      ],
    );
  }
}

class _PeakValleyCard extends StatelessWidget {
  const _PeakValleyCard({required this.icon, required this.label, required this.hour, required this.steps, required this.color});

  final String icon;
  final String label;
  final double hour;
  final int steps;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final h = hour.floor();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$icon ${h}h · $label', style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 9)),
            Text('$steps', style: AppTheme.technicalStyle(color: color, fontSize: 15).copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _IntradayStepsLineChart extends StatelessWidget {
  const _IntradayStepsLineChart({required this.points});

  final List<(double hour, int steps)> points;

  @override
  Widget build(BuildContext context) {
    final spots = [for (final p in points) FlSpot(p.$1, p.$2.toDouble())];
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final chartMaxY = maxY <= 0 ? 10.0 : maxY * 1.2;

    return LineChart(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      LineChartData(
        minX: 0,
        maxX: 24,
        minY: 0,
        maxY: chartMaxY,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.bg,
            getTooltipItems: (spots) => [
              for (final s in spots) LineTooltipItem('${s.y.round()}', AppTheme.technicalStyle(color: AppColors.bone, fontSize: 11)),
            ],
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: chartMaxY / 3,
          getDrawingHorizontalLine: (_) => FlLine(color: AppColors.bg, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 6,
              reservedSize: 20,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${value.toInt()}h',
                  style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 10),
                ),
              ),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: AppColors.gold,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(radius: 3.5, color: AppColors.gold, strokeWidth: 0),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.gold.withValues(alpha: 0.2), AppColors.gold.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
