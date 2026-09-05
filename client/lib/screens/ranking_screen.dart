import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../widgets/profile_photo.dart';
import '../widgets/mentalcoin.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import 'public_profile_screen.dart';

/// Tela de Ranking geral — V1.1. Consome GET /ranking, que já garante no
/// backend (RANKING.md §4, SECURITY.md §8) que só `nickname` e `xp` são
/// expostos — nunca user_id/email, e nickname é sempre gerado pelo
/// sistema para conta em child_safe_mode (nunca texto livre de menor
/// visível publicamente). Esta tela não decide anonimização nenhuma —
/// só exibe o que o backend já entrega anonimizado.
///
/// RANKING_ENRIQUECIDO_V1.md — cada linha ganha um resumo compacto de
/// conquistas (streak/mundos/badges/MentalCoins/passos), destaque
/// visual pro 1º lugar, e indicação clara de que é possível tocar pra
/// ver o perfil público completo.
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            l10n.rankingWindowLabel,
            style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 14),
          ),
        ),
        // RANKING_ENRIQUECIDO_V1.md §4 — dica textual de que a lista é
        // interativa, uma vez só no topo (não repetida por linha).
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(l10n.rankingTapHint, style: TextStyle(color: AppColors.muted, fontSize: 11)),
              ),
            ],
          ),
        ),
        Expanded(
          // Pedido de Rhoney (04/09/2026): pull-to-refresh em qualquer
          // tela do app.
          child: RefreshIndicator(
            onRefresh: _load,
            color: AppColors.gold,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final isMe = me != null && entry['user_id'] == me['user_id'];
                return _RankingRow(
                  entry: entry,
                  isMe: isMe,
                  l10n: l10n,
                  onTap: isMe
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => PublicProfileScreen(client: widget.client, userId: entry['user_id'] as String)),
                          ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.entry, required this.isMe, required this.l10n, required this.onTap});

  final Map<String, dynamic> entry;
  final bool isMe;
  final AppLocalizations l10n;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final rank = entry['rank'] as int;
    final isTop1 = rank == 1;
    // Nome real substitui o apelido gerado pelo sistema ("jogador-xxxx")
    // assim que existir — pedido de Rhoney (29/08/2026).
    final realName = entry['real_name'] as String?;
    final displayName = realName != null && realName.isNotEmpty ? realName : entry['nickname'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: (isTop1 || isMe) ? AppColors.gold.withValues(alpha: 0.10) : AppColors.bg2.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (isTop1 || isMe) ? AppColors.gold.withValues(alpha: 0.35) : AppColors.muted.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 26,
                  child: Column(
                    children: [
                      if (isTop1) const Text('👑', style: TextStyle(fontSize: 14)),
                      Text(
                        l10n.rankingPositionLabel(rank),
                        style: AppTheme.technicalStyle(
                          color: isTop1 ? AppColors.gold : (isMe ? AppColors.gold : AppColors.muted),
                          fontSize: isTop1 ? 15 : 13,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _AvatarWithLevel(photoUrl: entry['photo_url'] as String?, level: entry['level'] as int, highlighted: isTop1),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMe ? '$displayName (${l10n.rankingMePrefix})' : displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isMe ? AppColors.gold : AppColors.bone,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 7),
                      _BadgeRow(entry: entry, l10n: l10n),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${entry['xp']}',
                      style: AppTheme.technicalStyle(color: isTop1 ? AppColors.gold : AppColors.teal, fontSize: 14)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text('XP', style: TextStyle(color: AppColors.muted, fontSize: 8, letterSpacing: 0.5)),
                  ],
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 18, color: AppColors.muted.withValues(alpha: 0.5)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarWithLevel extends StatelessWidget {
  const _AvatarWithLevel({required this.photoUrl, required this.level, required this.highlighted});

  final String? photoUrl;
  final int level;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ProfilePhotoCircle(photoUrl: photoUrl, size: 40, highlighted: highlighted),
        Positioned(
          bottom: -3,
          right: -3,
          child: Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.teal,
              border: Border.all(color: AppColors.bg2, width: 1.5),
            ),
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Text('$level', style: const TextStyle(color: Color(0xFF04231D), fontWeight: FontWeight.w700, fontSize: 9)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.entry, required this.l10n});

  final Map<String, dynamic> entry;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final streak = entry['current_streak'] as int;
    final worldsCompleted = entry['worlds_completed'] as int;
    final worldsTotal = entry['worlds_total'] as int;
    final badgesCount = entry['badges_count'] as int;
    final mentalcoins = entry['mentalcoins_balance'] as int;
    final steps = entry['total_steps'] as int;

    // Cada badge ganha uma cor de identidade (mesma paleta já usada no
    // resto do app, nenhuma cor nova introduzida) — achado de revisão
    // (04/09/2026, pedido de Rhoney: "está confuso, dê mais elegância").
    // Numa linha só (Wrap deixava a 5ª badge cair pra uma 2ª linha em
    // nomes longos), com um gap FIXO e generoso entre badges — spaceBetween
    // (tentativa anterior) deixava o espaçamento apertado demais quando
    // as 5 juntas quase preenchiam a largura disponível. Flexible+
    // FittedBox por pill garante que, no pior caso (nome bem comprido),
    // as badges encolhem levemente em vez de estourar a largura.
    final pills = [
      _pill(
        color: AppColors.error,
        semanticLabel: l10n.rankingBadgeStreakSemantics(streak),
        child: Text('🔥 $streak', style: _pillTextStyle(AppColors.error)),
      ),
      _pill(
        color: AppColors.purple,
        semanticLabel: l10n.rankingBadgeWorldsSemantics(worldsCompleted, worldsTotal),
        child: Text('🌍 $worldsCompleted/$worldsTotal', style: _pillTextStyle(AppColors.purple)),
      ),
      _pill(
        color: AppColors.victory,
        semanticLabel: l10n.rankingBadgeBadgesSemantics(badgesCount),
        child: Text('🏆 $badgesCount', style: _pillTextStyle(AppColors.victory)),
      ),
      _mentalcoinPill(mentalcoins),
      _pill(
        color: AppColors.teal,
        semanticLabel: l10n.rankingBadgeStepsSemantics(steps),
        child: Text('👟 ${_compactNumber(steps)}', style: _pillTextStyle(AppColors.teal)),
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < pills.length; i++) ...[
          if (i > 0) const SizedBox(width: 9),
          _flex(pills[i]),
        ],
      ],
    );
  }

  Widget _flex(Widget pill) => Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: pill));

  static TextStyle _pillTextStyle(Color color) => TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700);

  Widget _pill({required Color color, required String semanticLabel, required Widget child}) {
    return Semantics(
      label: semanticLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.28)),
          borderRadius: BorderRadius.circular(100),
        ),
        child: child,
      ),
    );
  }

  Widget _mentalcoinPill(int mentalcoins) {
    return Semantics(
      label: l10n.rankingBadgeMentalcoinsSemantics(mentalcoins),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.14),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.32)),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MentalCoin(size: 13),
            const SizedBox(width: 4),
            Text('$mentalcoins', style: _pillTextStyle(AppColors.gold)),
          ],
        ),
      ),
    );
  }

  // Formato compacto (RANKING_ENRIQUECIDO_V1.md §2, ex.: "8.4k") — só
  // pra passos, os únicos números potencialmente grandes o bastante pra
  // precisar disso nas badges compactas.
  String _compactNumber(int n) {
    if (n < 1000) return '$n';
    final thousands = n / 1000;
    return '${thousands.toStringAsFixed(thousands < 10 ? 1 : 0)}k';
  }
}
