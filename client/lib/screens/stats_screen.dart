import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../territories.dart';
import '../theme/app_theme.dart';

/// Tela de Estatísticas — V2 item 5. Visão de desempenho complementar à
/// de Progresso (XP/conquista): aqui o foco é qualidade da resposta —
/// acerto, uso de dica, sequência mais longa já vivida, dificuldade
/// adaptativa atual por território. Todo número vem de GET /stats, que
/// o backend já calcula a partir de dado existente (nenhum contador novo
/// no client). Gráficos (fl_chart, MIT/gratuito, sem chamada de rede) a
/// pedido do Rhoney — reforço visual, nunca a única forma de comunicar o
/// número: cada gráfico tem o valor exato em texto ao lado, nunca só a
/// forma (acessibilidade, mesmo princípio já aplicado a som/animação em
/// MICROINTERACTIONS.md §4). DESIGN_SYSTEM.md aplicado desde a criação.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stats = await widget.client.stats();
      if (mounted) setState(() => _stats = stats);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  static String _percent(num value) => '${(value * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = _stats;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsScreenTitle)),
      body: SafeArea(
        child: stats == null
            ? Center(
                child: _error != null
                    ? Text(_error!, style: TextStyle(color: AppColors.error))
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(l10n.preparingChallenge),
                        ],
                      ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(l10n.statsOverviewSectionTitle, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _AccuracyDonut(
                    accuracy: (stats['accuracy'] as num).toDouble(),
                    totalAttempts: stats['total_attempts'] as int,
                  ),
                  const SizedBox(height: 24),
                  // Composição das respostas soma o total (cada tentativa
                  // cai em exatamente uma categoria) — ao contrário de
                  // "acerto por território", aqui um gráfico de pizza é
                  // matematicamente correto, não só bonito.
                  _AnswerBreakdownDonut(
                    hintFreeCorrect: stats['hint_free_correct'] as int,
                    totalCorrect: stats['total_correct'] as int,
                    totalAttempts: stats['total_attempts'] as int,
                  ),
                  const SizedBox(height: 24),
                  _StatRow(label: l10n.statsTotalAttemptsLabel, value: '${stats['total_attempts']}'),
                  _StatRow(
                    label: l10n.statsStreakLabel,
                    value: l10n.statsStreakValue(stats['current_streak'] as int, stats['longest_streak'] as int),
                  ),
                  _StatRow(
                    label: l10n.statsBadgesLabel,
                    value: l10n.statsBadgesValue(stats['badges_earned'] as int, stats['badges_total'] as int),
                  ),
                  const SizedBox(height: 28),
                  Text(l10n.statsByTerritorySectionTitle, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _TerritoryAccuracyGrid(byTerritory: (stats['by_territory'] as List).cast<Map<String, dynamic>>()),
                  const SizedBox(height: 20),
                  ...(stats['by_territory'] as List).map(
                    (t) => _TerritoryStatsCard(territory: t as Map<String, dynamic>),
                  ),
                ],
              ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Text(value, style: AppTheme.technicalStyle(color: AppColors.gold, fontSize: 16)),
        ],
      ),
    );
  }
}

/// Donut de acerto geral — reforço visual do número que já aparece em
/// texto abaixo ("Acerto geral: X%"), nunca a única fonte dele.
class _AccuracyDonut extends StatelessWidget {
  const _AccuracyDonut({required this.accuracy, required this.totalAttempts});

  final double accuracy;
  final int totalAttempts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final correctFraction = totalAttempts == 0 ? 0.0 : accuracy.clamp(0.0, 1.0);

    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 0,
              centerSpaceRadius: 55,
              sections: [
                PieChartSectionData(
                  value: correctFraction,
                  color: AppColors.teal,
                  showTitle: false,
                  radius: 22,
                ),
                PieChartSectionData(
                  value: 1 - correctFraction,
                  color: AppColors.bg2,
                  showTitle: false,
                  radius: 22,
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _StatsScreenState._percent(accuracy),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.teal),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.statsAccuracyLabel,
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Composição de TODAS as respostas em 3 categorias mutuamente exclusivas
/// que somam o total (acerto sem dica + acerto com dica + erro =
/// total_attempts) — diferente de "acerto por território", esta métrica
/// É uma divisão de um todo, então um gráfico de pizza aqui é
/// tecnicamente correto, não só decorativo. Legenda ao lado sempre com o
/// número exato — o gráfico nunca é a única fonte do dado.
class _AnswerBreakdownDonut extends StatelessWidget {
  const _AnswerBreakdownDonut({
    required this.hintFreeCorrect,
    required this.totalCorrect,
    required this.totalAttempts,
  });

  final int hintFreeCorrect;
  final int totalCorrect;
  final int totalAttempts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final correctWithHint = totalCorrect - hintFreeCorrect;
    final incorrect = totalAttempts - totalCorrect;
    final hasAttempts = totalAttempts > 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 120,
          width: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  startDegreeOffset: -90,
                  sectionsSpace: hasAttempts ? 2 : 0,
                  centerSpaceRadius: 38,
                  sections: hasAttempts
                      ? [
                          if (hintFreeCorrect > 0)
                            PieChartSectionData(value: hintFreeCorrect.toDouble(), color: AppColors.teal, showTitle: false, radius: 18),
                          if (correctWithHint > 0)
                            PieChartSectionData(value: correctWithHint.toDouble(), color: AppColors.gold, showTitle: false, radius: 18),
                          if (incorrect > 0)
                            PieChartSectionData(value: incorrect.toDouble(), color: AppColors.error, showTitle: false, radius: 18),
                        ]
                      : [PieChartSectionData(value: 1, color: AppColors.bg2, showTitle: false, radius: 18)],
                ),
              ),
              Text('$totalAttempts', style: AppTheme.technicalStyle(color: AppColors.bone, fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendRow(color: AppColors.teal, label: l10n.statsHintFreeCorrectLabel, value: hintFreeCorrect),
              const SizedBox(height: 8),
              _LegendRow(color: AppColors.gold, label: l10n.statsCorrectWithHintLegend, value: correctWithHint),
              const SizedBox(height: 8),
              _LegendRow(color: AppColors.error, label: l10n.statsIncorrectLegend, value: incorrect),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Text('$value', style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 13)),
      ],
    );
  }
}

/// Comparação de acerto por território — a mesma ideia central de
/// "desempenho por categoria" que dá nome a este item da V2, mas em
/// forma de gráfico em vez de só lista (pedido explícito do Rhoney: mais
/// elegante, dinâmico e intuitivo que só texto).
///
/// Mini-donut por território, não gráfico de barras/pizza único: acerto
/// por território é um percentual INDEPENDENTE por categoria (não uma
/// fatia de um todo que soma 100%), então um único gráfico de pizza
/// distorceria a leitura — e um de barras com 7 categorias lado a lado
/// se mostrou confuso de ler num teste real no celular (rótulos
/// disputando espaço). Um donut pequeno por território preserva a
/// leitura correta (cada um é seu próprio 0-100%) com a estética
/// circular pedida.
class _TerritoryAccuracyGrid extends StatelessWidget {
  const _TerritoryAccuracyGrid({required this.byTerritory});

  final List<Map<String, dynamic>> byTerritory;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 16,
      children: byTerritory.map((t) => _TerritoryAccuracyDonut(territory: t)).toList(),
    );
  }
}

class _TerritoryAccuracyDonut extends StatelessWidget {
  const _TerritoryAccuracyDonut({required this.territory});

  final Map<String, dynamic> territory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final attempts = territory['total_attempts'] as int;
    final accuracy = (territory['accuracy'] as num).toDouble();
    final label = territoryLabel(l10n, territory['territory_id'] as String);
    final hasAttempts = attempts > 0;

    return SizedBox(
      width: 92,
      child: Column(
        children: [
          SizedBox(
            height: 76,
            width: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 0,
                    centerSpaceRadius: 26,
                    sections: [
                      PieChartSectionData(
                        value: hasAttempts ? accuracy.clamp(0.0, 1.0) : 1.0,
                        color: hasAttempts ? AppColors.teal : AppColors.bg2,
                        showTitle: false,
                        radius: 12,
                      ),
                      PieChartSectionData(
                        value: hasAttempts ? 1 - accuracy.clamp(0.0, 1.0) : 0.001,
                        color: AppColors.bg2,
                        showTitle: false,
                        radius: 12,
                      ),
                    ],
                  ),
                ),
                Text(
                  hasAttempts ? '${(accuracy * 100).round()}%' : '—',
                  style: AppTheme.technicalStyle(
                    color: hasAttempts ? AppColors.teal : AppColors.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _TerritoryStatsCard extends StatelessWidget {
  const _TerritoryStatsCard({required this.territory});

  final Map<String, dynamic> territory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = territoryLabel(l10n, territory['territory_id'] as String);
    final attempts = territory['total_attempts'] as int;
    final accuracy = territory['accuracy'] as num;
    final difficultyLevel = territory['current_difficulty_level'] as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            if (attempts == 0)
              Text(l10n.statsNoAttemptsYet, style: TextStyle(color: AppColors.muted))
            else ...[
              Text(
                l10n.statsTerritoryAttemptsAndAccuracy(attempts, '${(accuracy * 100).round()}%'),
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.statsTerritoryDifficultyLabel(difficultyLevel),
                style: AppTheme.technicalStyle(color: AppColors.teal, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
