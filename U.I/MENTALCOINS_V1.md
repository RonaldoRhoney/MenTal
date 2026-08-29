# MENTAL — MentalCoins (Moeda de Prestígio Semanal)

**Status:** Aprovado para implementação.
**Documento de origem:** TRIAGEM_FEEDBACK_TESTE.md (seção 5) — este documento formaliza e expande aquela decisão em especificação própria, agora que o conceito já tem protótipo visual aprovado.
**Referência visual:** mental-mentalcoins.html (protótipo estático em HTML/CSS — design da moeda + tela de saldo/Hall da Fama/resgate; reproduzir estrutura, hierarquia, cores e proporções em Flutter).
**Documentos relacionados:** DESIGN_SYSTEM.md, RANKING.md, MOVIMENTO_REDESIGN_V1.md (meta diária configurável, que passa a interagir com o cálculo de recordista de passos descrito aqui).

---

## 1. Conceito

MentalCoins é uma **moeda de prestígio interna** — não é criptomoeda real, não tem valor monetário, não é comprável com dinheiro, e não pode ser convertida em dinheiro. É uma recompensa por desempenho competitivo semanal, reforçando a camada social/competitiva do app sem introduzir qualquer mecanismo de pagamento.

Reaproveita dados que já existem no sistema (XP diário, contador de passos) — não requer nova telemetria, apenas nova lógica de apuração e crédito sobre dado já coletado.

## 2. Ciclo semanal

- **Início:** toda segunda-feira, 08:00.
- **Fim:** domingo, 23:59:59 (fechamento imediatamente antes do início do próximo ciclo).
- **Fuso de referência:** horário de Brasília, como padrão do produto (a confirmar formalmente com Claude Code na implementação, caso haja necessidade técnica de ajuste).
- Apuração e distribuição de MentalCoins ocorrem no momento do fechamento de cada ciclo, via rotina agendada (ver seção 6).

## 3. Regras de distribuição

Dois rankings **independentes**, sem sobreposição ou exclusão mútua entre eles — um mesmo usuário pode pontuar nos dois.

### 3.1 Ranking diário de XP
Repetido a cada um dos 7 dias do ciclo (até 7 conjuntos de top 3 por semana):
- 1º lugar do dia: **10 MentalCoins**
- 2º lugar do dia: **5 MentalCoins**
- 3º lugar do dia: **3 MentalCoins**
- Métrica: XP total ganho naquele dia específico, ranking geral (não segmentado por território).

### 3.2 Ranking de passos da semana
- **Campeão da semana** (maior soma de passos acumulados nos 7 dias do ciclo): **20 MentalCoins**.
- **Recordista do dia** (maior número de passos em um único dia dentro da semana — pico diário, não soma): **10 MentalCoins**.

**Nota de integração com a meta diária configurável (MOVIMENTO_REDESIGN_V1.md):** a apuração de passos para estas duas premiações usa o número absoluto de passos dados, independente da meta diária que cada usuário tenha configurado (5k/10k/15k/20k) — a meta pessoal influencia o bônus de XP individual de cada usuário (regra própria, definida no doc de Movimento), mas **não** altera o critério de disputa do Campeão da Semana ou Recordista do Dia, que comparam passos absolutos entre todos os usuários igualmente.

## 4. O que MentalCoins desbloqueia

- **Avatares e molduras de perfil exclusivos** — resgatáveis somente com MentalCoins, nunca compráveis com dinheiro real. Preserva o caráter de "conquistado por desempenho", não "comprado".
- **Hall da Fama semanal** — espaço de destaque na Home mostrando os vencedores da semana anterior (top 3 diários acumulados + Campeão da Semana + Recordista do Dia). Efêmero: renovado a cada novo ciclo, toda segunda-feira.
- **Fora de escopo por ora:** uso de saldo como desconto/crédito em assinatura futura — só será desenhado quando `MONETIZATION_ENABLED` for de fato ativado, com regra de negócio própria naquele momento.

## 5. Identidade visual (conforme protótipo aprovado)

A moeda em si, conforme mental-mentalcoins.html:
- Design circular com acabamento metálico e relevo físico (múltiplas camadas de gradiente radial simulando profundidade, não um ícone flat).
- Borda externa serrilhada, remetendo a moeda física/cripto.
- Anel interno com padrão sutil de sinapses, conectando visualmente à marca MENTAL (mesmo motivo do logo/ícone do app).
- "M" em relevo no centro, com sombra e realce simulando gravação física.
- Brilho/reflexo (highlight) no canto superior, reforçando a sensação de objeto metálico tridimensional.
- Paleta dourada dominante (`#FFB238` → `#FFDE8A` → tons terrosos `#7A4212` nas sombras), consistente com a cor de "conquista" já estabelecida no restante do app (Home, Movimento).
- Em contexto de exibição (ex: flutuando em destaque), aplicar leve animação de flutuação vertical + glow pulsante ao redor — reforça sensação de item valioso/vivo, não estático.

A tela de MentalCoins (protótipo já inclui):
- **Card de saldo**: moeda em miniatura + valor numérico em destaque + nota do ciclo atual (quando fecha, quando reinicia).
- **Seção "Como ganhar essa semana"**: os dois tracks de recompensa (seção 3) exibidos lado a lado, com os valores de cada colocação.
- **Hall da Fama da semana**: lista dos vencedores atuais, com destaque visual reforçado para o 1º lugar.
- **Seção de resgate**: itens cosméticos disponíveis (moldura, avatar) com custo em MentalCoins e botão de resgate.

## 6. Escopo técnico (alto nível — arquitetura detalhada a propor por Claude Code antes de codar)

- **Nova tabela de saldo** (`mentalcoins_balance`, por usuário) e **tabela de histórico/transações** (registrando cada concessão semanal e, futuramente, cada resgate) — autoridade de cálculo e crédito permanece 100% no backend; o cliente nunca decide nem calcula saldo, apenas exibe o que a API retorna.
- **Rotina de apuração semanal** (job agendado, mesmo padrão de infraestrutura já usado/discutido para automações via n8n — ver conversa sobre automação do app): dispara no fechamento do ciclo (segunda-feira, 08:00), calcula os dois rankings da seção 3 e credita os valores correspondentes a cada usuário elegível.
- **Hall da Fama**: reaproveita estrutura de leitura já existente de ranking; precisa apenas persistir o "congelamento" dos vencedores da semana fechada, para exibição estável durante toda a semana seguinte (não pode ser um cálculo em tempo real que mude durante a semana de exibição).
- **Catálogo de itens resgatáveis** (avatares/molduras): nova tabela simples de itens cosméticos com custo em MentalCoins, e tabela de itens já resgatados por usuário — bloqueando resgate duplicado do mesmo item.
- Painel administrativo (ADMIN_DASHBOARD_V1.md) deve futuramente expor curva de resgate de MentalCoins como métrica — não faz parte da entrega inicial deste documento, apenas registrado como gancho para quando o painel for expandido.

## 7. Fora de escopo nesta entrega

- Uso de MentalCoins como desconto em assinatura (aguardando `MONETIZATION_ENABLED`).
- Ampliação do catálogo de itens resgatáveis além dos exemplos iniciais (moldura + avatar) — curadoria de catálogo maior é trabalho de conteúdo/design separado.
- Definição final de todos os itens cosméticos e seus custos exatos em MentalCoins — os valores do protótipo (80 e 150 MentalCoins nos exemplos) são ilustrativos; a tabela de preços final deve ser calibrada com base na velocidade real de acúmulo observada após o lançamento da feature.

## 8. Critério de aceite

- Ciclo semanal fecha e reinicia automaticamente nos horários definidos, sem intervenção manual.
- Os dois rankings (XP diário e passos semanais) são apurados corretamente e de forma independente, sem sobreposição de regras.
- Saldo de MentalCoins e histórico de transações consultáveis pelo usuário na tela dedicada.
- Hall da Fama exibe corretamente os vencedores da semana fechada, permanecendo estável (não recalculando) durante toda a semana seguinte.
- Resgate de item cosmético debita o saldo corretamente e impede resgate duplicado do mesmo item.
- Nenhum caminho no app permite comprar MentalCoins com dinheiro real, nem hoje nem inadvertidamente por alguma flag de monetização futura mal configurada.
- Identidade visual da moeda e da tela seguem o protótipo aprovado (mental-mentalcoins.html) em termos de paleta, acabamento e hierarquia.
