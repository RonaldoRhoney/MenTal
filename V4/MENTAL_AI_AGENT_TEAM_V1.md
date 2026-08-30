# MENTAL — Arquitetura de Agentes de IA (MENTAL AI Agent Team)

**Status:** Aprovado para implementação da Fase 1. Fases 2 e 3 ficam registradas como visão de médio/longo prazo, sem detalhamento de execução ainda.
**Timing de início:** A Fase 1 deste documento será a **primeira ação quando o desenvolvimento da V4 começar** — não antes disso. Prioridade até lá continua sendo a curadoria/implementação de conteúdo da V3 e a validação do app em produção.
**Contexto:** Visão original proposta por Rhoney (equipe de 12 agentes especializados + orquestrador + review board). Este documento formaliza uma versão faseada e tecnicamente viável dessa visão, mantendo o espírito (especialização por função, aprovação humana obrigatória) e ajustando escopo/ordem para o estágio atual do produto.
**Documentos relacionados:** ADMIN_DASHBOARD_V1.md (reaproveitado pelo agente de Data/Analytics), MENTAL_V3_SOUND_AI_PRD (mesma Política de Não-Autonomia aplicada aqui), CHECKLIST_GOOGLE_PLAY_COMPLIANCE.md (modelo de auditoria já validado, reaproveitado pelo agente de Segurança).

---

## 1. Princípio central

Nenhum agente aplica mudança em produção de forma autônoma. Todo agente, em qualquer motor, gera relatório ou sugestão — nunca commit direto, nunca deploy automático, nunca merge sem revisão humana. Rhoney é sempre o ponto final de decisão, o mesmo princípio já aplicado ao Admin Dashboard (somente leitura) e à Política de Não-Autonomia do Sound AI.

## 2. Dois motores, não um só

A arquitetura original imaginava um único "hub" orquestrando tudo. Na prática, os agentes têm naturezas de trabalho diferentes, e por isso vivem em dois motores separados:

### 2.1 Motor A — Agentes de código
- Rodam como subagentes do Claude Code, com acesso direto ao repositório.
- Disparados sob demanda (ex: antes de um release) ou por evento (ex: a cada Pull Request).
- Escopo: leitura e análise do código-fonte, gerando relatório com achados e sugestões — nunca aplicando mudança sozinhos.

### 2.2 Motor B — Agentes de monitoramento e pesquisa
- Rodam via n8n (infraestrutura já discutida e desenhada em conversa anterior sobre automação do app), de forma agendada.
- Não têm acesso ao repositório de código — consomem dados de produção (métricas, logs, APIs externas) e geram relatório.
- Escopo: observação e pesquisa, nunca ação automática sobre o produto.

## 3. Painel de Relatórios (substitui o "Review Board" da visão original)

Em vez de uma camada intermediária de revisão automatizada entre os agentes e Rhoney, os dois motores escrevem seus relatórios num destino único e consolidado. Na prática, isso pode ser:
- Uma seção nova dentro do painel administrativo já existente (ADMIN_DASHBOARD_V1.md), ou
- Uma notificação consolidada (ex: via Telegram, reaproveitando a infraestrutura de alertas já desenhada para automação do app).

Decisão de qual formato exato fica a critério de Claude Code na implementação, desde que atenda ao critério: um único lugar onde Rhoney vê o que cada agente encontrou, sem precisar abrir várias ferramentas diferentes.

## 4. Fora do sistema de agentes (permanece manual, por decisão deliberada)

Os seguintes temas não viram agentes automatizados, mesmo tendo sido cogitados na visão original (UI/UX Agent, Gameplay Agent, AI Agent genérico):
- Decisões de UI/UX e identidade visual — permanecem como colaboração direta entre Rhoney e Claude (chat), como já vem funcionando bem (Home, Movimento, MentalCoins).
- Design de gameplay/mecânicas novas — mesma lógica: são decisões de produto que dependem do julgamento e gosto de Rhoney, não de análise automatizada.
- Pesquisa estratégica de produto (ex: "vale a pena entrar nesse mercado", "qual a próxima feature") — permanece como conversa entre Rhoney e Claude.

Motivo: essas áreas são onde o processo atual já demonstrou funcionar bem justamente por ser manual e supervisionado de perto — automatizar retiraria o controle que gerou os melhores resultados até aqui.

---

## 5. FASE 1 — Agentes aprovados para implementação imediata

### 5.1 Agente de Segurança + Revisor de Código (Motor A, fundidos)

Por que fundidos: ambos analisam o mesmo código-fonte com objetivos complementares (segurança e qualidade/legibilidade). Rodar como dois agentes separados duplicaria trabalho e poderia gerar sugestões conflitantes sobre o mesmo trecho de código.

Escopo:
- Varredura de vulnerabilidades conhecidas, dependências desatualizadas, segredos/chaves expostas no código, más práticas de autenticação — no mesmo espírito do CHECKLIST_GOOGLE_PLAY_COMPLIANCE.md já executado.
- Revisão de qualidade: legibilidade, duplicação de código, aderência ao padrão já estabelecido no projeto, ausência de testes em mudanças recentes.

Gatilho: sob demanda (Rhoney solicita) ou antes de cada release/publicação de nova versão.

Formato de saída: relatório único no formato conforme/atenção/não conforme/não verificado (mesmo padrão já validado no CHECKLIST_GOOGLE_PLAY_COMPLIANCE.md), com evidência (arquivo/linha) para cada achado.

### 5.2 Agente de Testing (Motor A)

Escopo:
- Garante que toda mudança relevante no código tem cobertura de teste correspondente.
- Roda a suíte de testes completa (backend + Flutter) e reporta falhas.
- Aponta áreas de cobertura fraca ou ausente, sem necessariamente escrever os testes sozinho (a menos que explicitamente solicitado).

Gatilho: a cada mudança relevante de código (Pull Request) ou sob demanda.

Formato de saída: relatório de status da suíte (passou/falhou, quantos testes, cobertura por área), com destaque para qualquer regressão detectada.

### 5.3 Agente Pesquisador de Conteúdo (Motor B)

Escopo:
- Reaproveita exatamente o processo que Rhoney e Claude já fazem manualmente nesta conversa: buscar tendências de conteúdo, validar fatos de curiosidades, sugerir novos temas/blocos.
- Roda de forma agendada (ex: semanal), trazendo um lote de sugestões para aprovação de Rhoney — nunca publica conteúdo direto no app.
- Aplica automaticamente, como primeiro filtro, os critérios já formalizados: teste do óbvio e teste da revelação (V3.5_CURIOSIDADE_RELAMPAGO.md), e a Política de Conteúdo Seguro (POLITICA_CONTEUDO_SEGURO_QUALQUER_IDADE.md).

Gatilho: agendado (ex: toda segunda-feira), reaproveitando a mesma infraestrutura n8n já desenhada para automação do app.

Formato de saída: lote de sugestões de conteúdo (charadas, curiosidades, temas de bloco), no mesmo formato de curadoria já usado nesta conversa — pronto para Rhoney aprovar, ajustar ou descartar.

---

## 6. FASE 2 — Candidatos para expansão futura (não detalhados nesta entrega)

- Agente de Performance (código) — Motor A: análise estática de queries lentas, tamanho de bundle, uso ineficiente de recursos no código.
- Agente de Performance (produção) — Motor B: monitoramento contínuo de métricas reais em produção, reaproveitando a Fase 1 de monitoramento de infra já desenhada anteriormente.
- Agente de Acessibilidade — Motor A: verificação de conformidade com boas práticas de acessibilidade (contraste, tamanho de toque, suporte a leitor de tela).
- Agente de Data/Analytics — Motor B: aprofundamento sobre o que já existe no ADMIN_DASHBOARD_V1.md, trazendo análises mais elaboradas de tendência de dados.

## 7. FASE 3 — Candidato a avaliar (não aprovado, apenas registrado)

- Agente Android especialista — Motor A: foco específico em particularidades da plataforma Android (permissões, políticas de loja, otimizações específicas do SO). Avaliar necessidade real depois que as Fases 1 e 2 estiverem validadas em uso — pode ser redundante com o que Segurança+Revisor de Código e Performance já cobrem.

---

## 8. Critério de aceite da Fase 1

- Os 3 agentes da Fase 1 (Segurança+Revisor, Testing, Pesquisador de Conteúdo) implementados e gerando relatório real, sem qualquer ação automática em produção ou no repositório.
- Painel de Relatórios funcional, consolidando a saída dos dois motores em um único lugar de consulta para Rhoney.
- Nenhum agente da Fase 1 substitui ou automatiza decisões de UI/UX, gameplay ou pesquisa estratégica de produto — essas permanecem manuais, conforme seção 4.
- Ordem de implementação respeitada: Segurança+Revisor primeiro, depois Testing, depois Pesquisador de Conteúdo — não simultâneo, seguindo o mesmo padrão de rollout sequencial já usado na V3 de conteúdo.
- Início da Fase 1 condicionado ao começo do desenvolvimento da V4 — é a primeira ação daquele momento, não uma tarefa paralela à V3 em andamento.
