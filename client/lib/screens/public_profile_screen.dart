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
  bool _sendingMovementInvite = false;

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

  // Pedido de Rhoney (05/09/2026): botão "GO" na mesma área de Torcida,
  // convidando o visitado a ligar o Movimento — notificação com deep
  // link é responsabilidade do backend (services.send_movement_invite).
  Future<void> _sendMovementInvite() async {
    if (_sendingMovementInvite) return;
    setState(() => _sendingMovementInvite = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await widget.client.sendMovementInvite(widget.userId);
      if (!mounted) return;
      setState(() => _profile = {..._profile!, 'movement_invite_sent_today_by_me': result['sent_today_by_me']});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.publicProfileMovementInviteSentFeedback)));
    } on ApiException catch (e) {
      if (!mounted) return;
      final message = e.code == 'MOVEMENT_INVITE_DAILY_LIMIT_REACHED' ? l10n.publicProfileMovementInviteLimitReached : e.message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _sendingMovementInvite = false);
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
    final movementInviteSentToday = profile['movement_invite_sent_today_by_me'] as int;

    // Pedido de Rhoney (04/09/2026): pull-to-refresh em qualquer tela do
    // app.
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.gold,
      child: ListView(
      // FEEDBACK_NOME_REAL_E_TORCIDA_LAYOUT_V1.md §3 (05/09/2026): os 4
      // ícones de Torcida (último conteúdo da lista) apareciam cortados
      // pela barra de navegação do Android — SafeArea sozinho não cobre
      // bem a área de gesto em todo aparelho/API, então soma o inset
      // real do sistema (MediaQuery) a um respiro fixo generoso, em vez
      // de confiar só no valor mínimo do SafeArea.
      padding: EdgeInsets.fromLTRB(16, 12, 16, 8 + MediaQuery.paddingOf(context).bottom + 12),
      children: [
        // Pedido de Rhoney (05/09/2026): tela compacta o bastante pra
        // caber sem rolagem em telas normais — espaçamentos e tamanhos
        // reduzidos em todas as seções abaixo, "Mundos" virou uma linha
        // (Wrap) em vez de lista vertical.
        Center(
          child: Column(
            children: [
              ProfilePhotoCircle(photoUrl: profile['photo_url'] as String?, size: 64),
              const SizedBox(height: 6),
              Text(displayName, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.publicProfileLevelLabel(level), style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(width: 8),
                  Text(l10n.publicProfileXpLabel(xpTotal), style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 12)),
                  if (streak > 0) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.local_fire_department_rounded, color: AppColors.gold, size: 14),
                    const SizedBox(width: 2),
                    Text(l10n.publicProfileStreakLabel(streak), style: TextStyle(color: AppColors.gold, fontSize: 12)),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.publicProfileBestTerritoryLabel, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.muted)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                bestTerritoryId ?? l10n.publicProfileNoBestTerritory,
                style: TextStyle(color: bestTerritoryId != null ? AppColors.bone : AppColors.muted, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(l10n.publicProfileBadgesLabel, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.muted)),
        const SizedBox(height: 4),
        if (badges.isEmpty)
          Text(l10n.publicProfileNoBadges, style: TextStyle(color: AppColors.muted, fontSize: 13))
        else
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: badges
                .map(
                  (badge) => Chip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    avatar: Icon(Icons.emoji_events, color: AppColors.gold, size: 14),
                    label: Text(badge['name'] as String, style: const TextStyle(fontSize: 12)),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 10),
        Text(l10n.publicProfileWorldsLabel, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.muted)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: worlds
              .map(
                (world) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      (world['completed'] as bool) ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: (world['completed'] as bool) ? AppColors.success : AppColors.muted,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(world['name'] as String, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        Text(l10n.publicProfileTorcidaLabel, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.muted)),
        const SizedBox(height: 2),
        Text(l10n.publicProfileTorcidaSentToday(sentToday), style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _reactionTypes
              .map(
                (type) => InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: _sendingReaction ? null : () => _sendTorcida(type),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.bg2),
                    child: Text(_reactionEmoji[type]!, style: const TextStyle(fontSize: 20)),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        // Pedido de Rhoney (05/09/2026): convite pra ligar o Movimento,
        // na mesma área de incentivo entre jogadores — "GO" leva um
        // alerta com deep link pra tela de Movimento de quem recebe
        // (client de quem recebe trata isso em main.dart).
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(Icons.directions_walk_rounded, color: AppColors.teal, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.publicProfileMovementInviteLabel, style: Theme.of(context).textTheme.labelMedium),
                    if (movementInviteSentToday > 0)
                      Text(l10n.publicProfileMovementInviteAlreadySentToday, style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: (_sendingMovementInvite || movementInviteSentToday > 0) ? null : _sendMovementInvite,
                style: FilledButton.styleFrom(backgroundColor: AppColors.teal, minimumSize: const Size(52, 32), padding: const EdgeInsets.symmetric(horizontal: 12)),
                child: Text(l10n.publicProfileMovementInviteButton, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }
}
