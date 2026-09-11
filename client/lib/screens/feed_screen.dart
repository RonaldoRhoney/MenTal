import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../color_challenge.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/feed_activity_service.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_photo.dart';
import 'public_profile_screen.dart';

/// FEED_SOCIAL_V1.md — Feed de conquistas (piloto). Só exibe o que
/// GET /feed já devolve pronto (texto de exibição montado no SERVIDOR,
/// nunca formatado aqui) — mesmo princípio de autoridade única já
/// aplicado em PublicProfileScreen/RankingScreen. Reagir a um evento
/// reaproveita 100% o endpoint de Torcida já existente (§7), mandando
/// pro user_id DO EVENTO — nenhuma mecânica de reação nova.
///
/// Revisão visual (06/09/2026, pedido de Rhoney: "padrão profissional,
/// com design, estilo, dinamismo e elegância") — cada tipo de evento
/// ganha um ícone/cor de identidade (mesmo espírito do badge de nível
/// em _AvatarWithLevel de ranking_screen.dart), nome em destaque
/// separado da ação, tempo relativo, e reações em chips com preenchimento
/// sutil em vez de emoji soltos — nunca decoração sem significado
/// (DESIGN_SYSTEM.md §1: "cor não é decoração, é significado").
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Map<String, dynamic>> _events = [];
  String? _nextCursor;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  static const _reactionTypes = ['vibracao', 'balao', 'coracao', 'joinha'];
  static const _reactionEmoji = {
    'vibracao': '⚡',
    'balao': '🎈',
    'coracao': '💚',
    'joinha': '👍'
  };

  static const _eventVisuals = {
    'world_completed': (icon: Icons.public_rounded, color: _EventColor.teal),
    'streak_milestone': (
      icon: Icons.local_fire_department_rounded,
      color: _EventColor.gold
    ),
    'level_up_milestone': (icon: Icons.star_rounded, color: _EventColor.purple),
    'badge_earned': (icon: Icons.emoji_events_rounded, color: _EventColor.gold),
    'battle_won': (icon: Icons.military_tech_rounded, color: _EventColor.teal),
    'movement_record': (
      icon: Icons.directions_walk_rounded,
      color: _EventColor.teal
    ),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.client.getFeed();
      final events = (result['events'] as List).cast<Map<String, dynamic>>();
      // Marca como "visto" já na primeira página — é o mais recente
      // que existe no momento em que o jogador abriu a tela (mesmo
      // princípio de "capturar a transição", não o estado absoluto).
      unawaited(FeedActivityService.markSeen(events));
      if (!mounted) return;
      setState(() {
        _events = events;
        _nextCursor = result['next_cursor'] as String?;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _nextCursor == null) return;
    setState(() => _loadingMore = true);
    try {
      final result = await widget.client.getFeed(before: _nextCursor);
      if (!mounted) return;
      setState(() {
        _events = [
          ..._events,
          ...(result['events'] as List).cast<Map<String, dynamic>>()
        ];
        _nextCursor = result['next_cursor'] as String?;
      });
    } on ApiException catch (_) {
      // Falha ao paginar não derruba a lista já carregada — o botão
      // "carregar mais" simplesmente continua disponível pra nova tentativa.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _react(String targetUserId, String reactionType) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await widget.client.sendTorcida(targetUserId, reactionType);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.publicProfileTorcidaSentFeedback)));
    } on ApiException catch (e) {
      if (!mounted) return;
      final message = e.code == 'TORCIDA_DAILY_LIMIT_REACHED'
          ? l10n.publicProfileTorcidaLimitReached
          : e.message;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _openProfile(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) =>
              PublicProfileScreen(client: widget.client, userId: userId)),
    );
  }

  /// Agrupamento por data (07/09/2026, pedido de Rhoney: "organize de
  /// forma profissional... todas as características de Feed") — cada
  /// grupo vira um `_DateHeaderItem` antes do primeiro evento daquele
  /// dia, seguindo o padrão visual de feed já esperado (Instagram/
  /// Twitter/LinkedIn agrupam assim). `_events` já chega ordenado do
  /// servidor (mais recente primeiro) — só detecta a MUDANÇA de dia
  /// consecutiva, nunca reordena nada.
  List<_FeedListItem> _buildListItems() {
    final items = <_FeedListItem>[];
    DateTime? lastDate;
    for (final event in _events) {
      final createdAt =
          DateTime.tryParse(event['created_at'] as String)?.toLocal();
      if (createdAt != null) {
        final dateOnly =
            DateTime(createdAt.year, createdAt.month, createdAt.day);
        if (lastDate == null || dateOnly != lastDate) {
          items.add(_DateHeaderItem(dateOnly));
          lastDate = dateOnly;
        }
      }
      items.add(_EventItem(event));
    }
    return items;
  }

  String _dateHeaderLabel(AppLocalizations l10n, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return l10n.feedDateHeaderToday;
    if (date == yesterday) return l10n.feedDateHeaderYesterday;
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return l10n.feedDateHeaderOlder('$dd/$mm/${date.year}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedScreenTitle)),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!,
                          style: TextStyle(color: AppColors.error),
                          textAlign: TextAlign.center),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.gold,
                    child: _events.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              _FeedEmptyState(text: l10n.feedEmptyState)
                            ],
                          )
                        : Builder(
                            builder: (context) {
                              final items = _buildListItems();
                              return ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 24),
                                itemCount: items.length +
                                    (_nextCursor != null ? 1 : 0),
                                separatorBuilder: (_, index) {
                                  // Sem respiro extra entre o cabeçalho de
                                  // data e o 1º evento daquele dia — só
                                  // entre eventos normais/entre o fim de
                                  // um grupo e o cabeçalho do próximo.
                                  if (index + 1 < items.length &&
                                      items[index + 1] is _DateHeaderItem) {
                                    return const SizedBox(height: 4);
                                  }
                                  return const SizedBox(height: 14);
                                },
                                itemBuilder: (context, index) {
                                  if (index == items.length) {
                                    return Center(
                                      child: _loadingMore
                                          ? const Padding(
                                              padding: EdgeInsets.all(12),
                                              child:
                                                  CircularProgressIndicator())
                                          : OutlinedButton(
                                              onPressed: _loadMore,
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppColors.gold,
                                                side: BorderSide(
                                                    color: AppColors.gold
                                                        .withValues(
                                                            alpha: 0.5)),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 10),
                                              ),
                                              child:
                                                  Text(l10n.feedLoadMoreButton),
                                            ),
                                    );
                                  }
                                  final item = items[index];
                                  if (item is _DateHeaderItem) {
                                    return _FeedDateHeader(
                                        label:
                                            _dateHeaderLabel(l10n, item.date));
                                  }
                                  final event = (item as _EventItem).event;
                                  final visual =
                                      _eventVisuals[event['event_type']] ??
                                          (
                                            icon: Icons.emoji_events_rounded,
                                            color: _EventColor.gold
                                          );
                                  return _FeedEventCard(
                                    event: event,
                                    icon: visual.icon,
                                    accent: visual.color.resolve(),
                                    reactionTypes: _reactionTypes,
                                    reactionEmoji: _reactionEmoji,
                                    onTapProfile: () => _openProfile(
                                        event['user_id'] as String),
                                    onReact: (type) => _react(
                                        event['user_id'] as String, type),
                                  );
                                },
                              );
                            },
                          ),
                  ),
      ),
    );
  }
}

/// Cor por tipo de evento avaliada em tempo de build (via .resolve()),
/// nunca como Color fixa em top-level const — AppColors depende do
/// ThemeModeService (claro/escuro), então precisa ser lida dentro do
/// build, não congelada na declaração do mapa estático.
enum _EventColor {
  teal,
  gold,
  purple;

  Color resolve() => switch (this) {
        _EventColor.teal => AppColors.teal,
        _EventColor.gold => AppColors.gold,
        _EventColor.purple => AppColors.purple,
      };
}

/// Item da lista renderizada — evento ou cabeçalho de grupo de data
/// (ver `_FeedScreenState._buildListItems`). Sealed pra o itemBuilder
/// nunca precisar de um `as` sem checagem de tipo antes.
sealed class _FeedListItem {}

class _DateHeaderItem extends _FeedListItem {
  _DateHeaderItem(this.date);
  final DateTime date;
}

class _EventItem extends _FeedListItem {
  _EventItem(this.event);
  final Map<String, dynamic> event;
}

class _FeedDateHeader extends StatelessWidget {
  const _FeedDateHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 12)
            .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4),
      ),
    );
  }
}

class _FeedEmptyState extends StatelessWidget {
  const _FeedEmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.10),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
            ),
            child: Icon(Icons.dynamic_feed_rounded,
                color: AppColors.gold.withValues(alpha: 0.7), size: 32),
          ),
          const SizedBox(height: 18),
          Text(text,
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppColors.muted, fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }
}

class _FeedEventCard extends StatelessWidget {
  const _FeedEventCard({
    required this.event,
    required this.icon,
    required this.accent,
    required this.reactionTypes,
    required this.reactionEmoji,
    required this.onTapProfile,
    required this.onReact,
  });

  final Map<String, dynamic> event;
  final IconData icon;
  final Color accent;
  final List<String> reactionTypes;
  final Map<String, String> reactionEmoji;
  final VoidCallback onTapProfile;
  final void Function(String reactionType) onReact;

  /// O texto pronto do servidor sempre começa com o nickname
  /// (notification_copy.FEED_EVENT_TEMPLATES) — separa só pra dar
  /// destaque tipográfico ao nome, nunca reformata o CONTEÚDO da frase.
  (String, String) _splitNameFromText(String nickname, String text) {
    if (text.startsWith(nickname)) {
      return (nickname, text.substring(nickname.length));
    }
    return ('', text);
  }

  String _relativeTime(AppLocalizations l10n, DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return l10n.feedTimeJustNow;
    if (diff.inHours < 1) return l10n.feedTimeMinutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l10n.feedTimeHoursAgo(diff.inHours);
    return l10n.feedTimeDaysAgo(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nickname = event['nickname'] as String;
    final (namePart, actionPart) =
        _splitNameFromText(nickname, event['text'] as String);
    final createdAt = DateTime.tryParse(event['created_at'] as String);

    return Material(
      color: AppColors.bg2.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTapProfile,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
            // Faixa de gradiente sutil na cor do evento — reforça
            // significado (DESIGN_SYSTEM.md §1: cor = significado, não
            // decoração) sem competir com o texto.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent.withValues(alpha: 0.08), Colors.transparent],
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AvatarWithEventBadge(
                      photoUrl: event['photo_url'] as String?,
                      icon: icon,
                      accent: accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                                color: AppColors.bone,
                                fontSize: 14.5,
                                height: 1.3),
                            children: [
                              if (namePart.isNotEmpty)
                                TextSpan(
                                    text: namePart,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                              TextSpan(text: actionPart),
                            ],
                          ),
                        ),
                        if (createdAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _relativeTime(l10n, createdAt),
                            style: AppTheme.technicalStyle(
                                color: AppColors.muted, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: reactionTypes
                    .map(
                      (type) => Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _ReactionChip(
                            emoji: reactionEmoji[type]!,
                            onTap: () => onReact(type)),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarWithEventBadge extends StatelessWidget {
  const _AvatarWithEventBadge(
      {required this.photoUrl, required this.icon, required this.accent});

  final String? photoUrl;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    // Mesmo padrão de _AvatarWithLevel (ranking_screen.dart): badge
    // pequeno sobreposto no canto inferior direito do avatar, aqui com
    // o ícone do tipo de evento em vez do nível.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ProfilePhotoCircle(photoUrl: photoUrl, size: 40),
        Positioned(
          bottom: -3,
          right: -3,
          child: Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
              border: Border.all(color: AppColors.bg2, width: 1.5),
            ),
            child: Icon(icon, size: 12, color: readableTextColorOn(accent)),
          ),
        ),
      ],
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({required this.emoji, required this.onTap});

  final String emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Text(emoji, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
