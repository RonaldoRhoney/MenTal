import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import 'movement_daily_detail_screen.dart';
import 'movement_screen.dart';

/// MENTAL_MOVIMENTO_REFORMULACAO.md §12 — detalhamento semanal (aberto
/// a partir do card "Semana ›" na tela principal). O gráfico completo
/// dos últimos 7 dias não fica mais na tela principal — mora só aqui.
/// Cada barra é tocável e abre o detalhamento daquele dia específico.
class MovementWeeklyDetailScreen extends StatelessWidget {
  const MovementWeeklyDetailScreen({super.key, required this.client, required this.cycles});

  final ApiClient client;
  /// Em ordem cronológica (mais antigo primeiro), sem snapshots — o
  /// detalhe de cada dia é buscado sob demanda ao tocar a barra.
  final List<Map<String, dynamic>> cycles;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.movementWeeklyDetailTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.movementWeeklyDetailHint, style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 11)),
              const SizedBox(height: 12),
              Expanded(
                child: ChartCard(
                  dotColor: AppColors.teal,
                  title: l10n.movementWeeklyChartTitle,
                  trailing: l10n.movementWeeklyChartSubtitle,
                  child: WeeklyStepsBarChart(
                    cycles: cycles,
                    onBarTap: (index) => _openDay(context, cycles[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDay(BuildContext context, Map<String, dynamic> cycle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovementDailyDetailScreen(client: client, cycleId: cycle['id'] as String),
      ),
    );
  }
}
