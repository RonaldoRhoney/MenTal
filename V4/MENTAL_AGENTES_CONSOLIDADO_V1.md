# MENTAL — Documento Consolidado dos Agentes de IA (Funções, Contexto e Relação entre Si)

**Status:** Aprovado. Documento vivo — atualizar sempre que um agente for implementado, ajustado de escopo, ou um novo agente for adicionado.
**Documentos relacionados:** MENTAL_AI_AGENT_TEAM_V1.md (arquitetura original de motores e princípio de não-autonomia), AGENTE_MENTALFEEDAI.md, AGENTE_SAUDE_INFRAESTRUTURA.md, AGENTE_MODERACAO.md.
**Propósito:** Reunir, num único lugar, a descrição contextualizada e a função de cada agente já nomeado — inclusive os já implementados — para servir de referência rápida sobre quem faz o quê, por que existe, e como os 9 trabalham em paralelo sem sobrepor responsabilidade.

---

## Princípio central (válido para todos os 9)

Nenhum agente aplica ação em produção de forma autônoma. Todo agente gera relatório, análise ou sugestão — a decisão final e a execução de qualquer mudança real permanecem sempre com Rhoney. Isso é o que permite que os 9 rodem verdadeiramente em paralelo: como nenhum executa ação final, não há disputa de prioridade entre eles — o único ponto de decisão é humano.

---

## Motor A — Agentes de Código (Claude Code, acesso ao repositório)

### 🛡️ MentalGuard — Segurança + Qualidade de Código
**Status:** Implementado (Fase 1 da V4).

**Função:** Varre o código-fonte do MENTAL em busca de vulnerabilidades de segurança (dados expostos, falhas de autenticação, brechas de acesso indevido) e, simultaneamente, avalia qualidade de código (legibilidade, duplicação, aderência a padrão estabelecido no projeto).

**Por que existe, com evidência real:** Já encontrou dois problemas reais em produção antes de exploração externa: um path traversal crítico na foto de perfil (permitia ler/apagar foto de outro usuário — checagem forense confirmou que ninguém explorou antes da correção) e um farm ilimitado de XP via `attempt_id` inventado pelo cliente no endpoint de resposta de desafio.

**Gatilho:** sob demanda, ou antes de cada release/publicação de nova versão.

**Nunca faz sozinho:** aplicar correção em produção — sempre gera relatório com achados e evidência (arquivo/linha), aguardando aprovação antes de qualquer mudança real.

**Relação com os demais:** trabalha lado a lado com MentalQA (que garante que a correção não quebra nada) e complementa MentalComply (que cobre conformidade de política de loja, não segurança técnica) e MentalShield (que cuida de segurança "social" — denúncia entre usuários — enquanto MentalGuard cuida da segurança técnica do código).

### 🧪 MentalQA — Testes Automatizados
**Status:** Implementado (Fase 1 da V4).

**Função:** Garante que toda mudança relevante de código tem cobertura de teste correspondente, roda a suíte completa (backend + client) e aponta áreas de cobertura fraca ou ausente.

**Por que existe:** Sem essa disciplina, uma correção do MentalGuard (ou qualquer outra mudança) poderia introduzir regressão silenciosa, só percebida em produção — a suíte já cresceu para centenas de testes cobrindo fluxos críticos como coleta de passos, XP e ciclo de dados.

**Gatilho:** a cada mudança relevante de código (Pull Request) ou sob demanda.

**Nunca faz sozinho:** decidir ignorar um teste falhando ou reduzir cobertura sem sinalizar — sempre reporta o estado real da suíte.

**Relação com os demais:** atua em conjunto direto com MentalGuard na maioria das rodadas de revisão — um encontra o problema, o outro garante que a correção aplicada é segura.

---

## Motor B — Agentes de Monitoramento e Pesquisa (n8n, sem acesso ao código)

### 🔎 MentalScout — Pesquisador de Conteúdo
**Status:** Implementado (Fase 1 da V4) — Motor B (n8n) ainda bloqueado por falta de acesso à infraestrutura na sessão atual; a função em si já reaproveita o processo de curadoria manual já validado.

**Função:** Busca tendências de conteúdo, valida fatos de curiosidades e sugere novos temas/blocos, aplicando os mesmos critérios já formalizados (teste do óbvio, teste da revelação, Política de Conteúdo Seguro).

**Por que existe:** O MENTAL já acumula um volume grande de conteúdo curado (Mitologia, ENEM, Concursos, Tecnologia, Vida Prática, Curiosidade Relâmpago, e mais de 90 blocos só no Mundo dos Idiomas) — a demanda por conteúdo novo é constante, e este agente antecipa sugestões em vez de depender só de decisão manual pontual.

**Gatilho:** agendado (ex.: semanal), reaproveitando a infraestrutura n8n já desenhada para automação do app.

**Nunca faz sozinho:** publicar conteúdo direto no app — sempre entrega um lote de sugestões para aprovação, ajuste ou descarte.

**Relação com os demais:** o que é aprovado e carregado pode disparar, em seguida, uma checagem do MentalAudit (confirmando que o novo conteúdo entrou no território/Mundo certo).

### 💗 MentalPulse — Saúde de Infraestrutura
**Status:** Formalizado, aguardando implementação.

**Função:** Monitora continuamente a disponibilidade e a saúde do backend (Render) e do banco de dados (Supabase), alertando sobre degradação, indisponibilidade, ou consumo próximo do limite do plano gratuito antes que o usuário perceba primeiro.

**Por que existe:** Já houve um caso real de suspensão inesperada de infraestrutura (bandwidth do plano gratuito do Render) descoberto apenas porque testadores reclamaram — este agente formaliza o "Monitor de Infra" desenhado desde a primeira conversa sobre automação via n8n, nunca implementado até então.

**Gatilho:** agendado, rodando a cada poucos minutos (ex.: 5-10 min) — a cadência mais frequente entre todos os 9 agentes.

**Nunca faz sozinho:** qualquer ação corretiva (reiniciar serviço, migrar, aumentar plano) — é estritamente observacional, apenas alerta.

**Relação com os demais:** roda de forma totalmente independente dos demais, já que é o único com necessidade real de cadência quase em tempo real.

### 📋 MentalComply — Compliance Contínuo
**Status:** Candidato nomeado, ainda não formalizado em detalhe/implementado.

**Função:** Reexecuta periodicamente o checklist de conformidade Google Play (o mesmo que já fechou 10 de 10 itens numa auditoria manual completa) — target API level, registro de package name, Data Safety Section, permissões sensíveis, conteúdo gerado por usuário.

**Por que existe:** Políticas de loja mudam com frequência, e hoje essa checagem só acontece quando alguém lembra de solicitar manualmente — um app já publicado corre risco real de ser pego de surpresa por mudança de regra sem aviso prévio.

**Gatilho previsto:** antes de cada release (junto com MentalGuard/MentalQA) e também numa cadência periódica independente (ex.: mensal).

**Nunca fará sozinho:** alterar comportamento do app ou declaração no Play Console — apenas relatório de conformidade, no mesmo formato já validado (✅/⚠️/🔴/❓).

**Relação com os demais:** cobre uma dimensão que MentalGuard não cobre (política de distribuição de loja, não segurança/qualidade técnica em si) — os dois se complementam antes de cada release.

### 🗂️ MentalAudit — Consistência de Conteúdo
**Status:** Candidato nomeado, ainda não formalizado em detalhe/implementado.

**Função:** Repete periodicamente a Auditoria Estrutural — verificar se cada território de conteúdo está alocado no Mundo certo, se não há item duplicado entre blocos, se o ID de cada item bate com o lugar onde ele fisicamente está armazenado.

**Por que existe:** Com o volume de conteúdo em constante crescimento (V3, V4, e o Mundo dos Idiomas já com 90+ blocos), a chance de um item ser alocado no lugar errado aumenta — fazer essa checagem manualmente a cada nova leva não escala.

**Gatilho previsto:** após qualquer carga grande de conteúdo novo.

**Nunca fará sozinho:** mover, corrigir ou apagar um item — apenas reporta inconsistências encontradas, no formato já validado (local encontrado / onde deveria estar / evidência / ação sugerida).

**Relação com os demais:** fecha o ciclo iniciado pelo MentalScout — Scout sugere conteúdo, Rhoney aprova, Audit confirma que entrou no lugar estrutural correto.

### 📈 MentalGrowth — Retenção e Engajamento
**Status:** Candidato nomeado, ainda não formalizado em detalhe/implementado.

**Função:** Analisa por que usuários abandonam em determinados pontos da jornada, quais territórios apresentam taxa de acerto anormalmente baixa (sinal de dificuldade mal calibrada), e tendências reais de uso — com foco de produto, não de infraestrutura.

**Por que existe:** Métricas puramente técnicas (uptime, taxa de erro) não respondem à pergunta "por que as pessoas param de jogar" — essa é uma lacuna de insight de produto que hoje não tem processo sistemático de resposta.

**Gatilho previsto:** periódico, consumindo os mesmos dados que já alimentam o Admin Dashboard.

**Nunca fará sozinho:** decidir ou aplicar mudança de produto — apenas análise e sinalização de padrão observado.

**Relação com os demais:** pode sinalizar ao MentalScout que um território específico precisa de mais conteúdo, ou apontar para revisão de UI quando uma tela parece confundir o usuário — é o agente mais voltado a gerar insumo de decisão estratégica, não operacional.

---

## Reativos (respondem a evento, não a agenda)

### 💬 MentalFeedAI — Análise de Feedback
**Status:** Formalizado, aguardando implementação.

**Função:** Analisa cada feedback/comentário enviado por um usuário através do menu Feedback já existente no app, e redige uma resposta sugerida.

**Por que existe:** O menu Feedback já existe, mas sem processo ativo de resposta — isso entrega valor real e imediato ao usuário (perceber que foi lido e está sendo tratado) sem exigir que cada resposta seja escrita do zero manualmente.

**Gatilho:** evento — disparado a cada novo feedback recebido.

**Nunca faz sozinho:** publicar a resposta — sempre aguarda aprovação, edição ou descarte antes de qualquer conteúdo chegar ao usuário. O alerta de "em análise" na Home é a única coisa visível ao usuário antes dessa aprovação.

**Relação com os demais:** compartilha o mesmo desenho de fluxo (analisar → sugerir → decisão humana) do MentalShield, mas atua sobre feedback espontâneo, não denúncia.

### 🚨 MentalShield — Moderação de Denúncias
**Status:** Formalizado, aguardando implementação.

**Função:** Analisa denúncias já recebidas pelo sistema existente (perfil, comportamento, conteúdo gerado), sugere uma classificação de severidade e uma ação (ignorar, advertir, remover, banir), priorizando casos sensíveis ou recorrentes.

**Por que existe:** O sistema de denúncia e bloqueio já existe (exigido pela conformidade Google Play para apps com conteúdo gerado por usuário), mas sem ninguém analisando ativamente o que chega — essa lacuna existe desde a implementação original de UGC.

**Gatilho:** evento — disparado a cada nova denúncia recebida.

**Nunca faz sozinho:** aplicar qualquer ação de moderação — dado que afeta diretamente a conta de outro usuário, a decisão final é sempre e exclusivamente humana, sem exceção, mais rígida ainda que os demais agentes reativos.

**Relação com os demais:** mesmo padrão reativo do MentalFeedAI, mas num domínio de maior sensibilidade e risco.

---

## Tabela-resumo

| Agente | Motor | Status | Gatilho | Nunca faz sozinho |
|---|---|---|---|---|
| MentalGuard | A | Implementado | Sob demanda / release | Aplicar correção em produção |
| MentalQA | A | Implementado | Cada mudança de código | Ignorar teste falhando |
| MentalScout | B | Implementado (Motor B bloqueado) | Agendado | Publicar conteúdo sem aprovação |
| MentalPulse | B | Formalizado | Contínuo (5-10 min) | Corrigir infraestrutura sozinho |
| MentalComply | B | Candidato | Release + periódico | Alterar comportamento do app |
| MentalAudit | B | Candidato | Após carga de conteúdo | Mover/corrigir item sozinho |
| MentalGrowth | B | Candidato | Periódico | Decidir mudança de produto |
| MentalFeedAI | Reativo | Formalizado | Novo feedback | Publicar resposta sem aprovação |
| MentalShield | Reativo | Formalizado | Nova denúncia | Aplicar ação de moderação |

---

## Histórico de atualização deste documento

- Criado nesta versão (V1) consolidando as descrições de todos os 9 agentes já nomeados, incluindo os 3 já implementados na Fase 1 da V4.
- Próxima atualização esperada: ao implementar MentalPulse, MentalFeedAI ou MentalShield (mudança de status), ou ao formalizar em detalhe MentalComply, MentalAudit ou MentalGrowth.
