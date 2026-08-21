import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sound_mode_advanced/sound_mode_advanced.dart';

/// Camada de som — MICROINTERACTIONS.md / AUDIO_FEEDBACK.md. Reforça o
/// que a interface já comunica em texto/cor; nunca é a única fonte de
/// informação (§4 de ambos os documentos).
enum FeedbackSound {
  /// Acerto comum de desafio — sutil.
  correct,

  /// Erro — suave, neutro, nunca "buzzer".
  incorrect,

  /// Território conquistado / badge desbloqueado / level up — mesma
  /// família sonora para os três, reservada a eventos raros.
  celebration,

  /// Sequência mantida/protegida — moderado, mais discreto que celebração.
  streak,
}

/// Serviço único de feedback sonoro, com as duas exigências não-
/// negociáveis de AUDIO_FEEDBACK.md §3: toggle on/off e volume,
/// persistidos localmente (nunca vão ao backend — não são dado de jogo).
///
/// Nuance técnica registrada aqui de propósito: no Android, o volume de
/// mídia (stream usado por audioplayers) NÃO é automaticamente silenciado
/// pelo modo "silencioso"/"vibrar" do aparelho — só o stream de
/// campainha/notificação é. Por isso a checagem de `sound_mode_advanced`
/// abaixo é o que de fato implementa "nunca toca som em modo silencioso"
/// — sem ela, o app tocaria som mesmo com o celular silenciado.
class FeedbackService {
  FeedbackService._();
  static final FeedbackService instance = FeedbackService._();

  static const _kEnabledKey = 'feedback_sound_enabled';
  static const _kVolumeKey = 'feedback_sound_volume';

  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;
  double _volume = 0.7;
  bool _loaded = false;

  bool get enabled => _enabled;
  double get volume => _volume;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_kEnabledKey) ?? true;
    _volume = prefs.getDouble(_kVolumeKey) ?? 0.7;
    _loaded = true;
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabledKey, value);
  }

  Future<void> setVolume(double value) async {
    _volume = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kVolumeKey, value);
  }

  Future<void> play(FeedbackSound sound) async {
    await ensureLoaded();
    if (!_enabled || _volume <= 0) return;
    if (await _deviceIsSilencedOrVibrating()) return;

    final asset = switch (sound) {
      FeedbackSound.correct => 'audio/correct.wav',
      FeedbackSound.incorrect => 'audio/incorrect.wav',
      FeedbackSound.celebration => 'audio/celebration.wav',
      FeedbackSound.streak => 'audio/streak.wav',
    };

    try {
      await _player.stop();
      await _player.setVolume(_volume);
      await _player.play(AssetSource(asset));
    } catch (_) {
      // Som é reforço, nunca requisito (AUDIO_FEEDBACK.md §4) — uma
      // falha de playback (ex.: dispositivo sem saída de áudio) nunca
      // pode travar ou interromper o fluxo do jogo.
    }
  }

  Future<bool> _deviceIsSilencedOrVibrating() async {
    try {
      final status = await SoundMode.ringerModeStatus;
      return status == RingerModeStatus.silent || status == RingerModeStatus.vibrate;
    } catch (_) {
      // Falha ao consultar o modo do aparelho (plugin indisponível numa
      // versão/fabricante específica) não deve silenciar o app inteiro —
      // assume-se modo normal nesse caso.
      return false;
    }
  }
}
