# MENTAL — Painel Administrativo Interno (In-App, Versão Leve)

**Status:** Aprovado para implementação.
**Documento relacionado:** ADMIN_DASHBOARD_V1.md (painel web separado, com maior poder e escopo — **fica para um outro momento, não é substituído por este documento**). Este documento formaliza uma versão **mais simples, dentro do próprio app**, para acompanhamento rápido de métricas sem depender de acessar um painel externo.
**Escopo:** Nova tela dentro do app Flutter, visível e acessível apenas para o admin (Rhoney). Somente leitura — mesma regra de segurança já aplicada ao painel externo.

---

## 1. Objetivo

Dar acesso rápido às métricas essenciais do MENTAL **direto no próprio app**, sem precisar abrir um painel separado no navegador. Não substitui a visão futura do ADMIN_DASHBOARD_V1.md (que continua planejado, com mais poder, filtros e profundidade de análise) — este é um painel **complementar e mais leve**, pensado para consulta rápida do dia a dia, inclusive pelo celular, no meio de qualquer outro uso do app.

## 2. Onde vive e como se acessa

- Nova tela dentro do app Flutter já existente — não é um app separado, nem uma rota web.
- **Acesso restrito ao admin**: a tela só deve estar acessível para o usuário cuja conta tenha `role = admin` no Supabase (mesma checagem já usada para proteger `/admin/profile-photos`).
- Ponto de entrada sugerido: um item extra na navegação (ex: bottom navigation ou menu de Configurações) que **só aparece quando o usuário logado é admin** — usuários comuns não devem ver nem saber que essa tela existe.
- Nenhuma rota ou botão desta tela pode ficar acessível a usuários não-admin, incluindo tentativa de acesso direto por deep link.

## 3. Métricas a exibir (versão inicial — enxuta, não é para replicar tudo do painel externo)

Priorizar as métricas de leitura mais rápida e mais úteis para acompanhamento do dia a dia, reaproveitando os mesmos endpoints/queries já especificados em ADMIN_DASHBOARD_V1.md quando existirem, em vez de recriar lógica de agregação duplicada:

- Usuários ativos hoje e na semana.
- Novos cadastros no período.
- Streak médio dos usuários ativos.
- Top 5 "quem mais progrediu" (XP ganho no período) — versão resumida da tabela do painel externo, sem todas as colunas.
- Taxa de acerto por território (lista simples, sem gráfico complexo).
- Distribuição do Feedback Pós-Nível (Fácil/Médio/Difícil/Muito Difícil).

**Fora desta versão leve** (ficam reservadas para o painel externo maior, quando ele for implementado): retenção D0-D14 detalhada, distribuição de nível completa, métricas de Batalhas/Amigos, gráficos elaborados, filtros de período customizados, exportação de dados.

## 4. Interface

- Layout simples, mobile-first (já que é dentro do app), organizado em cards/seções, reaproveitando a identidade visual já estabelecida no app (paleta de conquista definida em Home/Movimento) — não precisa ser um dashboard denso como o painel web, apenas legível e rápido de escanear.
- Seletor de período simples (ex: hoje / últimos 7 dias / últimos 30 dias).
- Sem necessidade de gráficos elaborados nesta versão — números em destaque e listas simples já atendem ao objetivo de "acompanhar rapidamente", que é o propósito desta tela.

## 5. Fonte de dados

- Reaproveitar os mesmos endpoints `/admin/metrics/*` já especificados (ou a especificar) em ADMIN_DASHBOARD_V1.md — este painel in-app é apenas **outra superfície consumindo a mesma API**, não uma nova fonte de dado nem uma nova lógica de agregação.
- Se algum endpoint necessário ainda não existir (porque o painel web maior ainda não foi implementado), criar apenas o(s) mínimo(s) necessário(s) para as métricas da seção 3 — sem antecipar todo o escopo do painel externo.

## 6. Segurança

- Somente leitura — nenhuma ação de escrita/edição de dado de jogador a partir desta tela, mesma regra do painel externo.
- Nenhum dado sensível de outros usuários além do que já é público no app (nome, foto, nível) deve aparecer nas listas desta tela.

## 7. Relação com o painel externo (ADMIN_DASHBOARD_V1.md)

Para deixar claro e evitar retrabalho conflitante:
- O painel externo (web, fora do app) **continua no roadmap**, com escopo maior, mais poder de análise e mais métricas — este documento não o cancela nem o substitui.
- Este painel in-app é a versão **de consulta rápida**, para quando Rhoney já está usando o app e quer ver um número rapidamente, sem trocar de contexto para o navegador.
- Quando o painel externo for implementado, os endpoints criados para esta versão in-app devem ser reaproveitados por ele (não duplicar lógica de agregação entre os dois).

## 8. Critério de aceite

- Tela só aparece e só é acessível para conta com `role = admin`.
- Todas as métricas da seção 3 exibidas corretamente, batendo com o dado real do Supabase.
- Nenhuma ação de escrita disponível na tela.
- Seletor de período funcional (mínimo: hoje, últimos 7 dias, últimos 30 dias).
- Performance da tela não impacta a experiência do restante do app (queries de agregação não podem travar ou lentificar a navegação normal do jogo).
