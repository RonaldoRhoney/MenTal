import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Tela de Conquistas — V2 item 1. Catálogo completo com status real
/// (conquistado/bloqueado), consumindo GET /badges — nenhuma lógica de
/// concessão no client, só exibição do que o backend já decidiu
/// (mesma regra de autoridade única já aplicada a XP/score/desbloqueio).
class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.client.badges();
      if (mounted) setState(() => _data = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = _data;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.badgesScreenTitle)),
      body: SafeArea(
        child: data == null
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
            // Pedido de Rhoney (04/09/2026): pull-to-refresh em qualquer
            // tela do app.
            : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.gold,
                child: ListView(
                padding: const EdgeInsets.all(16),
                children: (data['badges'] as List).cast<Map<String, dynamic>>().map((badge) {
                  final earned = badge['earned'] as bool;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          earned ? Icons.emoji_events : Icons.lock_outline,
                          color: earned ? AppColors.gold : AppColors.muted,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                badge['name'] as String,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: earned ? AppColors.bone : AppColors.muted,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                badge['description'] as String,
                                style: TextStyle(color: earned ? AppColors.bone : AppColors.muted),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                earned ? l10n.badgeEarnedLabel : l10n.badgeLockedLabel,
                                style: TextStyle(
                                  color: earned ? AppColors.success : AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
                ),
      ),
    );
  }
}
