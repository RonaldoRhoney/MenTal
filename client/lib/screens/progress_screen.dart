import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../territories.dart';
import '../theme/app_theme.dart';
import '../widgets/xp_bar.dart';
import 'badges_screen.dart';

/// Tela de Progresso — V1.1. Nível/XP total (reaproveita XpBar), lista de
/// territórios com conquista real via XP (não um limiar silencioso: o
/// jogador vê exatamente quanto falta), e sequência com estado de
/// proteção. DESIGN_SYSTEM.md aplicado desde a criação, não como
/// retrofit — tokens de cor/tipografia únicos, uma ideia central por
/// tela (aqui, "seu progresso"), terracota só para estados não-punitivos.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Map<String, dynamic>? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final progress = await widget.client.progress();
      if (mounted) setState(() => _progress = progress);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = _progress;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.progressScreenTitle)),
      body: SafeArea(
        child: progress == null
            ? Center(
                child: _error != null
                    ? Text(_error!, style: const TextStyle(color: AppColors.error))
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
                  XpBar(xpTotal: progress['xp_total'] as int, level: progress['level'] as int),
                  const SizedBox(height: 32),
                  Text(l10n.streakSectionTitle, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  _buildStreakSection(l10n, progress['streak'] as Map<String, dynamic>),
                  const SizedBox(height: 32),
                  ...(progress['territories'] as List).map(
                    (t) => _TerritoryProgressTile(territory: t as Map<String, dynamic>),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => BadgesScreen(client: widget.client)),
                      );
                    },
                    child: Text(l10n.viewBadgesButton),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStreakSection(AppLocalizations l10n, Map<String, dynamic> streak) {
    final freezeAvailable = streak['freeze_available'] as bool;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.streakDaysLabel(streak['current_streak'] as int),
          style: AppTheme.technicalStyle(color: AppColors.gold, fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(
          freezeAvailable ? l10n.streakFreezeAvailableMessage : l10n.streakFreezeUsedMessage,
          style: TextStyle(
            color: freezeAvailable ? AppColors.teal : AppColors.muted,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _TerritoryProgressTile extends StatelessWidget {
  const _TerritoryProgressTile({required this.territory});

  final Map<String, dynamic> territory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final xp = territory['xp_in_territory'] as int;
    final threshold = territory['conquest_threshold'] as int;
    final conquered = territory['conquered'] as bool;
    final unlocked = territory['unlocked'] as bool;
    final fraction = (xp / threshold).clamp(0.0, 1.0);
    final label = territoryLabel(l10n, territory['territory_id'] as String);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleLarge),
              if (unlocked)
                Text(
                  conquered ? l10n.conqueredBadge : l10n.inProgressBadge,
                  style: TextStyle(
                    color: conquered ? AppColors.success : AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Container(color: AppColors.bg2),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(
                      color: conquered ? AppColors.success : AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.territoryXpLabel(xp, threshold),
            style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
