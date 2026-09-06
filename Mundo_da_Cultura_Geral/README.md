# Mundo da Cultura Geral

**Status:** Em produção. Territórios: `esportes`, `regioes`, `cultura_pop`,
`mitologia_grega`, `mitologia_nordica`, `mitologia_indigena`,
`enem_linguagens`, `enem_humanas`, `enem_natureza`, `enem_matematica`,
`concursos_portugues`, `concursos_raciocinio`, `concursos_direito`,
`tecnologia_fundamentos`, `tecnologia_programacao`,
`tecnologia_seguranca`, `tecnologia_fronteira`, `financas_pessoais`,
`filosofia`, `artes`, `saude_bemestar`, `curiosidade_relampago`,
`libras`, `caca_palavras` (`app/seed.py`, World `cultura_geral`).

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

Conteúdo de produção (`backend/content/`) e migrations
(`backend/migrations/`) permanecem nos diretórios padrão do backend —
só a documentação de arquitetura/curadoria foi reorganizada aqui.
