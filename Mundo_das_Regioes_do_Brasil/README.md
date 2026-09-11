# Mundo das Regiões do Brasil

**Status:** Em produção, parcial. Território atual: `regioes`
(`app/seed.py`, World `regioes_brasil`) — mas ver "Pendência" abaixo,
este Mundo ainda não tem os territórios por região que o documento
original pede.

Criado em 07/09/2026 via `DESMEMBRAMENTO_CULTURA_GERAL_V1.md` §3 (raiz
do repo). Diferente dos demais Mundos desmembrados da Cultura Geral,
este não é uma renomeação simples: o documento pede que as **cinco
regiões do Brasil (Norte, Nordeste, Centro-Oeste, Sudeste, Sul) sejam
o contexto organizador**, cada uma um território próprio dentro do
Mundo, reunindo curiosidades/geografia/cultura específicas daquela
região.

## Achado real na investigação (07/09/2026)

O território `regioes` já existente (15 perguntas, curadas em
`V3.0_ESPORTES_REGIOES_CULTURA_POP.md`) é sobre **gírias e expressões
regionais** ("qual região usa a expressão X") — perguntas que misturam
todas as regiões, não conteúdo dividido por região. Não dava pra
simplesmente "renomear" esse território pras 5 regiões sem perder
sentido nem recurar do zero.

**Decisão de Rhoney (07/09/2026)**: manter as 15 perguntas como
território próprio dentro deste Mundo, renomeado **"Gírias e
Expressões"** (`l10n.territoryRegioes`, id continua `regioes` — nenhum
dado de progresso/XP é perdido). Os 5 territórios de região (um por
região, curadoria de curiosidades/geografia/cultura específicas) ficam
como pendência — a estrutura do Mundo já está pronta pra recebê-los
quando curados.

## Pendência

- Curar conteúdo de 5 novos territórios (Norte, Nordeste, Centro-Oeste,
  Sudeste, Sul) e integrá-los a este Mundo — mesmo passo a passo já
  usado em Valores/Trânsito (migration + `seed.py` + client).
