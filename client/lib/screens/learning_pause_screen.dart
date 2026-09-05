import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/feedback_service.dart';
import '../theme/app_theme.dart';
import '../widgets/institutional_video_player.dart';

/// V3.2 (V3/V3.2_TECNOLOGIA.md §3) — "Pausa para Aprender": leitura sem
/// cronômetro, sem múltipla escolha, sem certo/errado (§3.3) — o único
/// formato de conteúdo do MENTAL que não é desafio/pergunta. Endpoint
/// próprio (GET /learning-pauses/next), nunca reaproveita o fluxo de
/// ChallengeScreen (que é 100% pergunta+resposta).
///
/// Sem celebração grande (confete/fogos) de propósito — §3.4: "não deve
/// ser um atalho de XP fácil". Só um retorno discreto de XP.
class LearningPauseScreen extends StatefulWidget {
  const LearningPauseScreen({super.key, required this.client, required this.territoryId, required this.territoryLabel});

  final ApiClient client;
  final String territoryId;
  final String territoryLabel;

  @override
  State<LearningPauseScreen> createState() => _LearningPauseScreenState();
}

class _LearningPauseScreenState extends State<LearningPauseScreen> {
  bool _loading = true;
  String? _error;
  bool _notFound = false;
  String? _learningPauseId;
  String? _text;
  String? _promptImage;
  String? _videoUrl;
  String? _sourceName;
  String? _sourceUrl;
  bool _completed = false;
  int? _xpAwarded;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _notFound = false;
    });
    try {
      final result = await widget.client.nextLearningPause(widget.territoryId);
      if (!mounted) return;
      setState(() {
        _learningPauseId = result['learning_pause_id'] as String;
        _text = result['text'] as String;
        _promptImage = result['prompt_image'] as String?;
        _videoUrl = result['video_url'] as String?;
        _sourceName = result['source_name'] as String?;
        _sourceUrl = result['source_url'] as String?;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.statusCode == 404) {
          _notFound = true;
        } else {
          _error = e.message;
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _complete() async {
    final id = _learningPauseId;
    if (id == null || _busy) return;
    setState(() => _busy = true);
    try {
      final result = await widget.client.completeLearningPause(id);
      if (!mounted) return;
      final xpAwarded = result['xp_awarded'] as int;
      if (xpAwarded > 0) FeedbackService.instance.play(FeedbackSound.correct);
      setState(() {
        _completed = true;
        _xpAwarded = xpAwarded;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.learningPauseScreenTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _buildBody(l10n),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_notFound) {
      return Center(
        child: Text(l10n.learningPauseEmptyMessage, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          Text(_error!, style: TextStyle(color: AppColors.error)),
          const SizedBox(height: 12),
        ],
        Expanded(
          // Pedido de Rhoney (04/09/2026): pull-to-refresh em qualquer
          // tela do app.
          child: RefreshIndicator(
            onRefresh: _load,
            color: AppColors.gold,
            child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_promptImage != null) ...[
                  Text(_promptImage!, style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                ],
                Text(_text ?? '', style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5)),
                if (_videoUrl != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => showInstitutionalVideo(
                      context,
                      videoUrl: _videoUrl!,
                      sourceName: _sourceName ?? '',
                      sourceUrl: _sourceUrl ?? '',
                    ),
                    icon: const Icon(Icons.play_circle_outline),
                    label: Text(l10n.learningPauseWatchVideoButton),
                  ),
                ],
              ],
            ),
          ),
          ),
        ),
        const SizedBox(height: 16),
        if (_completed)
          Text(
            (_xpAwarded ?? 0) > 0 ? l10n.learningPauseXpAwardedMessage(_xpAwarded!) : l10n.learningPauseAlreadyReadMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700),
          )
        else
          FilledButton(
            onPressed: _busy ? null : _complete,
            child: _busy
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.learningPauseCompleteButton),
          ),
      ],
    );
  }
}
