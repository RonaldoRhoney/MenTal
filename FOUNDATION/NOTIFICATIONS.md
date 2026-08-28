# MENTAL — NOTIFICATIONS.md

Status: aprovado por Rhoney (dono). Parte oficial da Foundation, adicionado
durante a V2. Toda notificação deste documento segue `PRODUCT_PRINCIPLES.md`
(não-humilhação, não-manipulação) e `FAMILY_SAFETY.md` — nenhuma exceção
por ser mecanismo de retenção.

## 1. Princípio

Notificação existe para lembrar com gentileza, nunca para pressionar,
envergonhar ou criar ansiedade. O jogador deve sentir convite, não cobrança.
Isso vale tanto para lembretes de inatividade quanto para notificações de
evento social (alguém avançou no ranking).

## 2. Notificação de reengajamento (inatividade)

Dois estágios, tom crescente em calor, nunca em pressão:

**Após 24h sem abrir o app:**
- Tom leve, sem urgência. Lembrete simples de que o progresso está
  esperando.
- Exemplo de direção (não é copy final — Claude Code deve propor 2-3
  variações para Rhoney escolher): "Seu território está esperando por
  você. Bora pensar um pouco hoje?"

**Após 48h sem abrir o app:**
- Tom mais caloroso, pode reforçar o que o jogador já conquistou (reforço
  positivo, não culpa por ter sumido).
- Exemplo de direção: "Sentimos sua falta! Seu Nível [N] e seus territórios
  seguem esperando por você."
- **Nunca** usar linguagem de perda, culpa ou urgência artificial — proibido
  qualquer variação de "você vai perder seu progresso", "não deixe seu
  streak morrer", "últimas horas para X". Isso é manipulação emocional
  vedada por `PRODUCT_PRINCIPLES.md`, mesmo sendo prática comum em outros
  apps de gamificação.

**Regra de frequência:** no máximo uma notificação de reengajamento por
janela de inatividade (uma em 24h, uma em 48h) — nunca notificações
repetidas/insistentes no mesmo período de ausência.

## 3. Notificação de evento social (alguém avançou/ultrapassou)

Esta categoria exige mais cuidado — é a que mais facilmente escorrega para
tom competitivo hostil se mal escrita.

**Quando disparar:** quando outro jogador (ranking geral ou, futuramente,
amigo) ultrapassa a posição do usuário, ou conquista algo que coloca o
usuário em desvantagem relativa recente.

**Tom obrigatório:** convite a jogar de novo, nunca comparação humilhante.
- Aceitável: "Alguém avançou no ranking esta semana. Que tal um desafio
  agora?"
- Aceitável (reaproveitando linguagem já usada no app): "João passou você
  no território. Hora de reconquistar?" — mantendo o espírito lúdico já
  presente em `PRODUCT_PRINCIPLES.md` (exemplo de linguagem de engagement
  já citado no documento original do produto).
- **Proibido:** exibir a diferença numérica de forma que soe como
  "derrota" (ex.: "Você está 340 pontos atrás de João" tem tom de
  ranking de humilhação, evitar formulação que pareça cobrança).
- **Proibido:** qualquer notificação desta categoria para usuário marcado
  como criança (`child_safe_mode = true`) que exponha nome ou desempenho
  de outro jogador de forma direta e comparativa — regra de anonimização já
  aplicada ao ranking (`RANKING.md` §4) se estende às notificações. Uma
  criança não deve receber notificação do tipo "Fulano passou você" — a
  mensagem para esse público deve ser genérica ("A disputa está acirrada no
  seu território — hora de jogar!"), sem citar outro jogador nominalmente.

## 4. Controle do usuário

- Notificações devem ter opt-in explícito (permissão do Android é opt-in
  por padrão a partir de Android 13+, mas o app deve pedir a permissão de
  forma clara, explicando o valor, não forçar ou repetir o pedido de forma
  insistente).
- Toggle para desativar cada categoria separadamente (reengajamento vs.
  evento social) na tela de Perfil/Configurações — usuário pode querer uma
  sem a outra.
- Nenhuma notificação enviada se o usuário desativou a categoria
  correspondente — sem exceção, sem "notificação importante" que ignore a
  preferência.

## 5. Escopo técnico

- Serviço de push: a definir por Claude Code respeitando a regra Zero-Cost
  já aplicada ao restante da infraestrutura (ex.: Firebase Cloud Messaging
  tem tier gratuito adequado ao volume esperado nesta fase — Claude Code
  deve verificar a política de preço atual antes de decidir, mesmo rigor
  já aplicado nas decisões de Render/UptimeRobot).
- Cálculo de "quem ultrapassou quem" deve ser feito no backend (mesma regra
  de autoridade única já aplicada a tudo no projeto) — client nunca decide
  se deve notificar, apenas recebe e exibe.
- Textos finais de notificação (copy) devem ser aprovados por Rhoney antes
  de entrar em produção — Claude Code propõe variações, não decide o texto
  final sozinho.

## 6. Papel de cada parte

- **Rhoney**: aprova o texto final de cada notificação antes de produção;
  decide se/quando ativar a categoria de evento social (pode entrar em
  etapa separada da de reengajamento, se fizer sentido sequenciar).
- **Claude (arquitetura)**: garante que a regra de anonimização para
  usuário menor (Seção 3) é respeitada tecnicamente, e que a escolha de
  serviço de push (Seção 5) segue a regra Zero-Cost antes de aprovar.
- **Claude Code**: implementa o disparo de notificação no backend, propõe
  variações de copy para aprovação, implementa os toggles de controle do
  usuário, e testa em dispositivo real antes de considerar fechado.
