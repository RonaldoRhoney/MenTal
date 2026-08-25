# MENTAL — Feedback Pós-Nível

**Status:** Aprovado para implementação.
**Documentos relacionados:** DESIGN_SYSTEM.md

---

## 1. Conceito

Ao final de cada nível concluído (em qualquer território), o usuário responde uma tela rápida de feedback. O objetivo é coletar dado de opinião pra uso futuro (incremento de produto) — **não afeta o algoritmo de dificuldade adaptativa já existente** (`hint_penalty_factor`), nem qualquer outra mecânica do jogo. É puramente informativo/qualitativo.

---

## 2. Estrutura da tela

**Bloco 1 — Ação:**
- "Repetir este nível" — permite refazer o mesmo nível.
- "Seguir em frente" — avança pro próximo nível, comportamento já existente hoje.

**Bloco 2 — Avaliação de dificuldade (múltipla escolha, 1 toque):**
- Fácil
- Médio
- Difícil
- Muito difícil

**Bloco 3 — Comentário livre (opcional):**
- Caixa de texto aberta, abaixo das opções de dificuldade, para o usuário deixar qualquer observação adicional em texto livre.
- Campo opcional — não bloqueia o envio do feedback se deixado em branco.

---

## 3. Regras

- Aparece **sempre que um nível é concluído**, em qualquer território.
- Resposta rápida — 1 toque por bloco de escolha, sem fricção; comentário é o único campo que exige digitação, e é opcional.
- Dado é armazenado associado a usuário, território e nível — para análise futura.
- **Visível no painel administrativo**, restrito à conta admin (`rhoneyinc@gmail.com`) — mesmo escopo já registrado em ADMIN_PANEL_E_CREDITO_INSTITUCIONAL.md (somente leitura, role=admin). Serve de base para decisões futuras de produto e para eventuais declarações no Google Play Console (ex.: Data Safety).
- **Não altera nenhuma mecânica do jogo hoje** (XP, dificuldade adaptativa, progressão) — é coleta pura, uso é decisão futura do produto.
- Tom visual consistente com DESIGN_SYSTEM.md — não deve parecer formulário burocrático.

---

## 4. Escopo técnico (alto nível — arquitetura detalhada a propor por Claude Code)

- Nova tabela simples de feedback (usuário, território, nível, ação escolhida, avaliação de dificuldade, comentário livre, timestamp) — ou campo agregado em estrutura já existente, a critério de Claude Code.
- "Repetir este nível" precisa de fato permitir refazer o mesmo nível; "Seguir em frente" mantém o comportamento padrão já existente.
- Comentário de texto livre: aplicar mesmo cuidado de moderação já usado em outros campos de texto do usuário no MENTAL, caso haja exibição pública futura (hoje é só armazenamento interno, sem exibição a outros usuários).
- Dado precisa ser consultável pelo painel administrativo (mesmo escopo de ADMIN_PANEL_E_CREDITO_INSTITUCIONAL.md) — se o painel ainda não existir implementado, ao menos a estrutura de dado deve estar pronta para consulta futura (ex.: endpoint read-only restrito a admin, ou consulta direta ao banco por enquanto).

---

## 5. Fora de escopo agora

- Implementação completa do painel administrativo em si (interface visual) — isso é o escopo maior já registrado em ADMIN_PANEL_E_CREDITO_INSTITUCIONAL.md, não prioritizado. Aqui, o requisito é garantir que o dado fique estruturado e acessível para quando o painel for implementado.
- Uso desse dado para ajustar dificuldade automaticamente — decisão futura, não faz parte desta implementação.
- Exibição do feedback de um usuário para outros usuários — dado é interno/privado por padrão.
