import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_photo.dart';

/// V4 item 1 — Perfil Público de outro usuário
/// (PERFIL_PUBLICO_E_TORCIDA_V1.md). Tela de LEITURA — nunca decide
/// sozinha o que exibir, só renderiza o que GET /profile/{id}/public
/// devolve (mesma regra de autoridade única já aplicada em XP/score).
/// Torcida (TORCIDA_MULTIPLA_V2.md): 4 ícones pré-definidos, nunca
/// texto livre.
class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({super.key, required this.client, required this.userId});

  final ApiClient client;
  final String userId;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  Map<String, dynamic>? _profile;
  String? _error;
  bool _sendingReaction = false;

  static const _reactionTypes = ['vibracao', 'balao', 'coracao', 'joinha'];
  static const _reactionEmoji = {'vibracao': '⚡', 'balao': '🎈', 'coracao': '💚', 'joinha': '👍'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _profile = null;
      _error = null;
    });
    try {
      final profile = await widget.client.getPublicProfile(widget.userId);
      if (mounted) setState(() => _profile = profile);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _sendTorcida(String reactionType) async {
    if (_sendingReaction) return;
    setState(() => _sendingReaction = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await widget.client.sendTorcida(widget.userId, reactionType);
      if (!mounted) return;
      setState(() => _profile = {..._profile!, 'torcida_sent_today_by_me': result['sent_today_by_me']});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.publicProfileTorcidaSentFeedback)));
    } on ApiException catch (e) {
      if (!mounted) return;
      final message = e.code == 'TORCIDA_DAILY_LIMIT_REACHED' ? l10n.publicProfileTorcidaLimitReached : e.message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _sendingReaction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = _profile;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.publicProfileScreenTitle)),
      body: SafeArea(
        child: profile == null
            ? Center(
                child: _error != null
                    ? Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: TextStyle(color: AppColors.error), textAlign: TextAlign.center))
                    : const CircularProgressIndicator(),
              )
            : _buildBody(context, l10n, profile),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, Map<String, dynamic> profile) {
    final displayName = () {
      final realName = profile['real_name'] as String?;
      return realName != null && realName.isNotEmpty ? realName : profile['nickname'] as String;
    }();
    final level = profile['level'] as int;
    final xpTotal = profile['xp_total'] as int;
    final streak = profile['current_streak'] as int;
    final bestTerritoryId = profile['best_territory_id'] as String?;
    final badges = (profile['badges'] as List).cast<Map<String, dynamic>>();
    final worlds = (profile['worlds'] as List).cast<Map<String, dynamic>>();
    final sentToday = profile['torcida_sent_today_by_me'] as int;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              ProfilePhotoCircle(photoUrl: profile['photo_url'] as String?, size: 88),
              const SizedBox(height: 12),
              Text(displayName, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(l10n.publicProfileLevelLabel(level), style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
              Text(l10n.publicProfileXpLabel(xpTotal), style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 13)),
              if (streak > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded, color: AppColors.gold, size: 16),
                    const SizedBox(width: 4),
                    Text(l10n.publicProfileStreakLabel(streak), style: TextStyle(color: AppColors.gold, fontSize: 13)),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(l10n.publicProfileBestTerritoryLabel, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          bestTerritoryId ?? l10n.publicProfileNoBestTerritory,
          style: TextStyle(color: bestTerritoryId != null ? AppColors.bone : AppColors.muted),
        ),
        const SizedBox(height: 24),
        Text(l10n.publicProfileBadgesLabel, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (badges.isEmpty)
          Text(l10n.publicProfileNoBadges, style: TextStyle(color: AppColors.muted))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: badges
                .map(
                  (badge) => Chip(
                    avatar: Icon(Icons.emoji_events, color: AppColors.gold, size: 18),
                    label: Text(badge['name'] as String),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 24),
        Text(l10n.publicProfileWorldsLabel, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...worlds.map(
          (world) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  (world['completed'] as bool) ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: (world['completed'] as bool) ? AppColors.success : AppColors.muted,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(world['name'] as String),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(l10n.publicProfileTorcidaLabel, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(l10n.publicProfileTorcidaSentToday(sentToday), style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _reactionTypes
              .map(
                (type) => InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: _sendingReaction ? null : () => _sendTorcida(type),
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.bg2),
                    child: Text(_reactionEmoji[type]!, style: const TextStyle(fontSize: 26)),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
