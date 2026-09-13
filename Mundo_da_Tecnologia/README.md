# Mundo da Tecnologia

**Status:** Em produção. Territórios: `tecnologia_fundamentos`,
`tecnologia_programacao`, `tecnologia_seguranca`,
`tecnologia_fronteira` (`app/seed.py`, World `tecnologia`, agrupados
sob o bloco de menu `tecnologia`).

Criado em 07/09/2026 via `DESMEMBRAMENTO_CULTURA_GERAL_V1.md` (raiz do
repo) — os 4 territórios saíram do Mundo da Cultura Geral (que reunia
territórios de naturezas muito diferentes) e ganharam Mundo próprio.
Conteúdo original curado em `V3.2_TECNOLOGIA.md` (ver
`Mundo_da_Cultura_Geral/`), que também introduziu a mecânica "Pausa
para Aprender" — pura reorganização de agrupamento, nenhum desafio foi
alterado/removido, nenhum XP/progresso afetado.

## SubMundo: Internet

`ARQUITETURA_SUBMUNDOS_V1.md` (13/09/2026, aprovado): "Internet" entra
como **SubMundo** deste Mundo, não como Mundo próprio — taxonomicamente
é um subconjunto de Tecnologia. Conteúdo bruto de curadoria em
`Internet/` (formato "meta + saiba_mais + perguntas", trilha por
dificuldade 1-4, diferente do formato "cápsula de texto" usado nos
territórios clássicos acima).

Implementado reaproveitando o Bloco já existente (`BLOCOS_MENUS.md`) em
vez de criar uma entidade "SubMundo" nova: os territórios de Internet
têm `world_id="tecnologia"` (mesmo Mundo) e `block_id="internet"`
(bloco próprio, diferente do `block_id="tecnologia"` dos 4 territórios
clássicos) — isso já basta pra aparecerem sob um subcabeçalho "Internet"
separado dentro da tela do Mundo Tecnologia (`home_screen.dart`, sem
nenhuma mudança de client). Territórios prontos hoje:
`internet_origens`, `internet_sistemas_operacionais`
(`scripts/convert_internet_content.py` BLOCO_TO_TERRITORY) — os demais
blocos curados (Os Gigantes da Internet, Cultura de Internet, Passado/
Presente/Futuro) entram como territórios novos assim que a curadoria de
cada um terminar.
