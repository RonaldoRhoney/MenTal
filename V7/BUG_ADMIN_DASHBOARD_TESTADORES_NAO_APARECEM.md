# MENTAL — Bug: Admin Dashboard não reflete testadores ativos (Amigos/Progresso/Ranking)

**Status:** ENCERRADO em 05/09/2026 — investigação concluída, sem bug de dado confirmado no Painel Admin in-app.
**Tipo:** Investigação de bug — causa raiz desconhecida, não presumir a causa antes de investigar.

## Conclusão da investigação (05/09/2026)

Comparação direta entre o Painel Admin (`GET /admin/metrics/summary`, aba "7 dias") e queries diretas no Postgres de produção (Supabase SQL Editor):

| Métrica | Painel Admin | Query direta no banco |
|---|---|---|
| Novos cadastros (7d) | 6 | 6 (`select count(*) from mental.profiles where created_at >= now() - interval '7 days'`) |
| Fizeram alguma ação (7d) | 17 | 17 (`select count(distinct user_id) from mental.attempts where created_at >= now() - interval '7 days'`) |

Os números batem exatamente — o painel reflete o banco em tempo real, sem cache, sem filtro indevido. `auth.users` (34) vs `mental.profiles` (32) tem um gap pequeno (2 contas autenticadas sem perfil criado ainda), não uma divergência em massa. Rhoney confirmou que a percepção de "dado desatualizado" não correspondia a nenhum testador específico ausente — investigação encerrada sem correção de código necessária no Painel Admin.

**Nota**: esta investigação NÃO cobriu as telas normais do app (Amigos/Progresso/Ranking como o jogador comum vê, fora do Painel Admin) — essas já tinham sido avaliadas antes como comportamento esperado (Amigos exige pedido aceito; Progresso é sempre self-only por design; Ranking global usa janela semanal fixa no client, sem toggle "todo período"), exceto o achado secundário de que `Profile.last_seen_at` só é atualizado dentro de `GET /progress` — isso ainda vale como observação registrada, não corrigido, mas não impacta as métricas de "engajamento" (`Attempt.created_at`) usadas no Painel Admin, só as métricas de "ativos" (`last_seen_at`).

---

## 1. Descrição do problema

Rhoney reporta que várias pessoas estão entrando no teste fechado e usando o app, mas o Admin Dashboard não está refletindo essa atividade real. Especificamente:
- A área de **Amigos** não está mostrando os novos usuários/testadores.
- A área de **Progresso** não está mostrando a atividade desses usuários.
- A pontuação (XP/score) dessas pessoas não está aparecendo em nenhum lugar do painel.

Isso é uma divergência entre o que está acontecendo de fato em produção (pessoas usando o app) e o que o painel administrativo está exibindo — o painel parece estar "cego" para esses usuários, mesmo que eles existam e estejam gerando dado real.

## 2. Investigação necessária, sem presumir a causa

Antes de aplicar qualquer correção, confirmar e reportar:

1. **Os usuários estão sendo criados corretamente no banco?** Verificar diretamente na tabela de usuários/perfis (Supabase) se os registros desses novos testadores existem de fato, com dados coerentes (nome, XP, atividade recente).
2. **O problema está na consulta do backend, ou na exibição do painel?** Testar o endpoint que alimenta essas seções do Admin Dashboard diretamente (sem passar pela interface visual), para isolar se o dado já vem incompleto do backend ou se chega completo e é o painel que não exibe.
3. **Existe algum filtro ou critério de elegibilidade** que pode estar excluindo indevidamente esses usuários da consulta (ex.: filtro por período de cadastro, por status de conta, por algum campo que só usuários mais antigos possuem)?
4. **O problema é específico dessas seções (Amigos/Progresso/pontuação), ou mais amplo?** Confirmar se outras seções do Admin Dashboard (ex.: métricas gerais, contagem total de usuários) refletem corretamente esses novos testadores — isso ajuda a isolar se é um problema pontual dessas telas ou algo mais estrutural na camada de dados.
5. **Há alguma relação com cache?** Verificar se o painel usa algum tipo de cache que não está sendo invalidado/atualizado com a entrada de novos usuários.

## 3. O que NÃO fazer nesta rodada

- Não aplicar correção alguma antes de reportar a causa raiz confirmada.
- Não presumir que é "apenas atraso de sincronização" sem confirmar isso de fato — se for esse o caso, reportar em quanto tempo a sincronização deveria acontecer e por que não está acontecendo dentro desse prazo.

## 4. Escopo técnico (alto nível — investigação a aprofundar por Claude Code)

- Revisar os endpoints que alimentam as seções de Amigos, Progresso e Ranking/pontuação dentro do Admin Dashboard (ADMIN_DASHBOARD_V1.md / ADMIN_PAINEL_IN_APP_V1.md, se já implementado).
- Comparar a contagem de usuários que o painel exibe com a contagem real na tabela de perfis do Supabase, para quantificar a divergência (quantos usuários estão "faltando" no painel).
- Uma vez identificada a causa raiz, propor a correção antes de aplicar, seguindo o mesmo padrão de investigação-antes-de-corrigir já usado em bugs anteriores do Movimento.

## 5. Critério de aceite

- Causa raiz identificada e reportada a Rhoney antes de qualquer correção ser aplicada.
- Após a correção, o Admin Dashboard exibe corretamente todos os testadores ativos nas áreas de Amigos, Progresso e pontuação/Ranking, refletindo o estado real do banco de dados.
- Confirmação de que a divergência não existe mais, comparando contagem do painel com contagem real na base de dados.
