# MENTAL — Triagem de Feedback de Teste (UX/UI) + MentalCoins

**Status:** Aprovado — triagem do feedback recebido durante o teste fechado, com nova moeda de prestígio (MentalCoins).
**Documentos relacionados:** DESIGN_SYSTEM.md, FEEDBACK_POS_NIVEL.md, V2_KICKOFF.md (item 5 — Estatísticas), RANKING.md

---

## 1. Contexto

Feedback estruturado de UX/UI recebido durante o período de teste. Cada ponto foi avaliado individualmente — nem toda sugestão é aceita, algumas contrariam decisões já fechadas, e algumas exigem verificação antes de virar tarefa nova.

---

## 2. Aceito — implementar agora

**Refinamento visual de botões:**
- Cantos mais trabalhados, sombra sutil, hierarquia visual clara entre ação primária e secundária.
- Isso é refinamento **dentro** da paleta e identidade visual já oficiais (DESIGN_SYSTEM.md) — não muda cor, tipografia ou conceito de marca, só o acabamento dos componentes.

---

## 3. Verificar antes de agir — pode já existir

**Mapa/tela de progresso + aba de estatísticas detalhada:**
- O feedback pede uma tela dedicada de progressão (níveis concluídos/bloqueados/próximos) e um painel de histórico de XP/pontuação.
- Pode já existir parcialmente (item 5 da V2 — Estatísticas, mais a estrutura de Mundos/Blocos). Antes de tratar como feature nova, verificar com Claude Code o que já está implementado e se o problema é de **visibilidade/acesso** ou de fato **ausência de funcionalidade**.

---

## 4. Não aceito — contraria decisão já fechada

**Substituir o Feedback Pós-Nível por ajuste automático de dificuldade:**
- O sistema de dificuldade adaptativa já existe, baseado em `hint_penalty_factor` — decisão técnica separada e já validada.
- O Feedback Pós-Nível foi formalizado deliberadamente como **coleta de opinião qualitativa para uso futuro**, não como insumo de algoritmo automático agora. Não implementar essa mudança.

---

## 5. Aceito — MentalCoins (nova moeda de prestígio semanal)

### 5.1 Conceito

Moeda de prestígio interna, com design visual sofisticado remetendo a criptomoedas (não é criptomoeda real, não tem valor monetário, não é comprável com dinheiro — é conquista de desempenho). Objetivo: reforçar competição semanal saudável, reaproveitando dados que já existem (XP diário, contador de passos).

### 5.2 Ciclo semanal

- **Início:** toda segunda-feira, 08:00 (horário local do dispositivo/servidor — a definir fuso de referência com Claude Code, provavelmente horário de Brasília como padrão do produto).
- **Fim:** ciclo fecha imediatamente antes do início do próximo ciclo (domingo às 23:59:59, efetivamente).
- Apuração e distribuição de MentalCoins ocorre no fechamento de cada ciclo.

### 5.3 Regras de distribuição — dois rankings independentes, sem sobreposição

**A) Ranking diário de XP (todos os 7 dias da semana):**
- Métrica: XP total ganho naquele dia específico (ranking geral, não por território).
- Recompensa por dia:
  - 1º lugar do dia: **10 MentalCoins**
  - 2º lugar do dia: **5 MentalCoins**
  - 3º lugar do dia: **3 MentalCoins**
- Isso se repete a cada um dos 7 dias do ciclo — ou seja, até 7 conjuntos de top 3 por semana.

**B) Ranking de passos da semana (Contador de Passos):**
- **Campeão da semana:** usuário com maior soma de passos acumulados nos 7 dias do ciclo → **20 MentalCoins**.
- **Recordista do dia:** usuário com o maior número de passos em um único dia dentro da semana (pico diário, não soma) → **10 MentalCoins**.
- Estes dois prêmios de passos são **independentes** do ranking de XP diário (seção A) — um usuário pode ganhar em ambos, nenhuma sobreposição ou exclusão mútua entre os sistemas.

### 5.4 Uso do saldo acumulado (o que MentalCoins desbloqueia)

- **Avatares/cosméticos exclusivos:** linha de avatares e molduras de perfil resgatáveis somente com MentalCoins — nunca compráveis com dinheiro real, preservando o caráter de prestígio por desempenho.
- **Hall da Fama semanal:** espaço de destaque na Home mostrando os vencedores da semana anterior (top diários + campeão de passos + recordista) — efêmero, renovado a cada novo ciclo (toda segunda-feira).
- Fora de escopo por ora: uso de MentalCoins como desconto/crédito em eventual assinatura futura — só será avaliado quando `MONETIZATION_ENABLED` for de fato ativado, com regra de negócio própria a ser desenhada naquele momento.

### 5.5 Identidade visual (design)

- Ícone/design da moeda deve remeter a criptomoedas: acabamento sofisticado e moderno — sugestões de tratamento: efeito metálico/gradiente, formato circular com relevo, possível uso de um símbolo próprio (ex.: um "M" estilizado ou o já existente ícone de sinapse do MENTAL, adaptado a formato de moeda).
- Manter coerência com a paleta oficial (dourado #E2BE6E como cor dominante da moeda, teal #3FA796 como acento) — reforça associação com prestígio/conquista, consistente com a identidade visual já estabelecida (DESIGN_SYSTEM.md).
- Recomenda-se protótipo visual (HTML/SVG) para aprovação antes de qualquer implementação final no client.

### 5.6 Escopo técnico (alto nível — arquitetura detalhada a propor por Claude Code)

- Nova tabela de saldo (`mentalcoins_balance` por usuário) e tabela de histórico/transações (concessões semanais, futuros resgates).
- Rotina de apuração semanal (job agendado, mesmo padrão de infraestrutura já usado para scheduler de notificações) — roda no fechamento do ciclo (segunda-feira, 08:00), calcula os 2 rankings (seção 5.3) e credita os valores correspondentes.
- Autoridade de cálculo e crédito permanece 100% no backend — cliente nunca decide nem calcula saldo.
- Hall da Fama: pode reaproveitar estrutura de leitura já existente de ranking, só precisa persistir o "congelamento" dos vencedores da semana fechada para exibição durante a semana seguinte.

---

## 6. Registrado para debate futuro — não decidir agora

**Paleta de cores mais vibrante:**
- Decisão deliberada de marca (DESIGN_SYSTEM.md) — não mudar agora, revisitar só com debate dedicado.

**Mascote do app:**
- Decisão de marca de grande porte — fica para conversa dedicada, possivelmente junto do planejamento de V3.

---

## 7. Escopo técnico imediato (para Claude Code) — resumo de prioridade

1. Refinamento visual de botões (seção 2).
2. Investigar e reportar o estado atual de mapa de progresso/estatísticas antes de tratar como pedido novo (seção 3).
3. Implementar MentalCoins (seção 5) — nova funcionalidade, requer arquitetura própria a ser proposta antes de codar.
4. Nenhuma mudança na lógica de dificuldade adaptativa nem no Feedback Pós-Nível (seção 4).
5. Nenhuma mudança de paleta ou adição de mascote nesta rodada (seção 6).
