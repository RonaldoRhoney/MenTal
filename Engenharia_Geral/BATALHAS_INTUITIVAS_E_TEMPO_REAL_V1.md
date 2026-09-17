# MENTAL — Batalhas Mais Intuitivas: Modo Assíncrono Aprimorado + Modo Simultâneo (Tempo Real)

**Status:** Aprovado para análise e implementação por fases. Fase 1 (assíncrona) e Fase 2 (simultânea) devem ser tratadas como entregas distintas, com esforço de arquitetura muito diferente entre si — não implementar como um único pacote.

---

## 1. Objetivo geral

Tornar as Batalhas uma experiência mais clara e envolvente para o usuário, em dois níveis:
- **Fase 1**: deixar o fluxo assíncrono já existente (você joga sua rodada, o adversário é notificado, vê seu resultado e "contra-responde" jogando a dele) muito mais visível e intuitivo na interface — hoje esse mecanismo existe, mas não é suficientemente claro para o jogador.
- **Fase 2**: introduzir um modo novo de Batalha **simultânea em tempo real**, onde os dois jogadores entram ao mesmo tempo numa disputa cronometrada e respondem ao mesmo desafio "ao vivo".

## 2. Fase 1 — Modo Assíncrono Aprimorado (prioridade imediata)

### 2.1 Problema atual
O mecanismo de "eu jogo, o outro é notificado e contra-responde depois" já existe no sistema de Batalhas, mas fica pouco evidente para o usuário — não fica claro, na interface, que ele está no meio de uma disputa em andamento, esperando a resposta do adversário, ou que é a vez dele de responder.

### 2.2 Proposta de melhoria de UX
- Estado visual claro de "aguardando o adversário" na tela de Batalhas, mostrando quem já jogou e quem falta jogar.
- Notificação push explícita quando o adversário joga sua rodada, convidando o usuário a "contra-responder agora".
- Indicador de "é a sua vez" bem destacado, talvez na Home ou na barra inferior, para reduzir a chance de o usuário esquecer que tem uma Batalha pendente.
- Resultado final da Batalha exibido de forma mais rica visualmente (não só texto), reforçando a sensação de disputa/competição — reaproveitar o estilo visual já estabelecido em Ranking e Movimento.

### 2.3 Escopo técnico (Fase 1)
- Não exige mudança de arquitetura de backend — é essencialmente uma melhoria de interface e notificações sobre uma lógica que já existe.
- Reaproveitar o padrão de notificação já usado para Torcida, com nome real do adversário (conforme regra já aprovada em NOME_REAL_E_FOTO_EM_TODO_LUGAR_V1.md).

## 3. Fase 2 — Modo Simultâneo em Tempo Real (esforço maior, planejamento à parte)

### 3.1 O que muda fundamentalmente
Diferente do modo assíncrono, aqui os dois jogadores precisam estar **conectados ao mesmo tempo**, numa "sala" de disputa, respondendo ao mesmo desafio dentro de um cronômetro compartilhado — o resultado de um jogador pode, inclusive, ser visível ou influenciar a percepção de urgência do outro durante a partida.

### 3.2 Por que isso é uma mudança de arquitetura maior
O restante do app funciona hoje por requisições tradicionais (o cliente pede, o servidor responde). Uma disputa simultânea em tempo real normalmente exige uma camada de comunicação diferente (ex.: WebSocket ou tecnologia equivalente), capaz de manter uma conexão viva entre os dois jogadores e o servidor durante toda a partida, sincronizando estado em tempo real — isso é estruturalmente diferente de qualquer coisa já implementada no MENTAL até hoje.

### 3.3 Perguntas que precisam de decisão de produto antes de qualquer implementação técnica
- Como funciona o convite pra uma Batalha simultânea? O usuário precisa estar com o app aberto no momento do convite, ou existe uma "sala de espera" com tempo limite?
- O que acontece se um dos dois perder a conexão no meio da partida? Reconecta automaticamente, a partida é cancelada, ou o outro jogador vence por W.O.?
- A pontuação/XP de uma Batalha simultânea deve ser diferente (maior?) da assíncrona, dado o maior nível de engajamento e dificuldade de coordenar dois jogadores online ao mesmo tempo?
- Esse modo roda em paralelo ao modo assíncrono (dois tipos de Batalha coexistindo), ou substitui o modo atual no longo prazo?

### 3.4 Escopo técnico (Fase 2 — alto nível, a ser detalhado por Claude Code)
- Investigar viabilidade de comunicação em tempo real dentro da stack atual do MENTAL (Flutter/FastAPI/Supabase), incluindo impacto de custo e complexidade de manter conexões simultâneas ativas no plano de hospedagem atual (Render Free, conforme já registrado no histórico do projeto).
- Propor arquitetura de "sala de disputa" com sincronização de estado entre os dois jogadores.
- Definir contingência para perda de conexão, timeout de resposta, e desistência no meio da partida.

## 4. Ordem recomendada de execução

1. **Fase 1 primeiro** — melhoria de UX do modo assíncrono, sem mudança de arquitetura, entrega rápida.
2. **Fase 2 depois**, e só após resposta às perguntas de produto da seção 3.3 — essa fase deve ser tratada como um projeto à parte, com investigação de viabilidade técnica antes de qualquer estimativa de prazo.

## 5. Critério de aceite

### Fase 1
- Usuário consegue identificar claramente, sem ambiguidade, quando está aguardando o adversário e quando é sua vez de jogar.
- Notificação de "contra-resposta" chega corretamente ao adversário quando uma rodada é jogada.

### Fase 2
- Investigação de viabilidade técnica entregue e aprovada antes de qualquer código ser escrito.
- Respostas às quatro perguntas de produto da seção 3.3 documentadas e aprovadas por Rhoney antes da implementação.
