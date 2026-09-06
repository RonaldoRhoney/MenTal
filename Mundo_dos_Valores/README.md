# Mundo dos Valores (V6)

**Status:** Em andamento (iniciada em 05/09/2026). Mundo dos Valores —
educação financeira/economia, nunca aconselhamento de investimento (ver
`FOUNDATION/POLITICA_CONTEUDO_SEGURO_QUALQUER_IDADE.md` e o campo
`meta.principio` de cada arquivo `mundo_dos_valores_*.json` desta pasta).

## Arquitetura implementada em 05/09/2026

Decisão confirmada com Rhoney: o formato "cápsula de texto + perguntas"
(sem timer, sem Relâmpago, sem penalidade de velocidade) reaproveita
100% o `Challenge` normal em vez de criar uma mecânica nova —
mesma infraestrutura já auditada (scoring, streak, badges, conquista de
território, rate limiting, etc.), zero telas novas.

- **Novo World**: `valores` (Mundo dos Valores), display_order 6.
- **4 territórios** (migration `063_mundo_valores.sql`): `bolsa`,
  `criptomoedas`, `cenario_global`, `financas_dia_a_dia` — cada
  "pergunta" de uma cápsula vira um `Challenge` normal (difficulty_level
  fixo em 1, é checagem de compreensão de leitura, não trilha de
  maestria por nível — mesmo raciocínio já usado nos territórios de
  idiomas, ver `SINGLE_DIFFICULTY_TERRITORY_IDS`).
- **Novo campo** `Challenge.reading_passage` (nullable, `None` em todo o
  resto do app): o texto da cápsula, mostrado no client ANTES da
  pergunta (mesmo espírito de `clues`/`audio_url` de Detetive Mental/
  Ouvido Afiado). Reaproveitado também como `explanation` (mostrado
  DEPOIS de responder) — os arquivos fonte não têm um campo de
  explicação próprio, só o texto da cápsula.
- **Nunca cronometrado, mesmo com `mode=relampago`**: os 4 territórios
  entram em `config.NEVER_TIMED_TERRITORY_IDS` (oposto de
  `ALWAYS_TIMED_TERRITORIES`) — o backend ignora o pedido do client,
  nunca confia nele pra decidir isso (mesmo princípio de segurança já
  aplicado em C1/A1 da auditoria pré-AAB). O client também não oferece
  o botão "Relâmpago" pra esses territórios (`kNeverTimedTerritoryIds`,
  `client/lib/territories.dart`).
- **Conteúdo**: 159 desafios (36 Bolsa, 48 Criptomoedas, 24 Cenário
  Global, 51 Finanças do Dia a Dia), convertidos de
  `mundo_dos_valores_*.json` (formato bruto: cápsulas com texto +
  perguntas) via `backend/scripts/convert_valores_content.py` — hints
  gerados automaticamente (nunca entregam a resposta, mesmo padrão já
  usado em `convert_idiomas_content.py`), carregados direto de
  `backend/content/valores_*.json` no `seed.py` (nunca duplicados
  inline, mesmo padrão de idiomas).
- Testes: `backend/tests/test_valores_content.py` (territórios, campo
  `reading_passage`, nunca cronometrado mesmo com `mode=relampago`,
  fluxo de resposta normal) + `client/test/challenge_screen_regression_test.dart`
  (reading_passage exibido antes da pergunta). Suíte backend: 334/334.
  Suíte client: 133/133.

## Deploy em produção (05/09/2026) — concluído

- Migration `063_mundo_valores.sql` rodada em produção (Supabase).
- `scripts/append_production_content.py` rodado com os 4 arquivos
  `content/valores_*.json` — 159/159 desafios inseridos (36 Bolsa, 48
  Criptomoedas, 24 Cenário Global, 51 Finanças do Dia a Dia), 0
  pulados.
- Teste em dispositivo real (release + reinstalação local):
  "Mundo dos Valores" aparece na Home com os 4 territórios; abriu
  desafio de Bolsa e Investimentos; `reading_passage` mostrado ANTES da
  pergunta, sem timer/Relâmpago; resposta certa concedeu XP
  normalmente (10 XP) e mostrou a explicação (mesmo texto da cápsula);
  território marcado "Você é o detentor" após acerto; logcat sem
  exceção do app.
- Achado durante o teste em dispositivo (05/09/2026, pedido de Rhoney):
  pergunta+alternativas exigiam rolar a tela quando a cápsula de texto
  era longa — corrigido dando altura máxima com rolagem própria ao
  `reading_passage`, deixando pergunta/alternativas/botão sempre
  visíveis abaixo. Também corrigido, no mesmo teste, um overflow real
  (mascarado em builds release) no card "Mais" da Home, e adicionada
  uma seta indicando "há mais Mundos abaixo" na lista da Home.

## Pendências

- Ícone/cor de identidade visual do Mundo dos Valores na Home (ainda
  não decidido).

## Próximo passo

V6 considerada concluída (conteúdo em produção + validado em
dispositivo real). Falta só decidir o ícone/cor do Mundo dos Valores.
Próxima prioridade a decidir com Rhoney: `MUNDO_LINGUAGEM_CONTEUDO_
DENSO_V1.md`, `FEED_SOCIAL_V1.md` ou V7 (Mundo do Trânsito, conteúdo já
presente em `Mundo_do_Transito/`).
