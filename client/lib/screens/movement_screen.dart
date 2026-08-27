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

  Future<void> _showGoalDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: _dailyGoalSteps != null ? '$_dailyGoalSteps' : '',
    );
    final result = await showDialog<int?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.movementGoalDialogTitle),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: l10n.movementGoalDialogHint),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.movementGoalCancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(int.tryParse(controller.text)),
            child: Text(l10n.movementGoalSaveButton),
          ),
        ],
      ),
    );
    if (result == null || result <= 0) return;
    setState(() => _busy = true);
    try {
      await widget.client.setMovementGoal(result);
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
      appBar: AppBar(title: Text(l10n.movementScreenTitle)),
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
          // DESIGN_SYSTEM.md §2: título da tela já vem do AppBar
          // (Fraunces, padrão do resto do app) — aqui só o texto de
          // apoio, em Inter. Achado real do redesign (2026-08-26): antes
          // usava JetBrains Mono, reservado a metadado técnico
          // (DESIGN_SYSTEM.md §2), não a texto corrido.
          Text(l10n.movementIntro, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
          ],
          if (!_movementEnabled)
            FilledButton(
              onPressed: _busy ? null : _enable,
              child: Text(l10n.movementEnableButton),
            )
          else ...[
            if (_pendingReportCycle != null) ...[
              PulseIn(
                intensity: 0.3,
                child: Text(
                  l10n.movementPendingReportLabel(_pendingReportCycle!['steps_collected'] as int),
                  style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _busy ? null : _collectPending,
                child: Text(l10n.movementCollectPreviousButton),
              ),
              const SizedBox(height: 24),
            ],
            if (_currentCycle != null) ...[
              Center(
                child: _MovementGoalDonut(
                  stepsCollected: _currentCycle!['steps_collected'] as int,
                  goal: _dailyGoalSteps,
                ),
              ),
              const SizedBox(height: 16),
              // Número de destaque — JetBrains Mono grande, reservado
              // pra metadado técnico (DESIGN_SYSTEM.md §2), aqui o valor
              // mais importante da tela.
              Text(
                l10n.movementCurrentCycleLabel(_currentCycle!['steps_collected'] as int),
                style: AppTheme.technicalStyle(color: AppColors.bone, fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _dailyGoalSteps != null ? l10n.movementGoalLabel(_dailyGoalSteps!) : l10n.movementNoGoalLabel,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: _busy ? null : _showGoalDialog,
                  child: Text(_dailyGoalSteps != null ? l10n.movementEditGoalButton : l10n.movementSetGoalButton),
                ),
              ),
              if (_goalReachedMessage != null) ...[
                const SizedBox(height: 8),
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
              const SizedBox(height: 8),
              if (_sensorUnavailable)
                Text(l10n.movementSensorUnavailableMessage, style: const TextStyle(color: AppColors.muted))
              else
                Text(l10n.movementDetectedStepsLabel(_detectedUncollectedSteps)),
              const SizedBox(height: 16),
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
                const SizedBox(height: 32),
                Text(l10n.movementTodayChartTitle, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(l10n.movementTodayChartSubtitle, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                _IntradayStepsLineChart(
                  snapshots: (_currentCycle!['snapshots'] as List).cast<Map<String, dynamic>>(),
                  cycleStart: DateTime.parse(_currentCycle!['cycle_start_at'] as String),
                ),
              ],
            ],
            // Gráfico semanal (barras) — desempenho de cada um dos
            // últimos 7 dias, com o dia recorde e o mais fraco
            // destacados. Precisa de pelo menos 2 ciclos pra fazer
            // sentido comparar.
            if (_recentCycles.length >= 2) ...[
              const SizedBox(height: 32),
              Text(l10n.movementWeeklyChartTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(l10n.movementWeeklyChartSubtitle, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              _WeeklyStepsBarChart(cycles: _recentCycles),
            ],
            const SizedBox(height: 24),
            TextButton(
              onPressed: _busy ? null : _disable,
              child: Text(l10n.movementDisableButton),
            ),
          ],
        ],
      ),
    );
  }
}

/// Progresso em relação à meta diária (pedido de Rhoney, 2026-08-21:
/// "sempre que possível use gráficos de fácil compreensão e dinâmico
/// pra ilustrar os feitos do usuário"). Donut é a escolha certa aqui —
/// é literalmente uma proporção de um todo (passos coletados / meta),
/// mesmo raciocínio já aplicado nos gráficos de Estatísticas. Ao
/// ultrapassar a meta, o anel fecha 100% em dourado — reforço visual do
/// bônus extra, sem precisar de um segundo gráfico.
///
/// Redesign 2026-08-26: `goal` agora é opcional — sem meta definida, o
/// anel continua visível (contorno decorativo neutro + total de passos
/// no centro) em vez de simplesmente sumir da tela, e mesmo com meta
/// definida um contorno fino sempre marca a borda do anel (achado real:
/// em 0%, o preenchimento quase invisível em cima do fundo escuro dava
/// a impressão de um componente quebrado/incompleto).
class _MovementGoalDonut extends StatelessWidget {
  const _MovementGoalDonut({required this.stepsCollected, required this.goal});

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
      height: 148,
      width: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Contorno sempre visível, mesmo em 0%/sem meta — sem isso o
          // anel "some" contra o fundo escuro quando o preenchimento
          // real é quase nulo.
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.bg2, width: 14),
            ),
          ),
          if (hasGoal)
            PieChart(
              PieChartData(
                startDegreeOffset: -90,
                sectionsSpace: 0,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(
                    value: progress > 0 ? progress : 0.001,
                    color: ringColor,
                    showTitle: false,
                    radius: 14,
                  ),
                  PieChartSectionData(
                    value: 1 - progress,
                    color: Colors.transparent,
                    showTitle: false,
                    radius: 14,
                  ),
                ],
              ),
            ),
          // Largura fixa (não só Padding) é necessária para o FittedBox
          // ter uma caixa concreta pra encolher o texto — dentro de um
          // Stack, um Column sem largura explícita cresce livremente e
          // o "100% da meta" ficava cortado nas bordas do círculo
          // (achado real em teste no dispositivo, 2026-08-21).
          SizedBox(
            width: 96,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    hasGoal ? l10n.movementGoalProgressLabel(percent) : '$stepsCollected',
                    style: AppTheme.technicalStyle(color: ringColor, fontSize: hasGoal ? 16 : 22),
                  ),
                ),
                if (!hasGoal)
                  Text(
                    l10n.movementNoGoalProgressLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (goalReached) const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 18),
              ],
            ),
          ),
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
      height: 170,
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
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= cycles.length) return const SizedBox.shrink();
                  final start = DateTime.parse(cycles[index]['cycle_start_at'] as String);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _weekdayLabels[start.weekday - 1],
                      style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 11),
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
                    width: 20,
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

/// Gráfico do dia atual (linha) — pedido explícito do redesign
/// (2026-08-26): oscilação de passos ao LONGO do ciclo em curso, um
/// ponto por coleta (MovementSnapshot, backend), plotado como fração de
/// hora desde o início do ciclo. Sempre começa em (0h, 0 passos) —
/// nenhum passo é possível antes do próprio início do ciclo.
class _IntradayStepsLineChart extends StatelessWidget {
  const _IntradayStepsLineChart({required this.snapshots, required this.cycleStart});

  final List<Map<String, dynamic>> snapshots;
  final DateTime cycleStart;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      const FlSpot(0, 0),
      for (final s in snapshots)
        FlSpot(
          DateTime.parse(s['recorded_at'] as String).difference(cycleStart).inMinutes / 60.0,
          (s['steps_total'] as int).toDouble(),
        ),
    ];
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final chartMaxY = maxY <= 0 ? 10.0 : maxY * 1.2;

    return SizedBox(
      height: 170,
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
            getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.bg2, strokeWidth: 1),
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
                reservedSize: 28,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${value.toInt()}h',
                    style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 11),
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
              color: AppColors.teal,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(radius: 3.5, color: AppColors.gold, strokeWidth: 0),
              ),
              belowBarData: BarAreaData(show: true, color: AppColors.teal.withValues(alpha: 0.12)),
            ),
          ],
        ),
      ),
    );
  }
}
