import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// V3.4 (V3/V3.4_LIBRAS.md §5) — player de vídeo embutido para os
/// vídeos de referência institucionais (INES/VLibras/UFSC/IFs) do
/// "Saiba Mais". Nunca navega pra fora do app em condições normais —
/// abre como overlay sobre o MENTAL, fecha sozinho ao terminar o
/// vídeo (§5.1). Se a URL não for reconhecida como YouTube (§5.2),
/// pede confirmação antes de abrir externamente, nunca navega direto.
Future<void> showInstitutionalVideo(
  BuildContext context, {
  required String videoUrl,
  required String sourceName,
  required String sourceUrl,
}) async {
  final videoId = YoutubePlayerController.convertUrlToId(videoUrl);
  if (videoId == null) {
    await _confirmAndOpenExternally(context, videoUrl);
    return;
  }
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _InstitutionalVideoScreen(
        videoId: videoId,
        videoUrl: videoUrl,
        sourceName: sourceName,
        sourceUrl: sourceUrl,
      ),
    ),
  );
}

/// §5.2 — fallback quando o player embutido não está disponível
/// (URL não reconhecida como YouTube, ou falha do player em runtime).
Future<void> _confirmAndOpenExternally(BuildContext context, String videoUrl) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.institutionalVideoFallbackTitle),
      content: Text(l10n.institutionalVideoFallbackBody),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.institutionalVideoFallbackCancel)),
        FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.institutionalVideoFallbackConfirm)),
      ],
    ),
  );
  if (confirmed == true) {
    await launchUrl(Uri.parse(videoUrl), mode: LaunchMode.externalApplication);
  }
}

class _InstitutionalVideoScreen extends StatefulWidget {
  const _InstitutionalVideoScreen({
    required this.videoId,
    required this.videoUrl,
    required this.sourceName,
    required this.sourceUrl,
  });

  final String videoId;
  final String videoUrl;
  final String sourceName;
  final String sourceUrl;

  @override
  State<_InstitutionalVideoScreen> createState() => _InstitutionalVideoScreenState();
}

class _InstitutionalVideoScreenState extends State<_InstitutionalVideoScreen> {
  late final YoutubePlayerController _controller;
  bool _playerFailed = false;

  @override
  void initState() {
    super.initState();
    try {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: widget.videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(showControls: true, showFullscreenButton: false),
      );
      // §5.1 — ao terminar o vídeo, fecha sozinho e volta pro MENTAL,
      // sem exigir ação manual do usuário.
      _controller.stream.listen((value) {
        if (value.playerState == PlayerState.ended && mounted) {
          Navigator.of(context).pop();
        }
      });
    } catch (_) {
      // Falha na criação do player embutido (§5.2) — cai pro fallback
      // assim que a tela terminar de montar (não dá pra fazer
      // navegação dentro de initState).
      _playerFailed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        Navigator.of(context).pop();
        await _confirmAndOpenExternally(context, widget.videoUrl);
      });
    }
  }

  @override
  void dispose() {
    if (!_playerFailed) _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_playerFailed) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: YoutubePlayer(controller: _controller),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.school_outlined, color: AppColors.gold, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => launchUrl(Uri.parse(widget.sourceUrl), mode: LaunchMode.externalApplication),
                      child: Text(
                        l10n.institutionalVideoSourceLabel(widget.sourceName),
                        style: const TextStyle(color: Colors.white70, decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
