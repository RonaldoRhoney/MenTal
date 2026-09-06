import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_photo.dart';
import 'public_profile_screen.dart';

/// FEED_SOCIAL_V1.md — Feed de conquistas (piloto). Só exibe o que
/// GET /feed já devolve pronto (texto de exibição montado no SERVIDOR,
/// nunca formatado aqui) — mesmo princípio de autoridade única já
/// aplicado em PublicProfileScreen/RankingScreen. Reagir a um evento
/// reaproveita 100% o endpoint de Torcida já existente (§7), mandando
/// pro user_id DO EVENTO — nenhuma mecânica de reação nova.
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
  static const _reactionEmoji = {'vibracao': '⚡', 'balao': '🎈', 'coracao': '💚', 'joinha': '👍'};

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
      if (!mounted) return;
      setState(() {
        _events = (result['events'] as List).cast<Map<String, dynamic>>();
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
        _events = [..._events, ...(result['events'] as List).cast<Map<String, dynamic>>()];
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.publicProfileTorcidaSentFeedback)));
    } on ApiException catch (e) {
      if (!mounted) return;
      final message = e.code == 'TORCIDA_DAILY_LIMIT_REACHED' ? l10n.publicProfileTorcidaLimitReached : e.message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _openProfile(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PublicProfileScreen(client: widget.client, userId: userId)),
    );
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
                      child: Text(_error!, style: TextStyle(color: AppColors.error), textAlign: TextAlign.center),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.gold,
                    child: _events.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
                                child: Text(l10n.feedEmptyState, textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _events.length + (_nextCursor != null ? 1 : 0),
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              if (index == _events.length) {
                                return Center(
                                  child: _loadingMore
                                      ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())
                                      : OutlinedButton(onPressed: _loadMore, child: Text(l10n.feedLoadMoreButton)),
                                );
                              }
                              final event = _events[index];
                              return _FeedEventCard(
                                event: event,
                                reactionTypes: _reactionTypes,
                                reactionEmoji: _reactionEmoji,
                                onTapProfile: () => _openProfile(event['user_id'] as String),
                                onReact: (type) => _react(event['user_id'] as String, type),
                              );
                            },
                          ),
                  ),
      ),
    );
  }
}

class _FeedEventCard extends StatelessWidget {
  const _FeedEventCard({
    required this.event,
    required this.reactionTypes,
    required this.reactionEmoji,
    required this.onTapProfile,
    required this.onReact,
  });

  final Map<String, dynamic> event;
  final List<String> reactionTypes;
  final Map<String, String> reactionEmoji;
  final VoidCallback onTapProfile;
  final void Function(String reactionType) onReact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTapProfile,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                ProfilePhotoCircle(photoUrl: event['photo_url'] as String?, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(event['text'] as String, style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: reactionTypes
                .map(
                  (type) => InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onReact(type),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(reactionEmoji[type]!, style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
