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

  test(
      'Phrasal Verbs e Expressões Idiomáticas leem as OPÇÕES em português '
      '(pedido de Rhoney, 28/09/2026: opção é o significado em PT, não a '
      'palavra estrangeira — ler com voz em inglês soaria errado)', () {
    for (final territoryId in [
      'ingles_phrasal_basico',
      'ingles_phrasal_relampago_avancado',
      'ingles_expressoes_intermediario',
      'ingles_expressoes_relampago_basico',
    ]) {
      expect(voiceForTerritory(territoryId), 'pt-BR-FranciscaNeural', reason: territoryId);
    }
    // Vocabulário clássico continua com a voz do idioma (opção É a palavra estrangeira).
    expect(voiceForTerritory('ingles_basico'), 'en-US-AriaNeural');
  });
}
