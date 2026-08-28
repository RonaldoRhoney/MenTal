import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../widgets/profile_photo.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Tela de Ranking geral — V1.1. Consome GET /ranking, que já garante no
/// backend (RANKING.md §4, SECURITY.md §8) que só `nickname` e `xp` são
/// expostos — nunca user_id/email, e nickname é sempre gerado pelo
/// sistema para conta em child_safe_mode (nunca texto livre de menor
/// visível publicamente). Esta tela não decide anonimização nenhuma —
/// só exibe o que o backend já entrega anonimizado.
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  Map<String, dynamic>? _ranking;
  String? _error;
  String _scope = 'global';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _ranking = null;
      _error = null;
    });
    try {
      final ranking = await widget.client.ranking(scope: _scope, window: 'weekly');
      if (mounted) setState(() => _ranking = ranking);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _setScope(String scope) {
    if (scope == _scope) return;
    setState(() => _scope = scope);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ranking = _ranking;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.rankingScreenTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              // V2 item 12 — scope "friends" agora filtra de verdade no
              // backend (era um parâmetro sem efeito desde o V1.1).
              child: SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'global', label: Text(l10n.rankingScopeGlobal)),
                  ButtonSegment(value: 'friends', label: Text(l10n.rankingScopeFriends)),
                ],
                selected: {_scope},
                onSelectionChanged: (selection) => _setScope(selection.first),
              ),
            ),
            Expanded(
              child: ranking == null
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
                  : _buildList(context, l10n, ranking),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, AppLocalizations l10n, Map<String, dynamic> ranking) {
    final entries = (ranking['entries'] as List).cast<Map<String, dynamic>>();
    final me = ranking['me'] as Map<String, dynamic>?;

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.rankingEmptyMessage, textAlign: TextAlign.center),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            l10n.rankingWindowLabel,
            style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 14),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isMe = me != null && entry['rank'] == me['rank'] && entry['nickname'] == me['nickname'];
              final realName = entry['real_name'] as String?;
              final displayName = realName != null && realName.isNotEmpty
                  ? '${entry['nickname']} · $realName'
                  : entry['nickname'] as String;
              return ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        l10n.rankingPositionLabel(entry['rank'] as int),
                        style: AppTheme.technicalStyle(
                          color: isMe ? AppColors.gold : AppColors.muted,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ProfilePhotoCircle(photoUrl: entry['photo_url'] as String?, size: 32),
                  ],
                ),
                title: Text(
                  isMe ? '$displayName (${l10n.rankingMePrefix})' : displayName,
                  style: TextStyle(
                    color: isMe ? AppColors.gold : AppColors.bone,
                    fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: Text(
                  '${entry['xp']} XP',
                  style: AppTheme.technicalStyle(color: AppColors.teal, fontSize: 14),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
