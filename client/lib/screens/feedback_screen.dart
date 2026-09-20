import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../relative_time.dart';
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
  bool _feedFailed = false;
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
      if (mounted) {
        setState(() {
          _feed = (data['items'] as List).cast<Map<String, dynamic>>();
          _feedFailed = false;
        });
      }
    } on ApiException catch (_) {
      // Feed público é reforço, nunca bloqueia o envio de um feedback novo —
      // só mostra um aviso com "tentar de novo" no lugar do mural.
      if (mounted && _feed == null) setState(() => _feedFailed = true);
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
          SnackBar(
              content: Text(AppLocalizations.of(context)!.feedbackSentMessage)),
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

  /// Resposta de qualquer usuário a um comentário (decisão de Rhoney,
  /// 20/09/2026). Devolve true se enviou (o tile limpa o campo).
  Future<bool> _sendReply(String feedbackId, String text) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await widget.client.replyToFeedback(feedbackId, text);
      if (mounted) _loadFeed();
      return true;
    } on ApiException catch (e) {
      if (mounted) {
        final message = e.code == 'DAILY_FEEDBACK_LIMIT'
            ? l10n.feedbackDailyLimitReached
            : e.message;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
      return false;
    }
  }

  Future<void> _deleteReply(String replyId) async {
    try {
      await widget.client.deleteFeedbackReply(replyId);
      if (mounted) _loadFeed();
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
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
        'my_reactions': alreadyReacted
            ? myReactions.where((r) => r != reactionType).toList()
            : [...myReactions, reactionType],
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
    final controller =
        TextEditingController(text: item['admin_reply'] as String? ?? '');
    final reply = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.adminFeedbackReplyDialogTitle),
        content: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 6,
            autofocus: true,
            decoration: InputDecoration(hintText: l10n.adminFeedbackReplyHint)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.settingsDeleteAccountCancelButton)),
          FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(l10n.adminFeedbackReplySendButton)),
        ],
      ),
    );
    if (reply == null || reply.isEmpty || !mounted) return;

    try {
      await widget.client.replyAppFeedback(item['id'] as String, reply);
      if (mounted) _loadFeed();
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feed = _feed;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedbackScreenTitle)),
      body: SafeArea(
        // Pedido de Rhoney (04/09/2026): puxar pra atualizar em toda tela.
        child: RefreshIndicator(
          onRefresh: _loadFeed,
          color: AppColors.gold,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _buildComposer(l10n),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                      width: 3,
                      height: 16,
                      decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(l10n.feedbackMyHistoryTitle,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontSize: 17))),
                  if (feed != null && feed.isNotEmpty)
                    Text(l10n.feedbackCommentsCount(feed.length),
                        style: AppTheme.technicalStyle(
                            color: AppColors.muted, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              if (feed == null && !_feedFailed)
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()))
              else if (_feedFailed)
                _WallMessage(
                  key: const Key('feedback_load_error'),
                  icon: Icons.cloud_off_rounded,
                  text: l10n.feedbackLoadError,
                  actionLabel: l10n.feedbackReloadButton,
                  onAction: _loadFeed,
                )
              else if (feed!.isEmpty)
                _WallMessage(
                    key: const Key('feedback_empty'),
                    icon: Icons.forum_outlined,
                    text: l10n.adminFeedbackEmptyMessage)
              else
                ...feed.map((item) => _FeedbackWallTile(
                      item: item,
                      isAdmin: _isAdmin,
                      onReact: (type) => _react(item['id'] as String, type),
                      onReply: () => _openReplyDialog(item),
                      onSendUserReply: (text) =>
                          _sendReply(item['id'] as String, text),
                      onDeleteUserReply: _deleteReply,
                    )),
            ],
          ),
        ),
      ),
    );
  }

  /// Cartão do compositor — mesmo padrão de Amigos/MentalCoins (ícone +
  /// título serifado, borda dourada sutil).
  Widget _buildComposer(AppLocalizations l10n) {
    final length = _commentController.text.length;
    final canSend = _commentController.text.trim().isNotEmpty && !_sending;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  color: AppColors.gold, size: 22),
              const SizedBox(width: 10),
              Text(l10n.feedbackComposerTitle,
                  style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 8),
          Text(l10n.feedbackScreenIntro,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
                hintText: l10n.feedbackCommentHint, counterText: ''),
            minLines: 4,
            maxLines: 8,
            maxLength: 2000,
            onChanged: (_) => setState(() {}),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Text('$length/2000',
                  key: const Key('feedback_counter'),
                  style: AppTheme.technicalStyle(
                      color: AppColors.muted, fontSize: 12)),
              const Spacer(),
              // minimumSize sobrescrito: o tema global dá largura mínima
              // infinita ao FilledButton (ver _CatalogTile em mentalcoins).
              FilledButton(
                style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 22)),
                onPressed: canSend ? _send : null,
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.feedbackSendButton),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Estado vazio / erro do mural.
class _WallMessage extends StatelessWidget {
  const _WallMessage(
      {super.key,
      required this.icon,
      required this.text,
      this.actionLabel,
      this.onAction});

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.muted),
          const SizedBox(height: 10),
          Text(text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
          if (actionLabel != null) ...[
            const SizedBox(height: 10),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _FeedbackWallTile extends StatefulWidget {
  const _FeedbackWallTile(
      {required this.item,
      required this.isAdmin,
      required this.onReact,
      required this.onReply,
      required this.onSendUserReply,
      required this.onDeleteUserReply});

  final Map<String, dynamic> item;
  final bool isAdmin;
  final void Function(String reactionType) onReact;
  // Resposta OFICIAL da equipe (só admin).
  final VoidCallback onReply;
  // Resposta de QUALQUER usuário (decisão de Rhoney, 20/09/2026): devolve
  // true se enviou, pra limpar o campo.
  final Future<bool> Function(String text) onSendUserReply;
  final void Function(String replyId) onDeleteUserReply;

  @override
  State<_FeedbackWallTile> createState() => _FeedbackWallTileState();
}

class _FeedbackWallTileState extends State<_FeedbackWallTile> {
  final _replyController = TextEditingController();
  bool _composerOpen = false;
  bool _sendingReply = false;

  Map<String, dynamic> get item => widget.item;
  bool get isAdmin => widget.isAdmin;
  void Function(String reactionType) get onReact => widget.onReact;
  VoidCallback get onReply => widget.onReply;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _sendingReply) return;
    setState(() => _sendingReply = true);
    final ok = await widget.onSendUserReply(text);
    if (!mounted) return;
    setState(() {
      _sendingReply = false;
      if (ok) {
        _replyController.clear();
        _composerOpen = false;
      }
    });
  }

  // FEEDBACK_NOME_REAL_E_TORCIDA_LAYOUT_V1.md §1 (05/09/2026) — mesmo
  // padrão já usado em ranking_screen.dart: prefere o nome real, cai
  // pro nickname quando ausente (autor sem nome real, ou mascarado por
  // bloqueio — o backend já resolve qual dos dois mandar).
  static String _authorDisplayName(Map<String, dynamic> item) {
    final realName = item['user_real_name'] as String?;
    return realName != null && realName.isNotEmpty
        ? realName
        : item['user_nickname'] as String;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reply = item['admin_reply'] as String?;
    final myReactions = (item['my_reactions'] as List).cast<String>();
    final likeCount = item['like_count'] as int;
    final loveCount = item['love_count'] as int;
    final replies =
        ((item['replies'] as List?) ?? const []).cast<Map<String, dynamic>>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.muted.withValues(alpha: 0.12))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _InitialAvatar(name: _authorDisplayName(item)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_authorDisplayName(item),
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ),
                Text(formatRelativeTime(l10n, item['created_at'] as String),
                    style: AppTheme.technicalStyle(
                        color: AppColors.muted, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 10),
            Text(item['comment'] as String,
                style: Theme.of(context).textTheme.bodyMedium),
            if (reply != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.teal.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_rounded,
                            size: 16, color: AppColors.teal),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(l10n.feedbackAdminReplyLabel,
                                style: AppTheme.technicalStyle(
                                    color: AppColors.teal, fontSize: 11))),
                        if (item['admin_reply_at'] != null)
                          Text(
                              formatRelativeTime(
                                  l10n, item['admin_reply_at'] as String),
                              style: AppTheme.technicalStyle(
                                  color: AppColors.muted, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(reply, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                _ReactionButton(
                    emoji: '👍',
                    count: likeCount,
                    active: myReactions.contains('like'),
                    onTap: () => onReact('like')),
                const SizedBox(width: 8),
                _ReactionButton(
                    emoji: '❤️',
                    count: loveCount,
                    active: myReactions.contains('love'),
                    onTap: () => onReact('love')),
                const Spacer(),
                TextButton.icon(
                  key: Key('reply_toggle_${item['id']}'),
                  onPressed: () =>
                      setState(() => _composerOpen = !_composerOpen),
                  icon: Icon(Icons.reply_rounded,
                      size: 18, color: AppColors.teal),
                  label: Text(
                    replies.isEmpty
                        ? l10n.feedbackReplyButton
                        : l10n.feedbackRepliesCount(replies.length),
                    style: TextStyle(color: AppColors.teal, fontSize: 13),
                  ),
                ),
                if (isAdmin)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 12)),
                    onPressed: onReply,
                    child: Text(
                        reply == null
                            ? l10n.adminFeedbackReplyButton
                            : l10n.adminFeedbackEditReplyButton,
                        style: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            if (replies.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
                decoration: BoxDecoration(
                  border: Border(
                      left: BorderSide(
                          color: AppColors.muted.withValues(alpha: 0.3),
                          width: 2)),
                ),
                child: Column(
                  children: [
                    for (final r in replies)
                      _ReplyRow(
                        reply: r,
                        canDelete: (r['is_mine'] as bool? ?? false) || isAdmin,
                        onDelete: () =>
                            widget.onDeleteUserReply(r['id'] as String),
                      ),
                  ],
                ),
              ),
            ],
            if (_composerOpen) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: Key('reply_field_${item['id']}'),
                      controller: _replyController,
                      decoration: InputDecoration(
                          hintText: l10n.feedbackReplyHint,
                          counterText: '',
                          isDense: true),
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: Key('reply_send_${item['id']}'),
                    tooltip: l10n.feedbackReplySendButton,
                    onPressed: (_replyController.text.trim().isNotEmpty &&
                            !_sendingReply)
                        ? _submitReply
                        : null,
                    icon: _sendingReply
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded, size: 18),
                  ),
                ],
              ),
            ],
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
  const _ReactionButton(
      {required this.emoji,
      required this.count,
      required this.active,
      required this.onTap});

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
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: active
                      ? AppColors.gold
                      : AppColors.muted.withValues(alpha: 0.25))),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              if (count > 0) ...[
                const SizedBox(width: 5),
                Text('$count',
                    style: AppTheme.technicalStyle(
                        color: active ? AppColors.gold : AppColors.muted,
                        fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar com a inicial do autor (o mural não carrega foto — só nome).
class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name, this.size = 34});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.gold.withValues(alpha: 0.16),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5))),
      child: Text(initial,
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
    );
  }
}

/// Uma resposta de usuário dentro do comentário (mural aberto, 20/09/2026).
class _ReplyRow extends StatelessWidget {
  const _ReplyRow(
      {required this.reply, required this.canDelete, required this.onDelete});

  final Map<String, dynamic> reply;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final realName = reply['user_real_name'] as String?;
    final name = realName != null && realName.isNotEmpty
        ? realName
        : reply['user_nickname'] as String;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InitialAvatar(name: name, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                        child: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                            overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text(
                        formatRelativeTime(l10n, reply['created_at'] as String),
                        style: AppTheme.technicalStyle(
                            color: AppColors.muted, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(reply['comment'] as String,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 14)),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              key: Key('reply_delete_${reply['id']}'),
              tooltip: l10n.feedbackReplyDeleteTooltip,
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.delete_outline_rounded,
                  size: 18, color: AppColors.muted),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
