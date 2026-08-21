import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/xp_bar.dart';
import 'challenge_screen.dart';

const List<String> _kTerritoryIds = ['palavras', 'numeros', 'logica', 'conhecimento'];

String _territoryLabel(AppLocalizations l10n, String territoryId) {
  switch (territoryId) {
    case 'palavras':
      return l10n.territoryPalavras;
    case 'numeros':
      return l10n.territoryNumeros;
    case 'logica':
      return l10n.territoryLogica;
    case 'conhecimento':
      return l10n.territoryConhecimento;
    default:
      return territoryId;
  }
}

/// Home: um CTA primário claro por território, conforme Princípio de
/// Clareza Imediata (PRODUCT_PRINCIPLES.md §1) — nada compete visualmente
/// com "escolher território e jogar".
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

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
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
                  itemCount: _kTerritoryIds.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final territoryId = _kTerritoryIds[index];
                    final territoryLabel = _territoryLabel(l10n, territoryId);
                    return FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChallengeScreen(
                              client: widget.client,
                              territoryId: territoryId,
                              territoryLabel: territoryLabel,
                            ),
                          ),
                        );
                        _loadProgress();
                      },
                      child: Text(l10n.newChallengeButton(territoryLabel)),
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
