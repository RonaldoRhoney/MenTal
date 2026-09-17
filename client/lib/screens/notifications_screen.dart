import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import 'battles_screen.dart';
import 'friends_screen.dart';
import 'movement_screen.dart';
import 'progress_screen.dart';
import 'public_profile_screen.dart';

/// CENTRAL_DE_NOTIFICACOES_HOME_V1.md — histórico persistente dentro do
/// app, complementar ao push (que continua disparando normalmente, em
/// paralelo). Só exibe o que GET /notifications já devolve pronto
/// (título/corpo montados no SERVIDOR, nunca formatado aqui) — mesmo
/// princípio de autoridade única já aplicado em FeedScreen/RankingScreen.
/// Ícone/cor por tipo é reforço visual só do client (doc §2.2: "cada
/// tipo deve ter identidade visual própria"), nunca lógica de negócio.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  String? _nextCursor;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  static const _typeVisuals = {
    'battle_challenge': (icon: Icons.sports_martial_arts_rounded, color: _NotifColor.teal),
    'battle_turn': (icon: Icons.sports_martial_arts_rounded, color: _NotifColor.gold),
    'battle_result': (icon: Icons.emoji_events_rounded, color: _NotifColor.gold),
    'torcida': (icon: Icons.favorite_rounded, color: _NotifColor.gold),
    'movement_invite': (icon: Icons.directions_walk_rounded, color: _NotifColor.teal),
    'movement_report': (icon: Icons.directions_walk_rounded, color: _NotifColor.teal),
    'movement_activation_invite': (icon: Icons.directions_walk_rounded, color: _NotifColor.muted),
    'territory_dethroned': (icon: Icons.flag_rounded, color: _NotifColor.error),
    'friend_request': (icon: Icons.person_add_rounded, color: _NotifColor.teal),
    'friend_accepted': (icon: Icons.people_alt_rounded, color: _NotifColor.teal),
    'system': (icon: Icons.notifications_rounded, color: _NotifColor.muted),
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
      final result = await widget.client.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = (result['notifications'] as List).cast<Map<String, dynamic>>();
        _nextCursor = result['next_cursor'] as String?;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final result = await widget.client.getNotifications(before: cursor);
      if (!mounted) return;
      setState(() {
        _notifications = [..._notifications, ...(result['notifications'] as List).cast<Map<String, dynamic>>()];
        _nextCursor = result['next_cursor'] as String?;
      });
    } on ApiException catch (_) {
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await widget.client.markAllNotificationsRead();
    } on ApiException catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _notifications = [
        for (final n in _notifications) {...n, 'read': true},
      ];
    });
  }

  Future<void> _handleTap(Map<String, dynamic> notification) async {
    final id = notification['id'] as String;
    if (notification['read'] != true) {
      unawaited(widget.client.markNotificationRead(id));
      if (mounted) {
        setState(() {
          final index = _notifications.indexWhere((n) => n['id'] == id);
          if (index != -1) _notifications[index] = {..._notifications[index], 'read': true};
        });
      }
    }

    final data = notification['data'] as Map<String, dynamic>?;
    final navigate = data?['navigate'] as String?;
    if (navigate == null || !mounted) return;
    switch (navigate) {
      case 'battles':
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => BattlesScreen(client: widget.client)));
      case 'movement':
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => MovementScreen(client: widget.client)));
      case 'friends':
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => FriendsScreen(client: widget.client)));
      case 'progress':
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProgressScreen(client: widget.client)));
      case 'public_profile':
        final userId = data?['user_id'] as String?;
        if (userId != null) {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PublicProfileScreen(client: widget.client, userId: userId)),
          );
        }
    }
  }

  String _relativeTime(AppLocalizations l10n, DateTime createdAt) {
    final diff = DateTime.now().toUtc().difference(createdAt.toUtc());
    if (diff.inMinutes < 1) return l10n.notificationsTimeJustNow;
    if (diff.inMinutes < 60) return l10n.notificationsTimeMinutes(diff.inMinutes);
    if (diff.inHours < 24) return l10n.notificationsTimeHours(diff.inHours);
    return l10n.notificationsTimeDays(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasUnread = _notifications.any((n) => n['read'] != true);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsScreenTitle),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: Text(l10n.notificationsMarkAllReadButton),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: TextStyle(color: AppColors.error)))
                : _notifications.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(l10n.notificationsEmptyMessage, textAlign: TextAlign.center),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.gold,
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notif) {
                            if (notif.metrics.pixels >= notif.metrics.maxScrollExtent - 200) _loadMore();
                            return false;
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _notifications.length + (_nextCursor != null ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _notifications.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              final notification = _notifications[index];
                              final read = notification['read'] == true;
                              final visual = _typeVisuals[notification['type'] as String] ??
                                  _typeVisuals['system']!;
                              final visualColor = visual.color.resolve();
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: read ? AppColors.bg2 : AppColors.bg2.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: (read ? AppColors.gold : visualColor).withValues(alpha: read ? 0.2 : 0.5),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Material(
                                    type: MaterialType.transparency,
                                    child: ListTile(
                                      onTap: () => _handleTap(notification),
                                      leading: Icon(visual.icon, color: visualColor),
                                      title: Text(
                                        notification['title'] as String,
                                        style: TextStyle(fontWeight: read ? FontWeight.normal : FontWeight.w700),
                                      ),
                                      subtitle: Text(notification['body'] as String),
                                      trailing: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          if (!read)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                                            ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _relativeTime(l10n, DateTime.parse(notification['created_at'] as String)),
                                            style: TextStyle(color: AppColors.muted, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
      ),
    );
  }
}

/// Cor por tipo de notificação avaliada em tempo de build (via
/// .resolve()), nunca como Color fixa em top-level const — AppColors
/// depende do ThemeModeService (claro/escuro), então precisa ser lida
/// dentro do build, não congelada na declaração do mapa estático (mesmo
/// padrão já usado em feed_screen.dart::_EventColor).
enum _NotifColor {
  teal,
  gold,
  muted,
  error;

  Color resolve() => switch (this) {
        _NotifColor.teal => AppColors.teal,
        _NotifColor.gold => AppColors.gold,
        _NotifColor.muted => AppColors.muted,
        _NotifColor.error => AppColors.error,
      };
}
