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
    default:
      return territoryId;
  }
}
