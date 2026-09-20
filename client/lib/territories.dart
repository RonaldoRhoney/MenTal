import 'l10n/generated/app_localizations.dart';

/// Territórios sempre cronometrados no backend (config.ALWAYS_TIMED_
/// TERRITORIES, routers/challenges.py::next_challenge) — o servidor já
/// ignora `mode` e sempre serve com timer, independente do que o client
/// pedir. Usado só pra decidir a UI da Home: mostrar um botão
/// "Relâmpago" separado ao lado do botão normal é redundante e confuso
/// aqui, já que os dois abrem o MESMO formato cronometrado (achado real,
/// pedido de Rhoney 2026-09-03: "busque erros... em Desafio de cores e
/// relâmpago" — tocar em qualquer um dos dois botões de Cores é
/// indistinguível pro jogador).
const Set<String> kAlwaysTimedTerritoryIds = {
  'conhecimento',
  'cores',
  'curiosidade_relampago',
};

/// V6 — Mundo dos Valores (05/09/2026): "cápsula de texto + perguntas"
/// exige NUNCA cronometrado (fonte do conteúdo: "NAO e Relampago, sem
/// timer, sem penalidade de velocidade" — ler um texto de economia
/// contra o relógio contraria o próprio propósito de compreensão de
/// leitura). O backend já ignora mode=relampago pra estes territórios
/// (config.NEVER_TIMED_TERRITORY_IDS) — aqui só decide a UI da Home:
/// nunca oferecer o botão "Relâmpago" pra eles.
const Set<String> kNeverTimedTerritoryIds = {
  'bolsa',
  'criptomoedas',
  'cenario_global',
  'financas_dia_a_dia',
  // V7 — Mundo do Trânsito (06/09/2026): mesmo formato "cápsula de
  // texto + perguntas", mesmo motivo.
  'educacao_legislacao',
  'historia_curiosidades',
  'transportes_terrestres',
  'economia_transito',
  'prevencao_seguranca',
  // Mundo da Gastronomia (07/09/2026): mesmo formato "cápsula de texto
  // + perguntas", mesmo motivo.
  'gastro_mundo',
  'gastro_brasil',
  'gastro_norte_nordeste',
  'gastro_centrooeste_sudeste',
  'gastro_sul_fusao',
  // Mundo dos Oceanos (07/09/2026): mesmo formato "cápsula de texto +
  // perguntas", mesmo motivo.
  'oceano_mundo',
  'oceano_vida_marinha',
  'oceano_profundezas',
  'oceano_clima',
  'oceano_brasil',
  // Mundo Acima de Nós/Espaço (07/09/2026): mesmo formato "cápsula de
  // texto + perguntas", mesmo motivo.
  'espaco_universo',
  'espaco_planetas',
  'espaco_estrelas',
  'espaco_exploracao',
  'espaco_brasil',
};

/// Ids dos 4 territórios do V1 — compartilhado entre Home, Progress e
/// Challenge para não duplicar a lista nem o mapeamento id→label.
const List<String> kTerritoryIds = [
  'palavras',
  'numeros',
  'logica',
  'conhecimento',
  'enigmas',
  'textos',
  // V4 item 3 (V4/V3_ENCERRAMENTO_PENDENCIAS_PARA_V4.md §2.1).
  'redacao',
  'visual',
  // V3.0 (V3/V3.0_ESPORTES_REGIOES_CULTURA_POP.md).
  'esportes',
  'regioes',
  'cultura_pop',
  // V3.0.1 (V3/V3.0.1_DESAFIO_CORES.md).
  'cores',
  // V3.1 (V3/V3.1_MITOLOGIA_ENEM_CONCURSOS.md).
  'mitologia_grega',
  'mitologia_nordica',
  'mitologia_indigena',
  'enem_linguagens',
  'enem_humanas',
  'enem_natureza',
  'enem_matematica',
  'concursos_portugues',
  'concursos_raciocinio',
  'concursos_direito',
  // V3.2 (V3/V3.2_TECNOLOGIA.md).
  'tecnologia_fundamentos',
  'tecnologia_programacao',
  'tecnologia_seguranca',
  'tecnologia_fronteira',
  // V3.3 (V3/V3.3_VIDA_PRATICA_PENSAMENTO.md).
  'financas_pessoais',
  'filosofia',
  'artes',
  'saude_bemestar',
  // V3.5 (V3/V3.5_CURIOSIDADE_RELAMPAGO.md).
  'curiosidade_relampago',
  // V3.4 (V3/V3.4_LIBRAS.md).
  'libras',
  // V3.3 §6 (V3.3_VIDA_PRATICA_PENSAMENTO.md) — Jogos de Palavras.
  'caca_palavras',
  // V4 (V4/V4_NOVOS_TERRITORIOS.md §1-5).
  'invencoes',
  'veiculos',
  'astronomia',
  'detetive_mental',
  'ouvido_afiado',
  // V5 (Mundo_dos_Idiomas/README.md) — Mundo dos Idiomas.
  'ingles_basico',
  'ingles_intermediario',
  'ingles_avancado',
  'espanhol_basico',
  'espanhol_intermediario',
  'espanhol_avancado',
  'frances_basico',
  'frances_intermediario',
  'frances_avancado',
  // V6 (Mundo_dos_Valores/README.md) — Mundo dos Valores.
  'bolsa',
  'criptomoedas',
  'cenario_global',
  'financas_dia_a_dia',
  // V7 (Mundo_do_Transito/README.md) — Mundo do Trânsito.
  'educacao_legislacao',
  'historia_curiosidades',
  'transportes_terrestres',
  'economia_transito',
  'prevencao_seguranca',
  // Mundo_da_Gastronomia/README.md — Mundo da Gastronomia.
  'gastro_mundo',
  'gastro_brasil',
  'gastro_norte_nordeste',
  'gastro_centrooeste_sudeste',
  'gastro_sul_fusao',
  // Mundo_dos_Oceanos/README.md — Mundo dos Oceanos.
  'oceano_mundo',
  'oceano_vida_marinha',
  'oceano_profundezas',
  'oceano_clima',
  'oceano_brasil',
  // Mundo_Acima_de_Nos/README.md — Mundo Acima de Nós (Espaço).
  'espaco_universo',
  'espaco_planetas',
  'espaco_estrelas',
  'espaco_exploracao',
  'espaco_brasil',
  // ARQUITETURA_SUBMUNDOS_V1.md — SubMundo Internet (Mundo da
  // Tecnologia). Achado real (14/09/2026, teste no celular): os 5
  // territórios já estavam em produção desde 13/09/2026 mas nunca
  // apareciam no carrossel de Mundos da Home nem no seletor de Batalha
  // — home_screen.dart/friends_screen.dart usam esta lista, não a
  // resposta do backend, pra decidir quais territórios existem.
  'internet_origens',
  'internet_sistemas_operacionais',
  'internet_gigantes',
  'internet_cultura',
  'internet_futuro',
  // MUNDO_ESPORTES_ARQUITETURA_V1.md — SubMundo Copa do Mundo (Mundo
  // dos Esportes), mesmo gap do Internet acima corrigido nesta mesma
  // leva.
  'copa_mundo_primeiras_copas',
  'copa_mundo_expansao',
  'copa_mundo_era_moderna',
  'copa_mundo_curiosidades',
  // SubMundo Futebol (mesmo Mundo dos Esportes), curadoria completa em
  // 14/09/2026.
  'futebol_origens',
  'futebol_grandes_nomes',
  'futebol_regras_curiosidades',
  'futebol_atualidade',
  // SubMundo Palavras Raras (Mundo da Linguagem), 20/09/2026.
  'palavras_raras_filosofia',
  'palavras_raras_psicologia',
  'palavras_raras_medicina',
  'palavras_raras_fisica_quimica',
  'palavras_raras_matematica',
  'palavras_raras_linguistica',
  'palavras_raras_historia',
  'palavras_raras_geografia',
  'palavras_raras_direito',
  'palavras_raras_eruditas',
  // SubMundos de gramática da Linguagem (só temas ativos), 20/09/2026.
  'linguagem_crase',
];

String territoryLabel(AppLocalizations l10n, String territoryId) {
  switch (territoryId) {
    case 'palavras':
      return l10n.territoryPalavras;
    case 'numeros':
      return l10n.territoryNumeros;
    case 'logica':
      return l10n.territoryLogica;
    case 'conhecimento':
      return l10n.territoryConhecimento;
    case 'enigmas':
      return l10n.territoryEnigmas;
    case 'textos':
      return l10n.territoryTextos;
    case 'redacao':
      return l10n.territoryRedacao;
    case 'visual':
      return l10n.territoryVisual;
    case 'esportes':
      return l10n.territoryEsportes;
    case 'regioes':
      return l10n.territoryRegioes;
    case 'cultura_pop':
      return l10n.territoryCulturaPop;
    case 'cores':
      return l10n.territoryCores;
    case 'mitologia_grega':
      return l10n.territoryMitologiaGrega;
    case 'mitologia_nordica':
      return l10n.territoryMitologiaNordica;
    case 'mitologia_indigena':
      return l10n.territoryMitologiaIndigena;
    case 'enem_linguagens':
      return l10n.territoryEnemLinguagens;
    case 'enem_humanas':
      return l10n.territoryEnemHumanas;
    case 'enem_natureza':
      return l10n.territoryEnemNatureza;
    case 'enem_matematica':
      return l10n.territoryEnemMatematica;
    case 'concursos_portugues':
      return l10n.territoryConcursosPortugues;
    case 'concursos_raciocinio':
      return l10n.territoryConcursosRaciocinio;
    case 'concursos_direito':
      return l10n.territoryConcursosDireito;
    case 'tecnologia_fundamentos':
      return l10n.territoryTecnologiaFundamentos;
    case 'tecnologia_programacao':
      return l10n.territoryTecnologiaProgramacao;
    case 'tecnologia_seguranca':
      return l10n.territoryTecnologiaSeguranca;
    case 'tecnologia_fronteira':
      return l10n.territoryTecnologiaFronteira;
    case 'internet_origens':
      return l10n.territoryInternetOrigens;
    case 'internet_sistemas_operacionais':
      return l10n.territoryInternetSistemasOperacionais;
    case 'internet_gigantes':
      return l10n.territoryInternetGigantes;
    case 'internet_cultura':
      return l10n.territoryInternetCultura;
    case 'internet_futuro':
      return l10n.territoryInternetFuturo;
    case 'copa_mundo_primeiras_copas':
      return l10n.territoryCopaMundoPrimeirasCopas;
    case 'copa_mundo_expansao':
      return l10n.territoryCopaMundoExpansao;
    case 'copa_mundo_era_moderna':
      return l10n.territoryCopaMundoEraModerna;
    case 'copa_mundo_curiosidades':
      return l10n.territoryCopaMundoCuriosidades;
    case 'palavras_raras_filosofia':
      return l10n.territoryPalavrasRarasFilosofia;
    case 'palavras_raras_psicologia':
      return l10n.territoryPalavrasRarasPsicologia;
    case 'palavras_raras_medicina':
      return l10n.territoryPalavrasRarasMedicina;
    case 'palavras_raras_fisica_quimica':
      return l10n.territoryPalavrasRarasFisicaQuimica;
    case 'palavras_raras_matematica':
      return l10n.territoryPalavrasRarasMatematica;
    case 'palavras_raras_linguistica':
      return l10n.territoryPalavrasRarasLinguistica;
    case 'palavras_raras_historia':
      return l10n.territoryPalavrasRarasHistoria;
    case 'palavras_raras_geografia':
      return l10n.territoryPalavrasRarasGeografia;
    case 'palavras_raras_direito':
      return l10n.territoryPalavrasRarasDireito;
    case 'palavras_raras_eruditas':
      return l10n.territoryPalavrasRarasEruditas;
    case 'linguagem_crase':
      return l10n.territoryLinguagemCrase;
    case 'futebol_origens':
      return l10n.territoryFutebolOrigens;
    case 'futebol_grandes_nomes':
      return l10n.territoryFutebolGrandesNomes;
    case 'futebol_regras_curiosidades':
      return l10n.territoryFutebolRegrasCuriosidades;
    case 'futebol_atualidade':
      return l10n.territoryFutebolAtualidade;
    case 'financas_pessoais':
      return l10n.territoryFinancasPessoais;
    case 'filosofia':
      return l10n.territoryFilosofia;
    case 'artes':
      return l10n.territoryArtes;
    case 'saude_bemestar':
      return l10n.territorySaudeBemestar;
    case 'curiosidade_relampago':
      return l10n.territoryCuriosidadeRelampago;
    case 'libras':
      return l10n.territoryLibras;
    case 'caca_palavras':
      return l10n.territoryCacaPalavras;
    case 'invencoes':
      return l10n.territoryInvencoes;
    case 'veiculos':
      return l10n.territoryVeiculos;
    case 'astronomia':
      return l10n.territoryAstronomia;
    case 'detetive_mental':
      return l10n.territoryDetetiveMental;
    case 'ouvido_afiado':
      return l10n.territoryOuvidoAfiado;
    case 'ingles_basico':
      return l10n.territoryInglesBasico;
    case 'ingles_intermediario':
      return l10n.territoryInglesIntermediario;
    case 'ingles_avancado':
      return l10n.territoryInglesAvancado;
    case 'espanhol_basico':
      return l10n.territoryEspanholBasico;
    case 'espanhol_intermediario':
      return l10n.territoryEspanholIntermediario;
    case 'espanhol_avancado':
      return l10n.territoryEspanholAvancado;
    case 'frances_basico':
      return l10n.territoryFrancesBasico;
    case 'frances_intermediario':
      return l10n.territoryFrancesIntermediario;
    case 'frances_avancado':
      return l10n.territoryFrancesAvancado;
    case 'bolsa':
      return l10n.territoryBolsa;
    case 'criptomoedas':
      return l10n.territoryCriptomoedas;
    case 'cenario_global':
      return l10n.territoryCenarioGlobal;
    case 'financas_dia_a_dia':
      return l10n.territoryFinancasDiaADia;
    case 'educacao_legislacao':
      return l10n.territoryEducacaoLegislacao;
    case 'historia_curiosidades':
      return l10n.territoryHistoriaCuriosidades;
    case 'transportes_terrestres':
      return l10n.territoryTransportesTerrestres;
    case 'economia_transito':
      return l10n.territoryEconomiaTransito;
    case 'prevencao_seguranca':
      return l10n.territoryPrevencaoSeguranca;
    case 'gastro_mundo':
      return l10n.territoryGastroMundo;
    case 'gastro_brasil':
      return l10n.territoryGastroBrasil;
    case 'gastro_norte_nordeste':
      return l10n.territoryGastroNorteNordeste;
    case 'gastro_centrooeste_sudeste':
      return l10n.territoryGastroCentrooesteSudeste;
    case 'gastro_sul_fusao':
      return l10n.territoryGastroSulFusao;
    case 'oceano_mundo':
      return l10n.territoryOceanoMundo;
    case 'oceano_vida_marinha':
      return l10n.territoryOceanoVidaMarinha;
    case 'oceano_profundezas':
      return l10n.territoryOceanoProfundezas;
    case 'oceano_clima':
      return l10n.territoryOceanoClima;
    case 'oceano_brasil':
      return l10n.territoryOceanoBrasil;
    case 'espaco_universo':
      return l10n.territoryEspacoUniverso;
    case 'espaco_planetas':
      return l10n.territoryEspacoPlanetas;
    case 'espaco_estrelas':
      return l10n.territoryEspacoEstrelas;
    case 'espaco_exploracao':
      return l10n.territoryEspacoExploracao;
    case 'espaco_brasil':
      return l10n.territoryEspacoBrasil;
    default:
      return territoryId;
  }
}

/// Busca na Home por "tema" (pedido de Rhoney, 2026-09-03) — resolvida
/// aqui no client, não no backend: territories.dart já tem o mapa
/// id→label localizado, então bater a busca contra a label é mais
/// barato e correto aqui do que duplicar tradução no servidor. Match
/// por trecho literal (case-insensitive) em qualquer direção — cobre
/// tanto "astronomia" quanto "astro" ou o nome completo digitado.
/// Retorna null quando nada bate (o client então tenta a busca de
/// frase/palavra no backend, GET /challenges/search).
String? findTerritoryIdByThemeQuery(AppLocalizations l10n, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return null;
  for (final territoryId in kTerritoryIds) {
    final label = territoryLabel(l10n, territoryId).toLowerCase();
    if (label.contains(needle) || needle.contains(label)) {
      return territoryId;
    }
  }
  return null;
}
