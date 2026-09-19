import 'package:flutter_test/flutter_test.dart';

import 'package:mental/idioma_voices.dart';

/// MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md §2.3 — estrutura genérica por
/// design: casa pelo prefixo do território (antes do "_"), sem lista
/// exaustiva de níveis.
void main() {
  test('territórios de idioma falado devolvem a voz certa', () {
    expect(voiceForTerritory('ingles_basico'), 'en-US-AriaNeural');
    expect(voiceForTerritory('ingles_intermediario'), 'en-US-AriaNeural');
    expect(voiceForTerritory('ingles_avancado'), 'en-US-AriaNeural');
    expect(voiceForTerritory('espanhol_basico'), 'es-ES-ElviraNeural');
    expect(voiceForTerritory('frances_avancado'), 'fr-FR-DeniseNeural');
  });

  test('Libras e territórios sem idioma falado não têm voz (sem TTS)', () {
    expect(voiceForTerritory('libras'), isNull);
    expect(voiceForTerritory('ouvido_afiado'), isNull);
    expect(voiceForTerritory('cores'), isNull);
  });
}
