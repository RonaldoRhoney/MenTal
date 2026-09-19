/// MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md §2.3 — "estrutura de dados e de
/// código deve ser genérica por design (idioma como parâmetro/
/// configuração, nunca hardcoded)". Adicionar um idioma novo no futuro é
/// só acrescentar uma linha aqui — nenhuma outra tela/lógica precisa
/// mudar. Territórios que NÃO aparecem aqui (ex.: Libras, que não usa
/// TTS — reforço visual próprio, ver §3) simplesmente não mostram o
/// botão de áudio (`voiceForTerritory` devolve null).
const Map<String, String> _kIdiomaVoiceByTerritoryPrefix = {
  'ingles': 'en-US-AriaNeural',
  'espanhol': 'es-ES-ElviraNeural',
  'frances': 'fr-FR-DeniseNeural',
};

/// Territórios hoje são "<idioma>_<nivel>" (ingles_basico,
/// espanhol_avancado, ...) — casa pelo prefixo antes do "_", sem exigir
/// lista exaustiva de todos os níveis existentes.
String? voiceForTerritory(String territoryId) {
  final prefix = territoryId.split('_').first;
  return _kIdiomaVoiceByTerritoryPrefix[prefix];
}
