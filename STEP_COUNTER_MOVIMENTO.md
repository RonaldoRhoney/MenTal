# MENTAL — Contador de Passos & Movimento ("Mente + Corpo")

**Status:** Aprovado para implementação — entra na V2, ativo a partir do lançamento da V2.
**Documentos relacionados:** V2_KICKOFF.md, MONETIZATION_UPDATE_FREE_LAUNCH.md, MICROINTERACTIONS.md, NOTIFICATIONS.md

---

## 1. Justificativa

O MENTAL treina a mente, mas jogar não deveria significar ficar parado e grudado na tela. A pessoa pode jogar em pé, andando, no intervalo do trabalho, levando o cachorro pra passear — o celular vai junto de qualquer forma. Esta feature aproveita esse tempo "morto" (o passo que a pessoa já ia dar) e transforma em recompensa dentro do jogo, reforçando o conceito de "mente + corpo" sem exigir nenhum esforço extra de atenção da pessoa.

**Fora de escopo (ver seção 7):** monitor de batimento cardíaco. Celulares não possuem sensor de BPM real; a única forma confiável exigiria um wearable pareado via Health Connect, o que é um outro nível de dependência de hardware. Registrado como ideia futura, não entra agora.

---

## 2. Mecânica do ciclo

- **Início do ciclo:** definido pelo próprio usuário (configurável), não é um horário fixo do sistema. O momento em que ele ativa/configura a feature pela primeira vez define o horário-âncora do seu ciclo pessoal (ex.: se ele liga às 9h, todo ciclo dele vai de 9h às 9h do dia seguinte).
- **Duração:** 24 horas corridas a partir desse horário-âncora escolhido pelo usuário.
- **Contagem:** feita em segundo plano via sensor nativo de hardware do Android (`TYPE_STEP_COUNTER` — baixíssimo consumo de bateria, não é GPS nem acelerômetro cru).
- **Coleta parcial:** o usuário pode tocar em "Coletar meus passos" a qualquer momento durante o ciclo — não precisa esperar o fim. Cada toque soma os passos acumulados até aquele momento aos pontos/XP.
- **Fechamento do ciclo (relatório final):** ao completar as 24h, o app entrega um **relatório enxuto** (ver seção 3-A) resumindo o ciclo que terminou. É esse relatório que convida o usuário a fazer a **coleta final** dos passos restantes daquele ciclo — a notificação/relatório é o gatilho da ação, não um horário fixo do sistema.
- **Passos não coletados:** se o usuário não coletar (nem parcialmente, nem via relatório final) antes do próximo ciclo avançar, os passos daquele ciclo são perdidos (não acumulam). Isso incentiva o hábito diário sem punir com culpa — ver tom de comunicação na seção 5.

### 2.1 Arquitetura de contagem: "catch-up ao reabrir", não serviço em segundo plano (decisão de Rhoney, 2026-08-21)

Achado real testando em dispositivo físico (Moto G22): `TYPE_STEP_COUNTER` só entrega uma leitura ao app quando o app está com um listener registrado e um passo de verdade acontece — não existe "consultar o valor atual" sob demanda. Isso levantou a pergunta de como garantir que os passos dados com o app fechado sejam contabilizados.

Duas opções foram avaliadas:
1. **Serviço em segundo plano (foreground service) com notificação fixa** — mantém um listener nativo sempre registrado, permite exibir contagem quase em tempo real, mas exige notificação persistente obrigatória (exigência do próprio Android para esse tipo de serviço) e mais consumo de bateria.
2. **Catch-up ao reabrir o app** (escolhida) — o sensor de hardware é cumulativo desde o último boot do aparelho e continua contando sozinho independente de haver um app ouvindo ou não. O app só precisa guardar localmente qual era a leitura do sensor no início do ciclo (baseline) e, toda vez que reabrir, calcular a diferença — os passos dados com o celular no bolso e o app fechado aparecem corretos assim que o app volta a rodar. Sem notificação fixa, sem serviço nativo adicional, sem custo extra de bateria.

**Limitação aceita:** não existe um número "ao vivo" atualizando na tela enquanto o app está minimizado/fechado — só ao reabrir. Único caso não coberto: reboot do aparelho no meio do ciclo zera o contador de hardware (perde o que não foi coletado antes do reboot) — aceitável para uma feature de bônus, não faz parte da autoridade de XP/score do jogo.

---

## 3. Relatório de fim de ciclo (gatilho da coleta final)

- **Momento:** disparado automaticamente quando o ciclo de 24h do usuário se completa (horário varia por pessoa, conforme seção 2 — não é um horário fixo do sistema, é relativo ao horário-âncora de cada usuário).
- **Formato:** relatório bem enxuto — nada de tela cheia de estatística. Algo como: total de passos do ciclo, faixa de bônus atingida, e um toque para coletar.
- **Função dupla:** ao mesmo tempo em que informa, ele é o convite direto para a coleta final dos passos daquele ciclo — o usuário vê o resumo e já tem o botão de coletar ali, sem fricção.
- Entregue como notificação amigável, tom leve — nunca de cobrança. Dispara pela mesma infraestrutura já decidida em NOTIFICATIONS.md (FCM = entrega apenas, FastAPI = autoridade de decisão, Supabase = dados).
- Exemplos de tom (a validar copy final com Rhoney antes de produção):
  - "Seu ciclo fechou! 6.200 passos hoje — toque pra coletar seus pontos. 🚶"
  - "Fim de ciclo! Vem ver quanto você caminhou e garantir seu bônus."
- Respeita configuração de notificações já existente (usuário pode desativar por categoria, conforme NOTIFICATIONS.md).

---

## 4. Conversão de passos em pontos — modelo escalonado por potencial

Conforme decidido: a recompensa cresce de acordo com o "potencial de caminhada" do dia — quanto mais a pessoa andou, proporcionalmente mais ela ganha, sem teto rígido que desestimule quem caminha muito.

**Lógica proposta (faixas escalonadas, a validar valores exatos com Rhoney/Claude Code na implementação):**

| Faixa de passos no ciclo | Bônus de XP |
|---|---|
| 0 – 1.999 | Sem bônus (abaixo do mínimo de esforço) |
| 2.000 – 4.999 | Bônus base |
| 5.000 – 9.999 | Bônus base × 2 |
| 10.000 – 14.999 | Bônus base × 3 |
| 15.000+ | Bônus base × 4 (sem teto superior — quem andar 19.000 como no seu exemplo, recebe o mesmo múltiplo da faixa mais alta, não mais que isso) |

- **Importante:** o valor exato do "bônus base" em XP é parâmetro de configuração no backend (não hardcoded no cliente), seguindo o mesmo padrão de autoridade central já usado em todo o MENTAL (FastAPI decide, Flutter exibe).
- Esse XP é **bônus separado**, distribuído dentro da grade de ganhos diários do jogo (XP total do dia = XP dos desafios + XP dos passos). **Não altera o limite de 24 desafios gratuitos por dia** — são fontes de pontuação diferentes que se somam na mesma grade de progresso (nível, conquistas, etc.).

### 4.1 Meta diária pessoal (extensão aprovada, 2026-08-21)

O usuário pode opcionalmente definir sua própria meta diária de passos (ex.: 20.000). Ultrapassar a PRÓPRIA meta paga um bônus fixo extra (`MOVEMENT_GOAL_BONUS_XP`, config de backend), somado — não em substituição — ao bônus por faixa da tabela acima, uma única vez por ciclo. Sem meta definida, esse bônus simplesmente não se aplica. Nunca é uma meta imposta pelo sistema, nem comparada entre usuários (mesma regra de não-humilhação da seção 5).

### 4.2 Checkpoints intradiários (extensão aprovada, 2026-08-21)

As 24h do ciclo são divididas em `MOVEMENT_CHECKPOINT_PARTS` (4) partes iguais de 6h. Cada um dos 3 primeiros fechamentos (o 4º coincide com o fim do próprio ciclo, já coberto pelo bônus de faixa cheio) paga um bônus extra, reaproveitando a MESMA tabela de faixas da seção 4 — só com os limiares escalados pela fração de tempo já decorrida (ex.: no checkpoint das 6h, 1/4 do dia, os limiares valem 1/4 do normal: 500/1.250/2.500/3.750 passos). Isso incentiva manter o ritmo ao longo do dia, não só "virar tudo de uma vez à noite".

**Limitação real conhecida e aceita** (arquitetura "catch-up", ver seção 6.1): como o backend só sabe quantos passos existem quando o app efetivamente envia uma coleta, os checkpoints são avaliados de forma preguiçosa — na próxima coleta depois que a janela de 6h/12h/18h já fechou no relógio, não exatamente no instante em que ela fecha. Se o usuário só abre o app à noite, uma única coleta tardia acerta as contas de todos os checkpoints pendentes de uma vez.

---

## 5. Tom de comunicação (Princípio de Não-Humilhação aplicado ao movimento)

Mesma regra já aplicada ao resto do MENTAL (ver FAMILY_SAFETY.md e MICROINTERACTIONS.md):

- **Nunca** usar linguagem de culpa por não ter andado ("você não andou nada hoje 😔").
- **Nunca** comparar o usuário com outros nessa métrica especificamente (sem ranking público de passos — evita constranger idosos, pessoas com mobilidade reduzida, crianças sedentárias por motivo de saúde).
- Comemorar o que a pessoa fez, do tamanho que for: 500 passos coletados merece um "Boa! Cada passo conta 🎉" do mesmo jeito que 15.000 merece um "Uau, que caminhada!".
- Público misto (crianças a idosos) reforça: isso é convite, nunca meta obrigatória.

---

## 6. Permissões e privacidade

- Android exige permissão em runtime `ACTIVITY_RECOGNITION` (API 29+) para acessar o sensor de passos — pedida de forma contextual (quando o usuário abrir a tela de Movimento pela primeira vez), nunca no onboarding genérico.
- Se o usuário negar a permissão: a feature simplesmente fica invisível/desativada para ele, sem bloquear o resto do app. Nenhuma penalização.
- Dado de passos fica isolado no schema do MENTAL (mesmo princípio de isolamento por produto já usado em todo RhoneyInc) — não é dado de saúde sensível como BPM, é contagem de movimento, mas ainda assim tratado com o mesmo cuidado de privacidade dos demais dados de usuário.
- Sem transmissão para terceiros, sem uso em publicidade personalizada (mesma regra do child_safe_mode já vigente).

---

## 7. Fora de escopo agora (registrado para o futuro)

- **Monitor de batimento cardíaco via wearable (Health Connect):** ideia registrada, não prioritizada. Exigiria integração com Google Health Connect e dependência de hardware externo (smartwatch/faixa). Avaliar como conceito V3, junto aos demais (trânsito, regional/UGC), somente após MENTAL estar publicado e estável.
- **Ranking de passos entre amigos:** não implementado agora — depende da feature de "amigos" ainda pendente de doc dedicado (ver V2_KICKOFF.md), e mesmo quando existir, precisa respeitar a regra de não-comparação humilhante já estabelecida.

---

## 8. Escopo de implementação (V2)

- Ativa a partir da V2, mas arquitetura pensada para não quebrar nada da V1 (mesmo padrão: feature nova, isolada, com flag de controle se necessário).
- Claude Code deve seguir o mesmo processo já validado: schema novo isolado, testes reais (não apenas unitários simulados), validação em dispositivo real antes de considerar "pronto".
- Este documento está aprovado para ir ao Claude Code junto aos demais pendentes de hoje.
