import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../territories.dart';
import '../theme/app_theme.dart';
import '../widgets/xp_bar.dart';
import 'challenge_screen.dart';
import 'progress_screen.dart';
import 'ranking_screen.dart';

/// Home: um CTA primário claro por território, conforme Princípio de
/// Clareza Imediata (PRODUCT_PRINCIPLES.md §1) — nada compete visualmente
/// com "escolher território e jogar". Os indicadores de conquista/XP por
/// território (V1.1) são status secundário, não uma segunda ação.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final progress = await widget.client.progress();
      if (mounted) setState(() => _progress = progress);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Map<String, dynamic>? _territoryProgress(String territoryId) {
    final territories = _progress?['territories'] as List?;
    if (territories == null) return null;
    for (final t in territories) {
      if ((t as Map<String, dynamic>)['territory_id'] == territoryId) return t;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            tooltip: l10n.progressTooltip,
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProgressScreen(client: widget.client)),
              );
              _loadProgress();
            },
          ),
          IconButton(
            tooltip: l10n.rankingTooltip,
            icon: const Icon(Icons.leaderboard_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => RankingScreen(client: widget.client)),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (progress != null) ...[
                XpBar(xpTotal: progress['xp_total'] as int, level: progress['level'] as int),
                const SizedBox(height: 12),
                Text(
                  l10n.progressSummary(
                    progress['xp_total'] as int,
                    progress['level'] as int,
                    progress['streak']['current_streak'] as int,
                  ),
                  style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 14),
                ),
              ],
              if (_error != null)
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: kTerritoryIds.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final territoryId = kTerritoryIds[index];
                    final label = territoryLabel(l10n, territoryId);
                    final territoryProgress = _territoryProgress(territoryId);
                    final conquered = territoryProgress?['conquered'] as bool? ?? false;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChallengeScreen(
                                  client: widget.client,
                                  territoryId: territoryId,
                                  territoryLabel: label,
                                ),
                              ),
                            );
                            _loadProgress();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(child: Text(l10n.newChallengeButton(label))),
                              if (conquered) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.check_circle, size: 18),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
