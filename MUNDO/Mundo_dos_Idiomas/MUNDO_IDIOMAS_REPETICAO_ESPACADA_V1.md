# MENTAL — Mundo dos Idiomas: Sistema de Repetição Espaçada

**Status:** APROVADO. Prioridade 1 das lacunas identificadas na análise de completude do Inglês (29/09/2026) — maior impacto pedagógico, reaproveita todo o conteúdo já existente sem exigir produção de conteúdo novo. Aplica-se a todos os idiomas do Mundo dos Idiomas, não é exclusivo ao Inglês.

---

## 1. Objetivo

Implementar um mecanismo de revisão espaçada (spaced repetition) que traga de volta, em intervalos crescentes, palavras/expressões/conceitos que o usuário já estudou — especialmente os que ele errou — em vez de deixar todo o conteúdo já visto ficar esquecido após ser completado uma única vez. Este é o mecanismo central por trás da retenção de longo prazo em apps de referência do mercado (Duolingo, Anki, Memrise).

## 2. Princípio de funcionamento

- Cada item de vocabulário/gramática/expressão que o usuário encontra (em qualquer Desafio, Relâmpago, ou interação futura) recebe um registro individual de "força de memória" para aquele usuário específico.
- Itens **errados** ou respondidos com hesitação (ex.: uso de dica) reaparecem em intervalo **mais curto**; itens **acertados com confiança** reaparecem em intervalo **mais longo**, crescendo progressivamente a cada acerto consecutivo (ex.: 1 dia → 3 dias → 1 semana → 1 mês, ajustável).
- A cada nova sessão de revisão, o sistema seleciona automaticamente os itens "vencidos" (cujo intervalo de revisão já passou), sem exigir que o usuário lembre manualmente o que precisa rever.

## 3. Onde aparece para o usuário

- Uma seção própria (ex.: "Revisão" ou "Praticar novamente"), populada automaticamente pelo algoritmo — não uma lista estática, e sim dinâmica, mudando conforme o desempenho e o tempo decorrido.
- Reaproveita o formato de pergunta já existente para cada tipo de conteúdo (vocabulário, phrasal verbs, expressões idiomáticas etc.) — a revisão não precisa de uma UI nova, só de uma lógica de seleção nova sobre o conteúdo já existente.

## 4. Escopo técnico (a propor em detalhe por Claude Code)

- Modelar a estrutura de dados de "força de memória" por usuário e por item de conteúdo (histórico de acertos/erros, data da última revisão, próximo intervalo calculado).
- Propor o algoritmo de cálculo de intervalo (referências de mercado usam variações do algoritmo SM-2 do Anki, ou lógicas mais simples de dobrar o intervalo a cada acerto — Claude Code deve avaliar a complexidade adequada ao estágio atual do MENTAL).
- Confirmar que o sistema funciona de forma agnóstica a Mundo/idioma — deve funcionar igualmente para o Mundo dos Idiomas, o Mundo da Linguagem, e qualquer outro Mundo que faça sentido no futuro, não como algo hardcoded apenas para Inglês.
- Avaliar custo computacional de manter esse histórico por usuário em escala, dado que o projeto roda hoje em infraestrutura de custo controlado.

## 5. Integração com gamificação

- Concluir uma sessão de revisão espaçada deve gerar recompensa, a ser formalizada como atualização da Regra Oficial de Gamificação antes de entrar em produção — não implementar recompensa nova sem essa formalização prévia, conforme o princípio de governança já estabelecido naquele documento.

## 6. Critério de aceite

- Itens errados ou revisados com dica reaparecem em intervalo mais curto que itens acertados com confiança.
- Intervalo de revisão cresce progressivamente a cada acerto consecutivo do mesmo item.
- Seção de revisão é populada dinamicamente, refletindo o estado real de memória do usuário, não uma lista fixa.
- Sistema funciona de forma agnóstica a idioma e a Mundo, pronto para reaproveitar em qualquer conteúdo futuro do MENTAL.

## 7. Status de implementação (02/10/2026)

**Backend concluído e testado, aguardando migration em produção. Tela/seção
"Revisão" no client e a recompensa de sessão de revisão (§5 acima) ficam
para depois** — decisão de escopo de Rhoney (02/10/2026): backend completo
primeiro, sem UI ainda, dado que a recompensa de sessão exige formalização
prévia da Regra Oficial de Gamificação antes de entrar em produção.

**Algoritmo**: schedule fixo crescente (Leitner-like), não o SM-2 completo
do Anki com fator de facilidade por item — avaliado como complexidade
excessiva pro estágio atual (§4 pede essa avaliação explicitamente).
`SPACED_REPETITION_SCHEDULE_DAYS = [1, 3, 7, 14, 30, 60]` dias. Acerto sem
dica avança `repetitions` e usa o próximo intervalo (satura no último
valor); erro OU uso de dica reseta `repetitions=0` (intervalo volta a 1
dia).

**Modelo de dado**: `SpacedRepetitionItem` (user_id, challenge_id) —
agnóstico a Mundo/território desde o início (chave é challenge_id, nunca
hardcoded pra Inglês/Idiomas); `territory_id` é só desnormalizado.
Alimentado automaticamente em TODO desafio respondido no app inteiro (não
só Idiomas), dentro de `submit_answer` — nunca em `REGRA_REVISAO_ERROS_
FIM_RODADA.md` (revisão imediata de fim de rodada é um mecanismo separado).

**Endpoints**: `GET /challenges/review/next` (serve o item vencido mais
atrasado, mesma autoridade de `GET /challenges/next`) e `GET /challenges/
review/count` (contagem pra badge, sem servir nada). Migration 116
(`backend/migrations/116_spaced_repetition.sql`): nova tabela
`spaced_repetition_items` + coluna `attempts.is_spaced_review`.

**Auditoria de segurança (mental-security, 02/10/2026)** — 1 achado
CRÍTICO e 2 ALTO corrigidos antes deste commit:
- CRÍTICO: `GET /challenges/review/next` servia um Attempt NOVO a cada
  chamada pro MESMO item vencido, e o bônus de lote (+3/+5 XP) é pago por
  attempt_id — farm de XP ilimitado chamando o endpoint em loop sem
  responder nada. Corrigido com `Attempt.is_spaced_review` (excluído do
  bônus de lote em `rewards.on_batch_completed`, mesmo tratamento de
  `is_search`) + reaproveitamento do attempt_id pendente em vez de servir
  de novo o mesmo item.
- ALTO: os dois endpoints novos não tinham rate limit — adicionado
  (`RATE_LIMIT_SPACED_REVIEW_NEXT`/`_COUNT`, mesma janela generosa de
  `RATE_LIMIT_SEARCH`).
- ALTO: o gancho em `submit_answer` não estava protegido contra erro
  (risco real de deploy antes da migration rodar em produção) — envolvido
  em `rewards.safely`; `update_spaced_repetition` agora faz upsert seguro
  contra corrida (mesmo padrão de `rewards.try_claim`).
- MÉDIO (2): território bloqueado apagava o item de memória (agora só
  pula, nunca apaga) e a checagem de desbloqueio usava o território
  desnormalizado no item em vez do território ATUAL do desafio (agora
  checa `challenge.territory_id`).
- Achados BAIXO não corrigidos agora (documentados, sem risco de
  segurança): `due_count` pode contar itens de território bloqueado (pequena
  imprecisão de badge); território sempre servido sem cronômetro na
  revisão, mesmo pra territórios `ALWAYS_TIMED_TERRITORIES`; duplicação de
  4 cópias da construção de `ChallengeOut` em `challenges.py` (já existia
  antes desta entrega, não é regressão).

**Testes**: 14 testes novos em `tests/test_spaced_repetition.py` (schedule,
dica, erro, ordenação por mais atrasado, contagem, XP normal não-zero,
isolamento do reattempt, farm de XP via chamadas repetidas, bônus de lote
não aplicado, território bloqueado pula sem apagar, isolamento entre
usuários, limite diário). Suíte completa do backend: 597/597.

**Pendência pra Rhoney**: rodar `backend/migrations/116_spaced_repetition.sql`
em produção ANTES do deploy do código novo (o gancho em `submit_answer` é
protegido por `rewards.safely`, então não quebra a resposta mesmo se a
migration ainda não tiver rodado, mas o sistema de revisão simplesmente não
funciona até lá).
