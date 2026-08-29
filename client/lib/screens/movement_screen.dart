import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/feedback_service.dart';
import '../services/movement_service.dart';
import '../theme/app_theme.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/pulse_in.dart';
import '../widgets/share_achievement_button.dart';

/// V2 item 9 — Contador de passos (STEP_COUNTER_MOVIMENTO.md). O backend
/// é sempre a autoridade sobre o estado do ciclo e o XP convertido —
/// esta tela só lê o sensor local para saber QUANTOS passos ainda não
/// foram enviados, nunca decide o bônus sozinha.
///
/// Redesign (U.I/MOVIMENTO_REDESIGN_V1.md, 29/08/2026): hierarquia fraca
/// e paleta apagada da versão anterior substituídas por um bloco Hero
/// compacto (anel + estatísticas lado a lado), regra de conversão
/// "100 passos = +2 XP" sempre visível, e seletor de meta diária em
/// chips (5k/10k/15k/20k) — GET/PUT /movement/goal já existiam no
/// backend, esta versão só troca o diálogo de texto livre por uma
/// escolha guiada. Meta continua sendo aceita como qualquer valor
/// (compat com quem já tinha uma meta fora dessas 4 faixas).
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

  late final CelebrationController _celebration;

  static const _goalTiers = [5000, 10000, 15000, 20000];

  @override
  void initState() {
    super.initState();
    _celebration = CelebrationController();
    _load();
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    _celebration.dispose();
    super.dispose();
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
      } else {
        _stepSub?.cancel();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    // Chip de streak no header (U.I/MOVIMENTO_REDESIGN_V1.md §3) — reforço
    // visual, nunca bloqueia a tela se falhar (mesmo princípio já usado
    // pros outros indicadores secundários da Home).
    try {
      final progress = await widget.client.progress();
      if (mounted) setState(() => _streakDays = progress['streak']['current_streak'] as int);
    } on ApiException catch (_) {}
  }

  void _listenToSensor(String cycleId) {
    _stepSub?.cancel();
    _stepSub = MovementService.instance.stepCountStream().listen(
      (steps) async {
        _lastRawStepsSinceBoot = steps;
        final delta = await MovementService.instance.pendingDeltaFor(cycleId, steps);
        if (mounted) {
          setState(() {
            _sensorUnavailable = false;
            _detectedUncollectedSteps = delta.uncollectedSteps;
          });
        }
      },
      onError: (_) {
        if (mounted) setState(() => _sensorUnavailable = true);
      },
    );
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

  Future<void> _collectCurrent() async {
    final cycle = _currentCycle;
    if (cycle == null || _detectedUncollectedSteps <= 0) return;
    setState(() => _busy = true);
    try {
      final localDelta = _detectedUncollectedSteps;
      final result = await widget.client.collectMovementSteps(steps: localDelta);
      final updatedCycle = result['cycle'] as Map<String, dynamic>;
      await _handleCollectResponse(result, cycle['id'] as String, updatedCycle['steps_collected'] as int);
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _collectPending() async {
    final pending = _pendingReportCycle;
    if (pending == null) return;
    setState(() => _busy = true);
    try {
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
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
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
                    const Icon(Icons.local_fire_department_rounded, color: AppColors.gold, size: 16),
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
            padding: const EdgeInsets.all(16),
            child: _loading ? const Center(child: CircularProgressIndicator()) : _buildBody(l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
          ],
          if (!_movementEnabled) ...[
            Text(l10n.movementIntro, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _enable,
              child: Text(l10n.movementEnableButton),
            ),
          ] else ...[
            if (_pendingReportCycle != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.gold.withValues(alpha: 0.35))),
                child: Row(
                  children: [
                    Expanded(
                      child: PulseIn(
                        intensity: 0.3,
                        child: Text(
                          l10n.movementPendingReportLabel(_pendingReportCycle!['steps_collected'] as int),
                          style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 12)),
                      onPressed: _busy ? null : _collectPending,
                      child: Text(l10n.movementCollectPreviousButton, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_currentCycle != null) ...[
              _HeroBlock(
                stepsCollected: _currentCycle!['steps_collected'] as int,
                xpAwarded: _currentCycle!['xp_awarded'] as int,
                goal: _dailyGoalSteps,
              ),
              const SizedBox(height: 16),
              _GoalSelector(
                l10n: l10n,
                tiers: _goalTiers,
                currentGoal: _dailyGoalSteps,
                onSelect: _busy ? null : _setGoal,
              ),
              if (_goalReachedMessage != null) ...[
                const SizedBox(height: 12),
                PulseIn(
                  intensity: 0.3,
                  child: Text(
                    _goalReachedMessage!,
                    style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                ShareAchievementButton(message: l10n.shareMovementGoalMessage, client: widget.client),
              ],
              if (_checkpointReachedMessage != null) ...[
                const SizedBox(height: 8),
                PulseIn(
                  intensity: 0.3,
                  child: Text(
                    _checkpointReachedMessage!,
                    style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_sensorUnavailable)
                    Text(l10n.movementSensorUnavailableMessage, style: const TextStyle(color: AppColors.muted, fontSize: 12))
                  else
                    Text(l10n.movementDetectedStepsLabel(_detectedUncollectedSteps), style: const TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: (_busy || _detectedUncollectedSteps <= 0) ? null : _collectCurrent,
                child: Text(
                  _detectedUncollectedSteps > 0 ? l10n.movementCollectButton : l10n.movementNoStepsToCollect,
                ),
              ),
              // Gráfico intradiário (linha) — oscilação de passos ao
              // LONGO do dia em curso, usando os checkpoints/coletas já
              // registrados. Precisa de pelo menos 2 pontos pra formar
              // uma curva com sentido; com 0-1 coleta ainda não há
              // "oscilação" nenhuma pra mostrar.
              if (((_currentCycle!['snapshots'] as List?)?.length ?? 0) >= 2) ...[
                const SizedBox(height: 24),
                _ChartCard(
                  dotColor: AppColors.gold,
                  title: l10n.movementTodayChartTitle,
                  trailing: l10n.movementTodayChartSubtitle,
                  child: _IntradayStepsSection(
                    l10n: l10n,
                    snapshots: (_currentCycle!['snapshots'] as List).cast<Map<String, dynamic>>(),
                    cycleStart: DateTime.parse(_currentCycle!['cycle_start_at'] as String),
                  ),
                ),
              ],
            ],
            // Gráfico semanal (barras) — desempenho de cada um dos
            // últimos 7 dias, com o dia recorde e o mais fraco
            // destacados. Precisa de pelo menos 2 ciclos pra fazer
            // sentido comparar.
            if (_recentCycles.length >= 2) ...[
              const SizedBox(height: 16),
              _ChartCard(
                dotColor: AppColors.teal,
                title: l10n.movementWeeklyChartTitle,
                trailing: l10n.movementWeeklyChartSubtitle,
                child: _WeeklyStepsBarChart(cycles: _recentCycles),
              ),
            ],
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _busy ? null : _disable,
                child: Text(l10n.movementDisableButton),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bloco Hero (U.I/MOVIMENTO_REDESIGN_V1.md §4) — anel de progresso +
/// estatísticas lado a lado num único card compacto, substituindo o
/// donut grande isolado + textos empilhados da versão anterior. A regra
/// de conversão "100 passos = +2 XP" fica sempre visível aqui, nunca
/// implícita.
class _HeroBlock extends StatelessWidget {
  const _HeroBlock({required this.stepsCollected, required this.xpAwarded, required this.goal});

  final int stepsCollected;
  final int xpAwarded;
  final int? goal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.bg2, Color.lerp(AppColors.bg2, AppColors.gold, 0.08)!]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ProgressRing(stepsCollected: stepsCollected, goal: goal),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatLine(color: AppColors.gold, value: '$stepsCollected', label: l10n.movementStepsTodayLabel),
                const SizedBox(height: 8),
                _StatLine(color: AppColors.teal, value: '$xpAwarded', label: l10n.movementXpTodayLabel),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 11),
                    children: const [
                      TextSpan(text: 'A cada '),
                      TextSpan(text: '100 passos', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
                      TextSpan(text: ' = '),
                      TextSpan(text: '+2 XP', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
                    ],
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

class _StatLine extends StatelessWidget {
  const _StatLine({required this.color, required this.value, required this.label});

  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value, style: AppTheme.technicalStyle(color: color, fontSize: 20).copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(width: 6),
        Text(label, style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 12)),
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
            SizedBox(
              width: 78,
              height: 78,
              child: PieChart(
                PieChartData(
                  startDegreeOffset: -90,
                  sectionsSpace: 0,
                  centerSpaceRadius: 30,
                  sections: [
                    PieChartSectionData(value: progress > 0 ? progress : 0.001, color: ringColor, showTitle: false, radius: 9),
                    PieChartSectionData(value: 1 - progress, color: Colors.transparent, showTitle: false, radius: 9),
                  ],
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
        child: const SizedBox(width: 5, height: 5, child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.teal))),
      ),
    );
  }
}

/// Seletor de meta diária em chips (U.I/MOVIMENTO_REDESIGN_V1.md §6) —
/// substitui o diálogo de texto livre anterior por uma escolha guiada
/// entre 4 faixas. Uma meta fora dessas faixas (definida antes desta
/// versão existir) continua funcionando normalmente — só não fica
/// destacada em nenhum chip até o usuário escolher uma das 4.
class _GoalSelector extends StatelessWidget {
  const _GoalSelector({required this.l10n, required this.tiers, required this.currentGoal, required this.onSelect});

  final AppLocalizations l10n;
  final List<int> tiers;
  final int? currentGoal;
  final void Function(int steps)? onSelect;

  String _chipLabel(int steps) {
    switch (steps) {
      case 5000:
        return l10n.movementGoalChipLight;
      case 10000:
        return l10n.movementGoalChipStandard;
      case 15000:
        return l10n.movementGoalChipIntense;
      default:
        return l10n.movementGoalChipElite;
    }
  }

  String _chipSubLabel(int steps) {
    switch (steps) {
      case 5000:
        return l10n.movementGoalChipLightLabel;
      case 10000:
        return l10n.movementGoalChipStandardLabel;
      case 15000:
        return l10n.movementGoalChipIntenseLabel;
      default:
        return l10n.movementGoalChipEliteLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold)),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.movementGoalSelectorTitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
              Text(l10n.movementGoalSelectorSubtitle, style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final steps in tiers) ...[
                Expanded(child: _GoalChip(label: _chipLabel(steps), subLabel: _chipSubLabel(steps), selected: currentGoal == steps, onTap: onSelect == null ? null : () => onSelect!(steps))),
                if (steps != tiers.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.label, required this.subLabel, required this.selected, required this.onTap});

  final String label;
  final String subLabel;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.gold.withValues(alpha: 0.16) : AppColors.bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? AppColors.gold : AppColors.muted.withValues(alpha: 0.25))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppTheme.technicalStyle(color: selected ? AppColors.gold : AppColors.bone, fontSize: 14).copyWith(fontWeight: FontWeight.w700)),
              Text(subLabel, style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 9)),
            ],
          ),
        ),
      ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor)),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
              Flexible(child: Text(trailing, style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 10), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Gráfico semanal (barras) — pedido explícito do redesign (2026-08-26):
/// desempenho de cada um dos últimos dias, destacando visualmente o dia
/// de maior (dourado) e o de menor (tom neutro) volume de passos, pra
/// dar uma visão de desempenho ao longo do tempo, não só o ciclo atual.
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

    return SizedBox(
      height: 150,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: const BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= cycles.length) return const SizedBox.shrink();
                  final start = DateTime.parse(cycles[index]['cycle_start_at'] as String);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _weekdayLabels[start.weekday - 1],
                      style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 10),
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
      ),
    );
  }
}

/// Gráfico do dia (linha) + mini-cards de pico/vale ao lado
/// (U.I/MOVIMENTO_REDESIGN_V1.md §5.2) — oscilação de passos ao LONGO do
/// ciclo em curso, um ponto por coleta (MovementSnapshot, backend).
class _IntradayStepsSection extends StatelessWidget {
  const _IntradayStepsSection({required this.l10n, required this.snapshots, required this.cycleStart});

  final AppLocalizations l10n;
  final List<Map<String, dynamic>> snapshots;
  final DateTime cycleStart;

  @override
  Widget build(BuildContext context) {
    final points = <(double hour, int steps)>[
      (0, 0),
      for (final s in snapshots)
        (DateTime.parse(s['recorded_at'] as String).difference(cycleStart).inMinutes / 60.0, s['steps_total'] as int),
    ];
    final peak = points.reduce((a, b) => a.$2 >= b.$2 ? a : b);
    final valley = points.reduce((a, b) => a.$2 <= b.$2 ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _IntradayStepsLineChart(points: points)),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _PeakValleyCard(icon: '🔥', label: l10n.movementPeakLabel, hour: peak.$1, steps: peak.$2, color: AppColors.gold),
              const SizedBox(height: 8),
              _PeakValleyCard(icon: '💤', label: l10n.movementValleyLabel, hour: valley.$1, steps: valley.$2, color: AppColors.muted),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$icon ${h}h · $label', style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 9)),
          Text('$steps', style: AppTheme.technicalStyle(color: color, fontSize: 15).copyWith(fontWeight: FontWeight.w700)),
        ],
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

    return SizedBox(
      height: 150,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 24,
          minY: 0,
          maxY: chartMaxY,
          lineTouchData: const LineTouchData(enabled: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: chartMaxY / 3,
            getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.bg, strokeWidth: 1),
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
                reservedSize: 24,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(top: 6),
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
      ),
    );
  }
}
