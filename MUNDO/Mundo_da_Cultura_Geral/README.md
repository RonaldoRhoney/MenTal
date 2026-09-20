# Mundo da Cultura Geral

**Status:** Em produção. Desmembrado em 07/09/2026
(`DESMEMBRAMENTO_CULTURA_GERAL_V1.md`, nesta pasta) — reunia
territórios de naturezas muito diferentes num único balaio genérico.
Territórios que **permanecem** aqui: `cultura_pop`, `filosofia`,
`artes`, `saude_bemestar`, `curiosidade_relampago`, `caca_palavras`
(`app/seed.py`, World `cultura_geral`).

Territórios que **migraram** pra Mundos próprios: `esportes` →
`Mundo_dos_Esportes/`, `regioes` → `Mundo_das_Regioes_do_Brasil/`,
mitologia (3 territórios) → `Mundo_da_Mitologia/`, ENEM (4) →
`Mundo_do_ENEM/`, Concursos (3) → `Mundo_dos_Concursos/`, Tecnologia
(4) → `Mundo_da_Tecnologia/`. `libras` migrou pra `Mundo_dos_Idiomas/`
e `financas_pessoais` pra `Mundo_dos_Valores/` (Mundos já existentes
que combinam melhor com eles). Pura reorganização de agrupamento —
nenhum conteúdo foi alterado/removido, nenhum XP/progresso afetado.

Docs de conteúdo/arquitetura movidos pra esta pasta em 06/09/2026
(pedido de Rhoney) — antes soltos em V3, organização espelhando os
Mundos da Home do app (mesmo padrão já usado em `Mundo_dos_Idiomas/`,
`Mundo_dos_Valores/`, `Mundo_da_Linguagem/`). Os 5 territórios que
originalmente também viviam aqui (Invenções, Veículos, Ouvido Afiado,
Detetive Mental, Astronomia) foram desmembrados pra `Mundo_da_Descoberta/`
ainda na V4 — ver aquela pasta.

- `V3.0_ESPORTES_REGIOES_CULTURA_POP.md` (V3, fase 1) — Esportes,
  Regiões, Cultura Pop.
- `V3.1_MITOLOGIA_ENEM_CONCURSOS.md` (V3, fase 2) — Mitologia
  (grega/nórdica/indígena), ENEM (4 áreas), Concursos (3 áreas).
- `V3.2_TECNOLOGIA.md` (V3, fase 3) — Tecnologia em profundidade (4
  territórios); introduz a mecânica "Pausa para Aprender".
- `V3.3_VIDA_PRATICA_PENSAMENTO.md` (V3, fase 4) — Finanças Pessoais,
  Filosofia, Artes, Saúde e Bem-estar.
- `V3.4_LIBRAS.md` (V3, fase 5) — Libras, conteúdo rico + player de
  vídeo institucional.
- `V3.5_CURIOSIDADE_RELAMPAGO.md` (V3) — bloco Curiosidade Relâmpago.
- `DESMEMBRAMENTO_CULTURA_GERAL_V1.md` (07/09/2026) — spec e execução
  do desmembramento em 6 Mundos temáticos descrito acima. Movido pra
  esta pasta em 11/09/2026 (antes solto na raiz do repo).

Conteúdo de produção (`backend/content/`) e migrations
(`backend/migrations/`) permanecem nos diretórios padrão do backend —
só a documentação de arquitetura/curadoria foi reorganizada aqui.
