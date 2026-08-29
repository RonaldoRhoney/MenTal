import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Menu de feedback geral (pedido de Rhoney, 2026-08-26) — comentário
/// livre sobre o app, acessível a qualquer momento pelo usuário.
/// Diferente do Feedback Pós-Nível (challenge_screen.dart), que só
/// aparece ao subir de nível e é sempre estruturado (ação + dificuldade).
/// Aqui é só texto livre, sem gatilho nenhum além do próprio usuário
/// querer comentar algo.
///
/// Seção "Meus feedbacks" (29/08/2026, pedido de Rhoney: "campos que eu
/// possa responder, discutir e interagir com o usuário") — mostra os
/// feedbacks já enviados por este usuário e a resposta do admin, quando
/// houver. GET /feedback/mine já marca a resposta como lida no backend
/// ao ser consultado, então basta recarregar a lista pra "ler" a resposta.
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
  List<Map<String, dynamic>>? _myFeedback;

  @override
  void initState() {
    super.initState();
    _loadMyFeedback();
  }

  Future<void> _loadMyFeedback() async {
    try {
      final data = await widget.client.getMyAppFeedback();
      if (mounted) setState(() => _myFeedback = (data['items'] as List).cast<Map<String, dynamic>>());
    } on ApiException catch (_) {
      // Histórico é reforço, nunca bloqueia o envio de um feedback novo.
    }
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
        _loadMyFeedback();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
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
            const SizedBox(height: 24),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(hintText: l10n.feedbackCommentHint),
              minLines: 6,
              maxLines: 10,
              maxLength: 2000,
              onChanged: (_) => setState(() {}),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 8),
            FilledButton(
              onPressed: (_commentController.text.trim().isNotEmpty && !_sending) ? _send : null,
              child: Text(l10n.feedbackSendButton),
            ),
            if ((_myFeedback ?? []).isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(l10n.feedbackMyHistoryTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ..._myFeedback!.map((item) => _MyFeedbackTile(item: item)),
            ],
          ],
        ),
      ),
    );
  }
}

class _MyFeedbackTile extends StatelessWidget {
  const _MyFeedbackTile({required this.item});

  final Map<String, dynamic> item;

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
          ],
        ),
      ),
    );
  }
}
