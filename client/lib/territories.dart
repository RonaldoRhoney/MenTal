import 'l10n/generated/app_localizations.dart';

/// Ids dos 4 territórios do V1 — compartilhado entre Home, Progress e
/// Challenge para não duplicar a lista nem o mapeamento id→label.
const List<String> kTerritoryIds = [
  'palavras',
  'numeros',
  'logica',
  'conhecimento',
  'enigmas',
  'textos',
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
    default:
      return territoryId;
  }
}
