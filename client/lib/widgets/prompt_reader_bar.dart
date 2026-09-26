import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/prompt_reader_service.dart';
import '../services/tts_service.dart' show TtsSpeed;
import '../theme/app_theme.dart';

/// Território de idioma (Idiomas tem leitor próprio, flutter_edge_tts) ou Libras
/// (língua visual, dentro do Mundo dos Idiomas): fora do escopo do leitor de
/// enunciados (MENTAL_LEITOR_PERGUNTAS_FEEDBACK_SONORO_V1.1.md).
bool promptReaderAppliesTo(String territoryId) {
  final prefix = territoryId.split('_').first;
  return !const {'ingles', 'espanhol', 'frances', 'libras'}.contains(prefix);
}

/// Leitor manual do enunciado: botão ouvir/parar + Normal/Rápido/Acelerado
/// (mesmo padrão visual de Idiomas). Sem autoplay; nunca bloqueia responder.
class PromptReaderBar extends StatefulWidget {
  const PromptReaderBar({super.key, required this.text, PromptSpeaker? speaker})
      : _speaker = speaker;

  final String text;
  final PromptSpeaker? _speaker;

  @override
  State<PromptReaderBar> createState() => _PromptReaderBarState();
}

class _PromptReaderBarState extends State<PromptReaderBar> {
  static const _kSpeedKey = 'prompt_reader_speed';
  late final PromptSpeaker _speaker = widget._speaker ?? NativePromptSpeaker.instance;
  TtsSpeed _speed = TtsSpeed.normal;

  @override
  void initState() {
    super.initState();
    _loadSpeed();
  }

  Future<void> _loadSpeed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kSpeedKey);
      final speed = TtsSpeed.values.where((s) => s.name == saved).firstOrNull;
      if (speed != null && mounted) setState(() => _speed = speed);
    } catch (_) {}
  }

  Future<void> _setSpeed(TtsSpeed speed) async {
    setState(() => _speed = speed);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSpeedKey, speed.name);
    } catch (_) {}
  }

  @override
  void dispose() {
    // Trocou de pergunta/saiu da tela: a fala não continua sozinha.
    _speaker.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget chip(TtsSpeed value, String label) => ChoiceChip(
          key: Key('prompt_reader_speed_${value.name}'),
          label: Text(label, style: const TextStyle(fontSize: 12)),
          selected: _speed == value,
          visualDensity: VisualDensity.compact,
          onSelected: (_) => _setSpeed(value),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: ValueListenableBuilder<bool>(
        valueListenable: _speaker.speaking,
        builder: (context, speaking, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                IconButton.filledTonal(
                  key: const Key('prompt_reader_button'),
                  tooltip: speaking ? 'Parar leitura' : 'Ouvir a pergunta',
                  icon: Icon(speaking ? Icons.stop_rounded : Icons.volume_up_rounded),
                  onPressed: () => speaking
                      ? _speaker.stop()
                      : _speaker.speak(widget.text, speed: _speed),
                ),
                chip(TtsSpeed.normal, l10n.ttsSpeedNormalLabel),
                chip(TtsSpeed.fast, l10n.ttsSpeedFastLabel),
                chip(TtsSpeed.veryFast, l10n.ttsSpeedVeryFastLabel),
              ],
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _speaker.failed,
              builder: (context, failed, _) => failed
                  ? Text(l10n.audioLoadErrorMessage,
                      key: const Key('prompt_reader_error'),
                      style: TextStyle(color: AppColors.error, fontSize: 12))
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
