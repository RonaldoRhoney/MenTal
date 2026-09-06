# Mundo da Descoberta

**Status:** Em produção. Territórios: `invencoes`, `veiculos`,
`astronomia`, `detetive_mental`, `ouvido_afiado` (`app/seed.py`, World
`descoberta`).

Docs de conteúdo/arquitetura movidos pra esta pasta em 06/09/2026
(pedido de Rhoney) — antes soltos em V4, organização espelhando os
Mundos da Home do app (mesmo padrão já usado em `Mundo_dos_Idiomas/`,
`Mundo_dos_Valores/`, `Mundo_da_Linguagem/`). Este Mundo nasceu na V4
como desmembramento do Mundo da Cultura Geral, que tinha ficado extenso
demais pro usuário navegar.

- `V4_NOVOS_TERRITORIOS.md` — os cinco blocos de conteúdo originais
  (Invenções, Veículos, Ouvido Afiado, Detetive Mental, Astronomia),
  rollout sequencial igual ao usado na V3.
- `PROMPT_CLAUDE_CODE_MUNDO_DESCOBERTA.md` — pedido original de Rhoney
  pra desmembrar esses 5 territórios do Mundo da Cultura Geral e criar
  este Mundo próprio.

Conteúdo de produção (`backend/content/`) e migrations
(`backend/migrations/`) permanecem nos diretórios padrão do backend —
só a documentação de arquitetura/curadoria foi reorganizada aqui.
