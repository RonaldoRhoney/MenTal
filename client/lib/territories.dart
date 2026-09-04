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
  // V3.0 (U.I/../V3/V3.0_ESPORTES_REGIOES_CULTURA_POP.md).
  'esportes',
  'regioes',
  'cultura_pop',
  // V3.0.1 (U.I/../V3/V3.0.1_DESAFIO_CORES.md).
  'cores',
  // V3.1 (U.I/../V3/V3.1_MITOLOGIA_ENEM_CONCURSOS.md).
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
  // V3.2 (U.I/../V3/V3.2_TECNOLOGIA.md).
  'tecnologia_fundamentos',
  'tecnologia_programacao',
  'tecnologia_seguranca',
  'tecnologia_fronteira',
  // V3.3 (U.I/../V3/V3.3_VIDA_PRATICA_PENSAMENTO.md).
  'financas_pessoais',
  'filosofia',
  'artes',
  'saude_bemestar',
  // V3.5 (U.I/../V3/V3.5_CURIOSIDADE_RELAMPAGO.md).
  'curiosidade_relampago',
  // V3.4 (U.I/../V3/V3.4_LIBRAS.md).
  'libras',
  // V3.3 §6 (V3.3_VIDA_PRATICA_PENSAMENTO.md) — Jogos de Palavras.
  'caca_palavras',
  // V4 (V4/V4_NOVOS_TERRITORIOS.md §1-5).
  'invencoes',
  'veiculos',
  'astronomia',
  'detetive_mental',
  'ouvido_afiado',
  // V5 (V5/README.md) — Mundo dos Idiomas.
  'ingles_basico',
  'ingles_intermediario',
  'ingles_avancado',
  'espanhol_basico',
  'espanhol_intermediario',
  'espanhol_avancado',
  'frances_basico',
  'frances_intermediario',
  'frances_avancado',
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
