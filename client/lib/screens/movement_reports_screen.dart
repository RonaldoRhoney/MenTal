import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import 'movement_screen.dart' show ChartCard;

/// MOVIMENTO_GRAFICOS_RICOS_V1.md — substitui as 3 telas de detalhe
/// separadas (Hoje/Semana/Ano) por UMA tela só com abas fixas
/// Dia/Semana/Mês/Ano (protótipo: movimento_rico.html, seguido à risca
/// a pedido de Rhoney). Trocar de aba atualiza tanto o card de total
/// quanto o gráfico, sem sair da tela. Histórico completo (§7) fica
/// sempre visível abaixo, independente da aba selecionada.
enum MovementReportPeriod { day, week, month, year }

/// Estado do histórico de UM período — paginação independente por aba
/// (§7, revisado 05/09/2026: "dia, semana, mês e ano devem ter seus
/// históricos fiéis"), nunca uma lista única reaproveitada entre abas.
class _HistoryState {
  final List<Map<String, dynamic>> items = [];
  String? cursor;
  bool loadingMore = false;
  bool hasMore = true;
}

class MovementReportsScreen extends StatefulWidget {
  const MovementReportsScreen({super.key, required this.client, this.initialPeriod = MovementReportPeriod.day});

  final ApiClient client;
  final MovementReportPeriod initialPeriod;

  @override
  State<MovementReportsScreen> createState() => _MovementReportsScreenState();
}

class _MovementReportsScreenState extends State<MovementReportsScreen> {
  late MovementReportPeriod _period = widget.initialPeriod;
  bool _loading = true;
  String? _error;
  int _streakDays = 0;
  int? _dailyGoalSteps;

  // Dia
  Map<String, dynamic>? _currentCycle;
  List<Map<String, dynamic>> _daySessions = [];

  // Semana
  List<Map<String, dynamic>> _weekCycles = [];

  // Mês
  Map<String, dynamic>? _monthData;

  // Ano
  Map<String, dynamic>? _yearData;

  // Histórico (§7, revisado 05/09/2026 — "dia, semana, mês e ano devem
  // ter seus históricos fiéis"): cada aba tem seu PRÓPRIO histórico,
  // agrupado na granularidade correspondente — nunca a mesma lista
  // diária reaproveitada embaixo de todas as abas.
  final Map<MovementReportPeriod, _HistoryState> _historyByPeriod = {
    for (final p in MovementReportPeriod.values) p: _HistoryState(),
  };

  static const _periodApiValue = {
    MovementReportPeriod.day: 'day',
    MovementReportPeriod.week: 'week',
    MovementReportPeriod.month: 'month',
    MovementReportPeriod.year: 'year',
  };

  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  Future<void> _loadEverything() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Future.wait([
        _loadStreakAndGoal(),
        _loadDay(),
        _loadWeek(),
        _loadMonth(),
        _loadYear(),
        for (final period in MovementReportPeriod.values) _loadHistoryFirstPage(period),
      ]);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadStreakAndGoal() async {
    final status = await widget.client.movementStatus();
    _dailyGoalSteps = status['daily_goal_steps'] as int?;
    final progress = await widget.client.progress();
    _streakDays = progress['streak']['current_streak'] as int;
  }

  Future<void> _loadDay() async {
    final status = await widget.client.movementStatus();
    _currentCycle = status['current_cycle'] as Map<String, dynamic>?;
    final chart = await widget.client.getMovementDailyChart();
    _daySessions = (chart['sessions'] as List).cast<Map<String, dynamic>>();
  }

  Future<void> _loadWeek() async {
    final status = await widget.client.movementStatus();
    _weekCycles = ((status['recent_cycles'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .reversed
        .toList();
  }

  Future<void> _loadMonth() async {
    _monthData = await widget.client.getMovementMonthlyChart();
  }

  Future<void> _loadYear() async {
    _yearData = await widget.client.getMovementYearlySummary();
  }

  Future<void> _loadHistoryFirstPage(MovementReportPeriod period) async {
    final page = await widget.client.getMovementHistory(period: _periodApiValue[period]!);
    final state = _historyByPeriod[period]!;
    state.items
      ..clear()
      ..addAll((page['items'] as List).cast<Map<String, dynamic>>());
    state.cursor = page['next_cursor'] as String?;
    state.hasMore = state.cursor != null;
  }

  Future<void> _loadMoreHistory(MovementReportPeriod period) async {
    final state = _historyByPeriod[period]!;
    if (state.loadingMore || !state.hasMore) return;
    setState(() => state.loadingMore = true);
    try {
      final page = await widget.client.getMovementHistory(period: _periodApiValue[period]!, before: state.cursor);
      setState(() {
        state.items.addAll((page['items'] as List).cast<Map<String, dynamic>>());
        state.cursor = page['next_cursor'] as String?;
        state.hasMore = state.cursor != null;
      });
    } on ApiException catch (_) {
    } finally {
      if (mounted) setState(() => state.loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final historyState = _historyByPeriod[_period]!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.movementReportsTitle)),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: TextStyle(color: AppColors.error), textAlign: TextAlign.center)))
                : RefreshIndicator(
                    onRefresh: _loadEverything,
                    color: AppColors.gold,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _PeriodTabs(period: _period, onChanged: (p) => setState(() => _period = p)),
                        const SizedBox(height: 14),
                        _buildTotalCard(l10n),
                        const SizedBox(height: 14),
                        _buildChartForPeriod(l10n),
                        const SizedBox(height: 18),
                        _buildHistorySectionLabel(l10n),
                        const SizedBox(height: 10),
                        ...historyState.items.map((item) => _HistoryItem(item: item, period: _period, l10n: l10n)),
                        if (historyState.hasMore) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: historyState.loadingMore
                                ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                                : TextButton(onPressed: () => _loadMoreHistory(_period), child: Text(l10n.movementReportsHistoryLoadMore)),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHistorySectionLabel(AppLocalizations l10n) {
    return Row(
      children: [
        Text(
          l10n.movementReportsHistorySectionTitle.toUpperCase(),
          style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 11).copyWith(letterSpacing: 1.2),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: AppColors.muted.withValues(alpha: 0.15))),
      ],
    );
  }

  // Total card (§2.2) — total do PERÍODO selecionado, sempre com XP/
  // meta%/streak como contexto, nunca um número isolado.
  Widget _buildTotalCard(AppLocalizations l10n) {
    int totalSteps;
    int xpGained;
    switch (_period) {
      case MovementReportPeriod.day:
        totalSteps = (_currentCycle?['steps_collected'] as int?) ?? 0;
        xpGained = (_currentCycle?['xp_awarded'] as int?) ?? 0;
      case MovementReportPeriod.week:
        totalSteps = _weekCycles.fold(0, (sum, c) => sum + (c['steps_collected'] as int));
        xpGained = _weekCycles.fold(0, (sum, c) => sum + (c['xp_awarded'] as int));
      case MovementReportPeriod.month:
        totalSteps = (_monthData?['total_steps'] as int?) ?? 0;
        xpGained = (_monthData?['total_xp_awarded'] as int?) ?? 0;
      case MovementReportPeriod.year:
        totalSteps = (_yearData?['total_steps'] as int?) ?? 0;
        xpGained = (_yearData?['total_xp_awarded'] as int?) ?? 0;
    }

    final goal = _dailyGoalSteps;
    final periodDays = switch (_period) {
      MovementReportPeriod.day => 1,
      MovementReportPeriod.week => _weekCycles.isEmpty ? 1 : _weekCycles.length,
      MovementReportPeriod.month => DateTime.now().day,
      MovementReportPeriod.year => DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays + 1,
    };
    final goalPercent = (goal != null && goal > 0) ? ((totalSteps / (goal * periodDays)) * 100).clamp(0, 999).round() : null;

    final periodPhrase = switch (_period) {
      MovementReportPeriod.day => l10n.movementReportsTotalPeriodDay,
      MovementReportPeriod.week => l10n.movementReportsTotalPeriodWeek,
      MovementReportPeriod.month => l10n.movementReportsTotalPeriodMonth,
      MovementReportPeriod.year => l10n.movementReportsTotalPeriodYear,
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gold.withValues(alpha: 0.14), AppColors.bg2, AppColors.teal.withValues(alpha: 0.06)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.movementReportsTotalLabel(periodPhrase).toUpperCase(),
            style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 10).copyWith(letterSpacing: 1, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.movementReportsTotalSteps(totalSteps),
            style: AppTheme.technicalStyle(color: AppColors.gold, fontSize: 30).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _TotalSubItem(value: '+$xpGained', label: l10n.movementReportsXpLabel),
              const SizedBox(width: 18),
              if (goalPercent != null) ...[
                _TotalSubItem(value: '$goalPercent%', label: l10n.movementReportsGoalPercentLabel),
                const SizedBox(width: 18),
              ],
              _TotalSubItem(value: '🔥 $_streakDays', label: l10n.movementReportsStreakLabel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartForPeriod(AppLocalizations l10n) {
    switch (_period) {
      case MovementReportPeriod.day:
        return _buildDayChart(l10n);
      case MovementReportPeriod.week:
        return _buildWeekChart(l10n);
      case MovementReportPeriod.month:
        return _buildMonthChart(l10n);
      case MovementReportPeriod.year:
        return _buildYearChart(l10n);
    }
  }

  Widget _buildDayChart(AppLocalizations l10n) {
    if (_daySessions.isEmpty) return Text(l10n.movementReportsEmptyMessage, style: TextStyle(color: AppColors.muted));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(l10n.movementReportsDayChartTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 14.5))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.12), border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(100)),
                child: Text(l10n.movementReportsLiveBadge, style: AppTheme.technicalStyle(color: AppColors.teal, fontSize: 10.5).copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(height: 130, child: _DaySessionsChart(sessions: _daySessions, l10n: l10n)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.82,
            children: [for (final session in _daySessions) _SessionCard(session: session)],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekChart(AppLocalizations l10n) {
    if (_weekCycles.length < 2) return Text(l10n.movementReportsEmptyMessage, style: TextStyle(color: AppColors.muted));
    final average = _weekCycles.fold(0, (sum, c) => sum + (c['steps_collected'] as int)) ~/ _weekCycles.length;
    return SizedBox(
      height: 190,
      child: ChartCard(
        dotColor: AppColors.teal,
        title: l10n.movementReportsWeekChartTitle,
        trailing: l10n.movementReportsAverageBadge(average),
        child: _WeekBarChart(cycles: _weekCycles, l10n: l10n),
      ),
    );
  }

  Widget _buildMonthChart(AppLocalizations l10n) {
    final data = _monthData;
    final days = (data?['days'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (days.isEmpty || (data?['active_days'] as int? ?? 0) == 0) {
      return Text(l10n.movementReportsEmptyMessage, style: TextStyle(color: AppColors.muted));
    }
    final average = data!['average_steps_per_active_day'] as int;
    return SizedBox(
      height: 190,
      child: ChartCard(
        dotColor: AppColors.purple,
        title: l10n.movementReportsMonthChartTitle,
        trailing: l10n.movementReportsAverageBadge(average),
        child: _MonthBarChart(days: days),
      ),
    );
  }

  Widget _buildYearChart(AppLocalizations l10n) {
    final data = _yearData;
    final months = (data?['months'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (months.isEmpty) return Text(l10n.movementReportsEmptyMessage, style: TextStyle(color: AppColors.muted));
    return SizedBox(
      height: 190,
      child: ChartCard(
        dotColor: AppColors.gold,
        title: l10n.movementReportsYearChartTitle,
        trailing: '${data!['total_steps']}',
        child: _YearBarChart(months: months),
      ),
    );
  }
}

class _TotalSubItem extends StatelessWidget {
  const _TotalSubItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: AppTheme.technicalStyle(color: AppColors.bone, fontSize: 15).copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 10.5).copyWith(letterSpacing: 0.4)),
      ],
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.period, required this.onChanged});

  final MovementReportPeriod period;
  final ValueChanged<MovementReportPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      MovementReportPeriod.day: l10n.movementReportsTabDay,
      MovementReportPeriod.week: l10n.movementReportsTabWeek,
      MovementReportPeriod.month: l10n.movementReportsTabMonth,
      MovementReportPeriod.year: l10n.movementReportsTabYear,
    };
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(100)),
      child: Row(
        children: [
          for (final entry in labels.entries)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: entry.key == period ? LinearGradient(colors: [AppColors.gold, const Color(0xFFFF8A3D)]) : null,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    entry.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: entry.key == period ? const Color(0xFF241000) : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Gráfico de linha/área do dia (§3.2) — 6 pontos, um por sessão de 4h
/// (não 24 pontos por hora: a granularidade da spec é por sessão).
/// Etiqueta flutuante do pico (§3.2 "uma pequena etiqueta indicando o
/// valor... diretamente sobre o gráfico") posicionada por fração do
/// espaço disponível, já que fl_chart não expõe coordenadas de pixel
/// dos pontos plotados.
class _DaySessionsChart extends StatelessWidget {
  const _DaySessionsChart({required this.sessions, required this.l10n});

  final List<Map<String, dynamic>> sessions;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final values = [for (final s in sessions) s['steps'] as int];
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final maxY = maxValue <= 0 ? 10.0 : maxValue * 1.35;
    final peakIndex = values.indexOf(maxValue);

    return LayoutBuilder(
      builder: (context, constraints) {
        final peakX = maxValue <= 0 ? 0.0 : (peakIndex / (values.length - 1)) * constraints.maxWidth;
        final peakY = maxValue <= 0 ? 0.0 : constraints.maxHeight * (1 - (maxValue / maxY)) - 22;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            LineChart(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              LineChartData(
                minX: 0,
                maxX: (values.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i].toDouble())],
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: const Color(0xFFFF8A3D),
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        final isPeak = maxValue > 0 && index == peakIndex;
                        return FlDotCirclePainter(
                          radius: isPeak ? 5.5 : 0,
                          color: AppColors.gold,
                          strokeWidth: isPeak ? 2 : 0,
                          strokeColor: AppColors.bg2,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [const Color(0xFFFF8A3D).withValues(alpha: 0.32), const Color(0xFFFF8A3D).withValues(alpha: 0.0)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (maxValue > 0)
              Positioned(
                left: (peakX - 30).clamp(0, constraints.maxWidth - 60),
                top: peakY.clamp(0, constraints.maxHeight - 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    l10n.movementReportsPeakTag(_compact(maxValue)),
                    style: const TextStyle(color: Color(0xFF241000), fontSize: 10.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static String _compact(int n) {
    if (n < 1000) return '$n';
    final thousands = n / 1000;
    return '${thousands.toStringAsFixed(thousands < 10 ? 1 : 0)}k';
  }
}

/// Card de uma sessão (§3.3) — nome+emoji, horário, valor, frase
/// descritiva dinâmica (já vem pronta do backend). Pico ganha destaque
/// visual diferenciado (borda/fundo dourado), igual ao protótipo.
class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final Map<String, dynamic> session;

  @override
  Widget build(BuildContext context) {
    final isPeak = session['is_peak'] as bool;
    final accent = isPeak ? AppColors.gold : AppColors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isPeak ? AppColors.gold.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${session['emoji']} ${session['label']}',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.bone, height: 1.15),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${session['start_hour']}h–${session['end_hour'] == 24 ? '23:59' : '${session['end_hour']}h'}',
            style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 9.5),
          ),
          const SizedBox(height: 3),
          Text('${session['steps']}', style: AppTheme.technicalStyle(color: accent, fontSize: 14).copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Expanded(
            child: Text(
              session['description'] as String,
              style: TextStyle(fontSize: 9.5, color: AppColors.muted, height: 1.3),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Semana (§4) — barra por dia, destaque no dia ATUAL (não no maior/
/// menor valor, critério diferente das telas antigas).
class _WeekBarChart extends StatelessWidget {
  const _WeekBarChart({required this.cycles, required this.l10n});

  final List<Map<String, dynamic>> cycles;
  final AppLocalizations l10n;

  static const _weekdayLabels = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

  @override
  Widget build(BuildContext context) {
    final values = cycles.map((c) => c['steps_collected'] as int).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final maxY = maxValue <= 0 ? 10.0 : maxValue * 1.25;
    final todayIndex = cycles.length - 1;

    return BarChart(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 3, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.bg, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
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
                final isToday = index == todayIndex;
                final start = DateTime.parse(cycles[index]['cycle_start_at'] as String);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    isToday ? l10n.movementReportsTodayLabel : _weekdayLabels[start.weekday - 1],
                    style: AppTheme.technicalStyle(color: isToday ? AppColors.gold : AppColors.bone, fontSize: 12).copyWith(fontWeight: FontWeight.w700),
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
                  color: i == todayIndex ? AppColors.gold : AppColors.teal,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Mês (§5) — uma barra por dia do mês, destaque no dia de melhor
/// desempenho (is_best já vem calculado do backend).
class _MonthBarChart extends StatelessWidget {
  const _MonthBarChart({required this.days});

  final List<Map<String, dynamic>> days;

  @override
  Widget build(BuildContext context) {
    final values = [for (final d in days) d['steps'] as int];
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final maxY = maxValue <= 0 ? 10.0 : maxValue * 1.25;

    return BarChart(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceBetween,
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 3, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.bg, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.bg,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem('${days[groupIndex]['day']}: ${rod.toY.round()}', AppTheme.technicalStyle(color: AppColors.bone, fontSize: 11)),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              interval: 5,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= days.length) return const SizedBox.shrink();
                return Text('${days[index]['day']}', style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 10.5));
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i].toDouble(),
                  width: 6,
                  borderRadius: BorderRadius.circular(3),
                  color: days[i]['is_best'] as bool ? AppColors.gold : AppColors.purple,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Ano (§6) — uma barra por mês, destaque no melhor mês (is_best vem
/// do backend, já reaproveitando get_yearly_summary).
class _YearBarChart extends StatelessWidget {
  const _YearBarChart({required this.months});

  final List<Map<String, dynamic>> months;

  static const _monthLabels = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];

  @override
  Widget build(BuildContext context) {
    final byMonth = {for (final m in months) m['month'] as int: m};
    final values = [for (var m = 1; m <= 12; m++) (byMonth[m]?['total_steps'] as int?) ?? 0];
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final maxY = maxValue <= 0 ? 10.0 : maxValue * 1.25;

    return BarChart(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 3, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.bg, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
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
              reservedSize: 20,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= 12) return const SizedBox.shrink();
                final isBest = byMonth[index + 1]?['is_best'] as bool? ?? false;
                return Text(_monthLabels[index], style: AppTheme.technicalStyle(color: isBest ? AppColors.gold : AppColors.muted, fontSize: 10.5).copyWith(fontWeight: isBest ? FontWeight.w700 : FontWeight.w400));
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < 12; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i].toDouble(),
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                  color: (byMonth[i + 1]?['is_best'] as bool? ?? false) ? AppColors.gold : AppColors.teal,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Item de histórico (§7) — numeração sequencial de dia de uso, data,
/// passos, XP, e acumulado até aquele dia. Ponto colorido indica se a
/// meta diária foi atingida naquele dia.
class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.item, required this.period, required this.l10n});

  final Map<String, dynamic> item;
  final MovementReportPeriod period;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final number = item['period_number'] as int;
    final isCurrent = item['is_current'] as bool;
    final goalReached = item['goal_reached'] as bool;

    final title = switch (period) {
      MovementReportPeriod.day => isCurrent ? l10n.movementReportsHistoryTodayLabel(number) : l10n.movementReportsHistoryDayLabel(number),
      MovementReportPeriod.week => isCurrent ? l10n.movementReportsHistoryCurrentWeekLabel(number) : l10n.movementReportsHistoryWeekLabel(number),
      MovementReportPeriod.month => isCurrent ? l10n.movementReportsHistoryCurrentMonthLabel(number) : l10n.movementReportsHistoryMonthLabel(number),
      MovementReportPeriod.year => isCurrent ? l10n.movementReportsHistoryCurrentYearLabel(number) : l10n.movementReportsHistoryYearLabel(number),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.muted.withValues(alpha: 0.12))),
      child: Row(
        children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: goalReached ? AppColors.gold : AppColors.teal)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTheme.technicalStyle(color: AppColors.bone, fontSize: 13.5).copyWith(fontWeight: FontWeight.w700),
                ),
                Text(item['label'] as String, style: TextStyle(color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${item['steps']}', style: AppTheme.technicalStyle(color: AppColors.teal, fontSize: 14.5).copyWith(fontWeight: FontWeight.w700)),
              Text(l10n.movementReportsHistoryXp(item['xp_awarded'] as int), style: TextStyle(color: AppColors.gold, fontSize: 10.5, fontWeight: FontWeight.w600)),
              Text(l10n.movementReportsHistoryAccumulated(item['cumulative_steps'] as int), style: TextStyle(color: AppColors.muted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
