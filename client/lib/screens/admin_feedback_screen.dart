import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Painel admin de feedback (pedido de Rhoney, 29/08/2026: "deve haver
/// uma área para receber os feedbacks dos usuários... e responder,
/// discutir e interagir com o usuário"). Só chega até aqui quem já viu a
/// entrada de menu (SettingsScreen, condicionada a profile.role ==
/// 'admin') — mas a autorização de verdade é sempre do backend
/// (GET/POST /admin/feedback exigem role=admin no servidor), esta tela
/// nunca decide sozinha quem pode ver o quê.
class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  List<Map<String, dynamic>>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.client.getAdminAppFeedback();
      if (mounted) setState(() => _items = (data['items'] as List).cast<Map<String, dynamic>>());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
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
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.adminFeedbackReplySendButton),
          ),
        ],
      ),
    );
    if (reply == null || reply.isEmpty || !mounted) return;

    try {
      await widget.client.replyAppFeedback(item['id'] as String, reply);
      if (mounted) _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = _items;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminFeedbackScreenTitle)),
      body: SafeArea(
        child: items == null
            ? Center(
                child: _error != null
                    ? Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: AppColors.error)))
                    : const CircularProgressIndicator(),
              )
            : items.isEmpty
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.adminFeedbackEmptyMessage, style: Theme.of(context).textTheme.bodySmall)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _FeedbackItemTile(item: items[index], onReply: () => _openReplyDialog(items[index])),
                  ),
      ),
    );
  }
}

class _FeedbackItemTile extends StatelessWidget {
  const _FeedbackItemTile({required this.item, required this.onReply});

  final Map<String, dynamic> item;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reply = item['admin_reply'] as String?;
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
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: onReply,
                child: Text(reply == null ? l10n.adminFeedbackReplyButton : l10n.adminFeedbackEditReplyButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
