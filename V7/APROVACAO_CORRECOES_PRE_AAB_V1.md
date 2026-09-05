# MENTAL — Aprovação de Correções Pré-AAB (Auditoria de Segurança)

**Status:** APROVADO PARA IMPLEMENTAÇÃO IMEDIATA. O Claude Code está autorizado a corrigir os itens abaixo, na ordem especificada, antes de qualquer novo AAB ser gerado.
**Documento de origem:** Relatório de auditoria pré-AAB (PoC real executado e removido, suíte backend 310/310 passando antes da auditoria).
**Regra geral:** Nenhum item desta lista deve ser corrigido "por cima" — a causa raiz de cada um já foi identificada no relatório de origem; a correção deve atacar exatamente essa causa, não sintoma. Rodar a suíte completa após cada correção, confirmando que continua 100% verde antes de passar para o próximo item.

---

## 1. Itens que BLOQUEIAM o AAB — corrigir primeiro, sem exceção

### 1.1 C1 — Oráculo de respostas via `/challenges/{id}/reattempt`
**Aprovado.** Exigir que o endpoint de revisão só sirva `correct_answer`/`explanation` quando existir, de fato, um `Attempt` anterior deste `user_id` neste `challenge_id` com `is_correct is False` (idealmente, da rodada corrente). Se essa condição não for satisfeita, o endpoint deve recusar a requisição, não servir a resposta de qualquer forma.
- Cobrir com teste automatizado explícito o caso "reattempt em challenge nunca servido a este usuário" — o relatório confirma que os testes existentes não cobrem esse caminho.
- Confirmar que o mesmo bloqueio fecha também os dois vetores de amplificação já identificados: `/battles/{id}/my-challenge` (oráculo aplicado a Batalha) e `/challenges/search` (escolha dirigida de desafio).

### 1.2 A1 — Bloqueio de usuário não vale para Perfil Público nem Torcida
**Aprovado.** Aplicar `services.is_blocked_either_way()` — a mesma função já corretamente usada em `request_friendship`, `accept_friend_request` e `search_users_by_name` — também em `get_public_profile` e em `send_torcida`. Nenhuma lógica nova precisa ser criada; é reaproveitar a função já validada nos três outros pontos.
- Critério de aceite: após o bloqueio, a parte bloqueada não deve conseguir abrir o perfil público da vítima nem enviar Torcida a ela, em nenhum dos dois sentidos do bloqueio.

## 2. Item obrigatório antes do AAB — configuração de build

### 2.1 M5 — Configuração de build Android para release
**Aprovado**, com as seguintes ações:
- `android:allowBackup="false"` no `AndroidManifest.xml` principal (hoje ausente, cai no default `true`, expondo token de sessão via backup automático — risco de LGPD).
- Ativar `isMinifyEnabled`/`isShrinkResources` no `buildTypes.release` (R8), reduzindo tamanho do AAB e dificultando engenharia reversa da API.
- Declarar `android.permission.INTERNET` explicitamente no manifest `main/` (hoje só existe em `debug/` e `profile/`), e confirmar no manifest mesclado do build de release que a permissão está presente antes de subir.
- O build de release deve **falhar explicitamente** se `key.properties` não existir, em vez de cair silenciosamente para a keystore de debug — um AAB assinado com chave errada só seria percebido tarde demais, na submissão à loja.

## 3. Pacote de correções médias — mesma leva, mesma área de código já em foco

### 3.1 M1 — Ausência de rate limiting e cap de `MovementSnapshot`
**Aprovado.** Implementar rate limiting básico por `user_id` (mesmo que simples) nos endpoints de recompensa/pontuação, priorizando os que já compõem os vetores de C1. Adicionar teto de sanidade na gravação de `MovementSnapshot` em `collect_steps`, hoje incondicional antes de qualquer clamp.

### 3.2 M2 — Conclusão de Caça-palavras e Pausa para Aprender sem prova mínima
**Aprovado.** Adicionar piso de tempo mínimo plausível (`elapsed_ms` mínimo, análogo ao `MOVEMENT_MAX_STEPS_PER_CYCLE` já usado em Movimento) tanto em `/word-puzzles/{result_id}/complete` quanto em `/learning-pauses/{id}/complete`.

### 3.3 M4 — Campos de texto livre sem teto de tamanho
**Aprovado.** Adicionar `Field(max_length=...)` em `AnswerRequest.submitted_answer`, cap de itens/tamanho em `WordPuzzleCompleteRequest.found_words`, e `max_length` no parâmetro `q` de `/challenges/search`. Também corrigir `find_challenge_by_search` para escapar `%`/`_` no `ilike`, seguindo o mesmo padrão já correto de `search_users_by_name`.

## 4. Itens de menor urgência — corrigir nesta leva se o tempo permitir, senão registrar como pendência explícita

- **M3** — padronizar `award_share_reward` e `award_app_invite_reward` para usar `utcnow().date()`, como o resto do projeto, eliminando a dependência do fuso local do servidor.
- **B1** — resolver a inconsistência entre datetime naive/aware em `_checkpoint_bonus` (movement.py:60-68), decidindo num sentido ou no outro, e confirmando contra o Postgres real de produção (não apenas SQLite de teste).
- **B2** — documentar `content_suggestions` como terceira exceção deliberada à cascata de exclusão de conta (`ON DELETE SET NULL`), atualizando a docstring de `services.delete_account` que hoje lista apenas duas exceções.

## 5. Fora de escopo desta rodada (registrado, não bloqueia)

- B3 (resíduo de `parental_gate`), B4 (funções/módulos grandes demais) e B5 (inconsistência de dependência em endpoints admin) — auditoria já classificou como itens de limpeza, adiáveis para depois do lançamento. Não fazem parte desta aprovação.

## 6. Ordem de execução obrigatória

1. C1
2. A1
3. M5
4. M1, M2, M4 (podem ser feitos em conjunto, mesma área de código)
5. M3, B1, B2 (se o tempo permitir nesta rodada)

## 7. Critério de aceite geral

- Suíte de testes completa (backend) passando a 100% após cada item corrigido, não apenas ao final de todos.
- C1 e A1 confirmados com teste automatizado específico cobrindo exatamente o cenário de exploração descrito na auditoria — não apenas a ausência de erro, mas a confirmação de que o vetor está de fato fechado.
- Nenhum AAB deve ser gerado para submissão antes de C1, A1 e M5 estarem corrigidos e validados.
