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

/// Phrasal Verbs e Expressões Idiomáticas (MUNDO_IDIOMAS_INGLES_PHRASAL_
/// VERBS_V1.md, MUNDO_IDIOMAS_INGLES_EXPRESSOES_IDIOMATICAS_V1.md) invertem
/// o padrão do vocabulário clássico: lá a pergunta é em português e as
/// OPÇÕES são a palavra estrangeira (por isso a voz do idioma faz sentido
/// nas opções); aqui o enunciado traz a frase em inglês, mas as opções são
/// o SIGNIFICADO em português. Ler essas opções com voz/entonação em
/// inglês soa errado — pedido de Rhoney (28/09/2026): "o app deve ler as
/// frases em português, com entonação da língua português". Mesma voz
/// usada pelo MENTAL LINGO (mental_lingo_screen.dart, kMentalLingoVoice)
/// pra explicações em português — consistência de identidade sonora.
const String _kPortugueseVoice = 'pt-BR-FranciscaNeural';
const List<String> _kPortugueseOptionsTerritoryPrefixes = [
  'ingles_phrasal',
  'ingles_expressoes',
  // Palavras Compostas e Contrações Informais (MUNDO_IDIOMAS_INGLES_PALAVRAS_COMPOSTAS_E_
  // CONTRACOES_V1.md, 29/09/2026): mesmo padrão invertido — enunciado em inglês, opções são
  // o SIGNIFICADO em português.
  'ingles_compostas',
  'ingles_contracoes',
  // Falsos Cognatos (MUNDO_IDIOMAS_INGLES_FALSOS_COGNATOS_V1.md, 30/09/2026): mesmo padrão
  // invertido — enunciado traz a frase em inglês, opções são o SIGNIFICADO em português
  // (incluindo o "falso amigo" como distrator proposital).
  'ingles_falsoscognatos',
];

/// Territórios hoje são "<idioma>_<nivel>" (ingles_basico,
/// espanhol_avancado, ...) — casa pelo prefixo antes do "_", sem exigir
/// lista exaustiva de todos os níveis existentes. Exceção: os prefixos
/// mais específicos acima (opções em português) são checados primeiro.
String? voiceForTerritory(String territoryId) {
  for (final prefix in _kPortugueseOptionsTerritoryPrefixes) {
    if (territoryId.startsWith(prefix)) return _kPortugueseVoice;
  }
  final prefix = territoryId.split('_').first;
  return _kIdiomaVoiceByTerritoryPrefix[prefix];
}

/// MUNDO_IDIOMAS_INGLES_PAR_PERFEITO_DIAGNOSTICO_TECNICO_V1.md §6/§7 —
/// Par Perfeito é o primeiro território do app a precisar de MAIS de uma
/// voz pro MESMO idioma (o jogador escolhe o sotaque que quer treinar,
/// §6 do doc principal). Validado tecnicamente em 06/10/2026 (ver commit):
/// três vozes sintetizadas de verdade (en-GB-SoniaNeural, en-GB-
/// RyanNeural, en-US-AriaNeural como controle), todas devolveram áudio
/// real sem erro; Rhoney ouviu as amostras e escolheu Ryan como a voz
/// britânica. Função separada de `voiceForTerritory` (que continua só
/// 1 voz fixa por idioma) pra não acoplar essa escolha de sotaque ao
/// resto do Mundo dos Idiomas — nenhum outro território muda de
/// comportamento.
enum ParPerfeitoAccent { us, uk }

String voiceForParPerfeitoAccent(ParPerfeitoAccent accent) => switch (accent) {
      ParPerfeitoAccent.us => 'en-US-AriaNeural',
      ParPerfeitoAccent.uk => 'en-GB-RyanNeural',
    };
