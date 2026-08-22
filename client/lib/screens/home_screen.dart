import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/movement_service.dart';
import '../territories.dart';
import '../theme/app_theme.dart';
import '../widgets/xp_bar.dart';
import 'challenge_screen.dart';
import 'friends_screen.dart';
import 'movement_screen.dart';
import 'progress_screen.dart';
import 'ranking_screen.dart';
import 'settings_screen.dart';

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

  // V2 item 9 — badge de passos ainda não coletados junto ao ícone de
  // Movimento (decisão de Rhoney, 2026-08-21: "catch-up ao reabrir o
  // app", nunca serviço em segundo plano com notificação fixa). Mostra
  // o valor certo assim que a Home carrega, usando a última leitura
  // conhecida do sensor de QUALQUER sessão — não espera um evento novo.
  int? _movementPendingSteps;
  String? _movementCycleId;
  StreamSubscription<int>? _movementStepSub;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadMovementBadge();
  }

  @override
  void dispose() {
    _movementStepSub?.cancel();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    try {
      final progress = await widget.client.progress();
      if (mounted) setState(() => _progress = progress);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _loadMovementBadge() async {
    try {
      final status = await widget.client.movementStatus();
      final enabled = status['movement_enabled'] as bool;
      final cycle = status['current_cycle'] as Map<String, dynamic>?;
      if (!enabled || cycle == null) {
        _movementStepSub?.cancel();
        _movementCycleId = null;
        if (mounted) setState(() => _movementPendingSteps = null);
        return;
      }

      final cycleId = cycle['id'] as String;
      await MovementService.instance.ensureBaselineFor(cycleId);
      final cachedLast = await MovementService.instance.lastKnownRawSteps();
      if (cachedLast != null) {
        final delta = await MovementService.instance.pendingDeltaFor(cycleId, cachedLast);
        if (mounted) setState(() => _movementPendingSteps = delta.uncollectedSteps);
      }

      if (_movementCycleId != cycleId) {
        _movementCycleId = cycleId;
        _movementStepSub?.cancel();
        _movementStepSub = MovementService.instance.stepCountStream().listen((steps) async {
          final delta = await MovementService.instance.pendingDeltaFor(cycleId, steps);
          if (mounted) setState(() => _movementPendingSteps = delta.uncollectedSteps);
        });
      }
    } on ApiException catch (_) {
      // Badge é reforço visual (mesmo princípio de AUDIO_FEEDBACK.md §4
      // aplicado aqui) — nunca bloqueia ou quebra a Home por causa disso.
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

  // V2 item 10 — Mundos completos. O backend é a autoridade sobre o
  // agrupamento (GET /progress já devolve os territórios de cada mundo
  // e se está completo) — a Home só organiza visualmente, nunca decide
  // sozinha quais territórios pertencem a qual mundo.
  List<Widget> _buildTerritoryItems(AppLocalizations l10n) {
    final worlds = (_progress?['worlds'] as List?)?.cast<Map<String, dynamic>>();
    if (worlds == null || worlds.isEmpty) {
      return _territoryButtons(l10n, kTerritoryIds);
    }

    final items = <Widget>[];
    for (final world in worlds) {
      final territoryIds = (world['territory_ids'] as List).cast<String>();
      final completed = world['completed'] as bool;
      if (items.isNotEmpty) items.add(const SizedBox(height: 24));
      items.add(
        Row(
          children: [
            Expanded(
              child: Text(
                world['name'] as String,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (completed) const Icon(Icons.check_circle, color: AppColors.gold, size: 20),
          ],
        ),
      );
      items.add(const SizedBox(height: 12));
      items.addAll(_territoryButtons(l10n, territoryIds));
    }
    return items;
  }

  List<Widget> _territoryButtons(AppLocalizations l10n, List<String> territoryIds) {
    final items = <Widget>[];
    for (final territoryId in territoryIds) {
      if (items.isNotEmpty) items.add(const SizedBox(height: 12));
      final label = territoryLabel(l10n, territoryId);
      final territoryProgress = _territoryProgress(territoryId);
      final conquered = territoryProgress?['conquered'] as bool? ?? false;

      items.add(
        FilledButton(
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
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
      );
    }
    return items;
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
          IconButton(
            tooltip: l10n.friendsTooltip,
            icon: const Icon(Icons.people_outline_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => FriendsScreen(client: widget.client)),
              );
            },
          ),
          IconButton(
            tooltip: l10n.movementTooltip,
            icon: Badge(
              isLabelVisible: (_movementPendingSteps ?? 0) > 0,
              label: Text('${_movementPendingSteps ?? 0}'),
              child: const Icon(Icons.directions_walk_rounded),
            ),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => MovementScreen(client: widget.client)),
              );
              _loadMovementBadge();
            },
          ),
          IconButton(
            tooltip: l10n.settingsTooltip,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SettingsScreen(client: widget.client)),
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
                child: ListView(children: _buildTerritoryItems(l10n)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
