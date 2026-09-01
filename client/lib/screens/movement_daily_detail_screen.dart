import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import 'movement_screen.dart';

/// MENTAL_MOVIMENTO_REFORMULACAO.md §11 — detalhamento de um dia
/// (aberto a partir do card "Hoje ›" na tela principal, ou tocando um
/// dia na tela "Semana"). O gráfico intradiário e os cards de pico/vale
/// não ficam mais na tela principal — moram só aqui.
///
/// Recebe `initialCycle` já pronto (com snapshots) quando disponível
/// (o dia de hoje, já carregado pela tela principal — evita uma
/// chamada de rede redundante); caso contrário busca via
/// GET /movement/cycles/{id} (dias passados, abertos pela tela Semana).
class MovementDailyDetailScreen extends StatefulWidget {
  const MovementDailyDetailScreen({
    super.key,
    required this.client,
    required this.cycleId,
    this.initialCycle,
    this.goal,
    this.liveExtraSteps = 0,
  });

  final ApiClient client;
  final String cycleId;
  final Map<String, dynamic>? initialCycle;
  // Meta ativa do jogador — só faz sentido mostrar pro dia de hoje
  // (dias passados não guardam qual era a meta vigente naquele momento).
  final int? goal;
  // Passos já detectados localmente mas ainda não coletados no servidor
  // (só relevante pro dia de hoje, igual ao Hero da tela principal).
  final int liveExtraSteps;

  @override
  State<MovementDailyDetailScreen> createState() => _MovementDailyDetailScreenState();
}

class _MovementDailyDetailScreenState extends State<MovementDailyDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _cycle;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.initialCycle != null) {
      setState(() {
        _cycle = widget.initialCycle;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cycle = await widget.client.getMovementCycle(widget.cycleId);
      if (mounted) setState(() => _cycle = cycle);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.movementDailyDetailTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!, style: TextStyle(color: AppColors.error)))
                  : _buildBody(l10n),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    final cycle = _cycle!;
    final snapshots = (cycle['snapshots'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final cycleStart = DateTime.parse(cycle['cycle_start_at'] as String);
    final steps = (cycle['steps_collected'] as int) + widget.liveExtraSteps;
    final xp = cycle['xp_awarded'] as int;
    final goal = widget.goal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _StatBlock(label: l10n.movementDailyDetailStepsLabel, value: '$steps', color: AppColors.gold)),
            const SizedBox(width: 8),
            Expanded(child: _StatBlock(label: l10n.movementDailyDetailXpLabel, value: '$xp', color: AppColors.teal)),
            if (goal != null && goal > 0) ...[
              const SizedBox(width: 8),
              Expanded(child: _StatBlock(label: l10n.movementDailyDetailGoalLabel, value: '$goal', color: AppColors.bone)),
            ],
          ],
        ),
        const SizedBox(height: 12),
        OscillationMetricsRow(
          l10n: l10n,
          sensorUnavailable: false,
          snapshots: snapshots,
          cycleStart: cycleStart,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ChartCard(
            dotColor: AppColors.gold,
            title: l10n.movementTodayChartTitle,
            trailing: l10n.movementTodayChartSubtitle,
            child: IntradayStepsLineChart(points: intradayPoints(snapshots, cycleStart)),
          ),
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: AppTheme.technicalStyle(color: color, fontSize: 20).copyWith(fontWeight: FontWeight.w800))),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 10)),
        ],
      ),
    );
  }
}
