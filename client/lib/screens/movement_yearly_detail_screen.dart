import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import 'movement_screen.dart';

/// MENTAL_MOVIMENTO_REFORMULACAO.md §13 — detalhamento anual (aberto a
/// partir do card "Ano ›" na tela principal). O gráfico anual completo
/// nunca fica na tela principal — mora só aqui.
class MovementYearlyDetailScreen extends StatefulWidget {
  const MovementYearlyDetailScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<MovementYearlyDetailScreen> createState() => _MovementYearlyDetailScreenState();
}

class _MovementYearlyDetailScreenState extends State<MovementYearlyDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await widget.client.getMovementYearlySummary();
      if (mounted) setState(() => _summary = summary);
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
      appBar: AppBar(title: Text(l10n.movementYearlyDetailTitle)),
      // Pedido de Rhoney (04/09/2026): pull-to-refresh em qualquer tela
      // do app. Mesmo achado de movement_daily_detail_screen.dart —
      // SliverFillRemaining quebra com "LayoutBuilder does not support
      // returning intrinsic dimensions" (o gráfico usa LayoutBuilder
      // internamente, fl_chart). LayoutBuilder aqui fora + SizedBox de
      // altura exata dá ao Column altura delimitada (Expanded funciona)
      // sem nenhum cálculo de dimensão intrínseca.
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.gold,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Text(_error!, style: TextStyle(color: AppColors.error)))
                          : _buildBody(l10n),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    final summary = _summary!;
    final months = (summary['months'] as List).cast<Map<String, dynamic>>();
    if (months.isEmpty) {
      return Center(child: Text(l10n.movementYearlyEmptyMessage, style: TextStyle(color: AppColors.muted), textAlign: TextAlign.center));
    }
    final totalSteps = summary['total_steps'] as int;
    final activeDays = summary['active_days'] as int;
    final average = summary['average_steps_per_active_day'] as int;
    final bestMonth = summary['best_month'] as int?;
    final totalXp = summary['total_xp_awarded'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _YearStatBlock(label: l10n.movementYearlyTotalStepsLabel, value: '$totalSteps', color: AppColors.gold)),
            const SizedBox(width: 8),
            Expanded(child: _YearStatBlock(label: l10n.movementYearlyActiveDaysLabel, value: '$activeDays', color: AppColors.teal)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _YearStatBlock(label: l10n.movementYearlyAverageLabel, value: '$average', color: AppColors.bone)),
            const SizedBox(width: 8),
            Expanded(
              child: _YearStatBlock(
                label: l10n.movementYearlyBestMonthLabel,
                value: bestMonth != null ? _monthLabels[bestMonth - 1] : '—',
                color: AppColors.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _YearStatBlock(label: l10n.movementYearlyXpLabel, value: '$totalXp', color: AppColors.teal, wide: true),
        const SizedBox(height: 12),
        Expanded(
          child: ChartCard(
            dotColor: AppColors.gold,
            title: l10n.movementYearCardTitle,
            trailing: l10n.movementYearCardSubtitle(summary['year'] as int),
            child: _MonthlyStepsBarChart(months: months),
          ),
        ),
      ],
    );
  }
}

const _monthLabels = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];

class _YearStatBlock extends StatelessWidget {
  const _YearStatBlock({required this.label, required this.value, required this.color, this.wide = false});

  final String label;
  final String value;
  final Color color;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: AppTheme.technicalStyle(color: color, fontSize: 18).copyWith(fontWeight: FontWeight.w800))),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 10)),
        ],
      ),
    );
  }
}

/// Barras por mês (jan-dez) — meses sem nenhum ciclo aparecem como 0,
/// mesma linguagem visual do gráfico semanal (dourado = melhor mês).
class _MonthlyStepsBarChart extends StatelessWidget {
  const _MonthlyStepsBarChart({required this.months});

  final List<Map<String, dynamic>> months;

  @override
  Widget build(BuildContext context) {
    final totalsByMonth = <int, int>{for (final m in months) m['month'] as int: m['total_steps'] as int};
    final values = [for (var m = 1; m <= 12; m++) totalsByMonth[m] ?? 0];
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final maxY = maxValue <= 0 ? 10.0 : maxValue * 1.25;

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
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= 12) return const SizedBox.shrink();
                final isBest = values[index] == maxValue && maxValue > 0;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _monthLabels[index],
                    style: AppTheme.technicalStyle(color: isBest ? AppColors.gold : AppColors.bone, fontSize: 10).copyWith(fontWeight: isBest ? FontWeight.w700 : FontWeight.w400),
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
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                  color: values[i] == maxValue && maxValue > 0 ? AppColors.gold : AppColors.teal,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
