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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
            ],
          ),
        ),
      ),
    );
  }
}
