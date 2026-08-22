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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.movementIntro, style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 14)),
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
            if (_dailyGoalSteps != null) ...[
              Center(
                child: _MovementGoalDonut(
                  stepsCollected: _currentCycle!['steps_collected'] as int,
                  goal: _dailyGoalSteps!,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              l10n.movementCurrentCycleLabel(_currentCycle!['steps_collected'] as int),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _dailyGoalSteps != null
                  ? l10n.movementGoalLabel(_dailyGoalSteps!)
                  : l10n.movementNoGoalLabel,
              style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 13),
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
              ShareAchievementButton(message: l10n.shareMovementGoalMessage),
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
          ],
          const SizedBox(height: 24),
          TextButton(
            onPressed: _busy ? null : _disable,
            child: Text(l10n.movementDisableButton),
          ),
        ],
      ],
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
class _MovementGoalDonut extends StatelessWidget {
  const _MovementGoalDonut({required this.stepsCollected, required this.goal});

  final int stepsCollected;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = goal <= 0 ? 0.0 : (stepsCollected / goal).clamp(0.0, 1.0);
    final goalReached = stepsCollected >= goal;
    final percent = (progress * 100).round();

    return SizedBox(
      height: 140,
      width: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 0,
              centerSpaceRadius: 48,
              sections: [
                PieChartSectionData(
                  value: progress > 0 ? progress : 0.001,
                  color: goalReached ? AppColors.gold : AppColors.teal,
                  showTitle: false,
                  radius: 18,
                ),
                PieChartSectionData(
                  value: 1 - progress,
                  color: AppColors.bg2,
                  showTitle: false,
                  radius: 18,
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
                    l10n.movementGoalProgressLabel(percent),
                    style: AppTheme.technicalStyle(
                      color: goalReached ? AppColors.gold : AppColors.teal,
                      fontSize: 16,
                    ),
                  ),
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
