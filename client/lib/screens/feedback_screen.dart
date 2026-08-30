import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Mural de feedback geral (26/08/2026; revisado 29/08/2026, decisão de
/// Rhoney) — comentário livre sobre o app, diferente do Feedback
/// Pós-Nível (só aparece ao subir de nível, sempre estruturado).
///
/// Desde 29/08/2026 é PÚBLICO: visível a TODOS os usuários (não só
/// autor + admin), com reações de curtir/amei — "isso ajudará mais
/// usuários fazerem comentários sobre o app". Só a resposta continua
/// exclusiva de quem tem role=admin no backend (a checagem de
/// autorização real é sempre do servidor; esta tela só decide se MOSTRA
/// o botão de responder).
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _commentController = TextEditingController();
  bool _sending = false;
  String? _error;
  List<Map<String, dynamic>>? _feed;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _loadProfile();
  }

  Future<void> _loadFeed() async {
    try {
      final data = await widget.client.getAppFeedback();
      if (mounted) setState(() => _feed = (data['items'] as List).cast<Map<String, dynamic>>());
    } on ApiException catch (_) {
      // Feed público é reforço, nunca bloqueia o envio de um feedback novo.
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await widget.client.getProfile();
      if (mounted) setState(() => _isAdmin = profile['role'] == 'admin');
    } on ApiException catch (_) {}
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.client.submitAppFeedback(comment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.feedbackSentMessage)),
        );
        _commentController.clear();
        _loadFeed();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _react(String feedbackId, String reactionType) async {
    // Otimista: alterna localmente antes da resposta do servidor
    // confirmar — reação é reforço social de baixo risco, não precisa
    // esperar round-trip pra parecer responsiva.
    final feed = _feed;
    if (feed == null) return;
    final index = feed.indexWhere((item) => item['id'] == feedbackId);
    if (index == -1) return;

    final item = feed[index];
    final myReactions = (item['my_reactions'] as List).cast<String>();
    final alreadyReacted = myReactions.contains(reactionType);
    final countKey = reactionType == 'like' ? 'like_count' : 'love_count';

    setState(() {
      _feed = [...feed];
      _feed![index] = {
        ...item,
        countKey: (item[countKey] as int) + (alreadyReacted ? -1 : 1),
        'my_reactions': alreadyReacted ? myReactions.where((r) => r != reactionType).toList() : [...myReactions, reactionType],
      };
    });

    try {
      await widget.client.reactToAppFeedback(feedbackId, reactionType);
    } on ApiException catch (_) {
      _loadFeed(); // Desfaz o otimismo recarregando o estado real do servidor.
    }
  }

  Future<void> _openReplyDialog(Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: item['admin_reply'] as String? ?? '');
    final reply = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.adminFeedbackReplyDialogTitle),
        content: TextField(controller: controller, minLines: 3, maxLines: 6, autofocus: true, decoration: InputDecoration(hintText: l10n.adminFeedbackReplyHint)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.settingsDeleteAccountCancelButton)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()), child: Text(l10n.adminFeedbackReplySendButton)),
        ],
      ),
    );
    if (reply == null || reply.isEmpty || !mounted) return;

    try {
      await widget.client.replyAppFeedback(item['id'] as String, reply);
      if (mounted) _loadFeed();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedbackScreenTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l10n.feedbackScreenIntro, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(hintText: l10n.feedbackCommentHint),
              minLines: 4,
              maxLines: 8,
              maxLength: 2000,
              onChanged: (_) => setState(() {}),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 8),
            FilledButton(
              onPressed: (_commentController.text.trim().isNotEmpty && !_sending) ? _send : null,
              child: Text(l10n.feedbackSendButton),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Container(width: 3, height: 16, decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text(l10n.feedbackMyHistoryTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
              ],
            ),
            const SizedBox(height: 12),
            if ((_feed ?? []).isEmpty)
              Text(l10n.adminFeedbackEmptyMessage, style: Theme.of(context).textTheme.bodySmall)
            else
              ..._feed!.map((item) => _FeedbackWallTile(
                    item: item,
                    isAdmin: _isAdmin,
                    onReact: (type) => _react(item['id'] as String, type),
                    onReply: () => _openReplyDialog(item),
                  )),
          ],
        ),
      ),
    );
  }
}

class _FeedbackWallTile extends StatelessWidget {
  const _FeedbackWallTile({required this.item, required this.isAdmin, required this.onReact, required this.onReply});

  final Map<String, dynamic> item;
  final bool isAdmin;
  final void Function(String reactionType) onReact;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reply = item['admin_reply'] as String?;
    final myReactions = (item['my_reactions'] as List).cast<String>();
    final likeCount = item['like_count'] as int;
    final loveCount = item['love_count'] as int;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['user_nickname'] as String, style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 11)),
            const SizedBox(height: 4),
            Text(item['comment'] as String, style: Theme.of(context).textTheme.bodyMedium),
            if (reply != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.feedbackAdminReplyLabel, style: AppTheme.technicalStyle(color: AppColors.teal, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(reply, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                _ReactionButton(emoji: '👍', count: likeCount, active: myReactions.contains('like'), onTap: () => onReact('like')),
                const SizedBox(width: 8),
                _ReactionButton(emoji: '❤️', count: loveCount, active: myReactions.contains('love'), onTap: () => onReact('love')),
                const Spacer(),
                if (isAdmin)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34), padding: const EdgeInsets.symmetric(horizontal: 12)),
                    onPressed: onReply,
                    child: Text(reply == null ? l10n.adminFeedbackReplyButton : l10n.adminFeedbackEditReplyButton, style: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão de reação (curtir/amei) — pedido de Rhoney (29/08/2026):
/// "ponha os ícones de curtir e amei... isso ajudará mais usuários
/// fazerem comentários". Emoji em vez de ícone Material: reforça o tom
/// social/leve do mural sem precisar de um asset novo.
class _ReactionButton extends StatelessWidget {
  const _ReactionButton({required this.emoji, required this.count, required this.active, required this.onTap});

  final String emoji;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.gold.withValues(alpha: 0.16) : AppColors.bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? AppColors.gold : AppColors.muted.withValues(alpha: 0.25))),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              if (count > 0) ...[
                const SizedBox(width: 5),
                Text('$count', style: AppTheme.technicalStyle(color: active ? AppColors.gold : AppColors.muted, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
