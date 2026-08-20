# MENTAL — CORE_LOOP.md

Status: rascunho de Discovery, para aprovação de Rhoney.

## 1. O laço central (sessão única)

Reproduzindo e detalhando o fluxo já definido em `MENTAL_KICKOFF.md` §10:

```
abrir app
  → autenticar (ou continuar sessão)
  → home (mostra progresso, território atual, CTA único "Novo desafio")
  → escolher território (ou "próximo recomendado" por padrão)
  → responder desafio (1 pergunta por vez, 1 tipo dos 4 do V1)
  → backend valida resposta
  → backend calcula score/XP (cliente nunca calcula)
  → backend registra tentativa (idempotente via attempt_id, ver kickoff §9.5)
  → app exibe resultado + explicação da resposta correta
  → app atualiza progresso visível (XP, nível, avanço no território)
  → oferece "próximo desafio" (loop) ou volta à home
```

## 2. O que fecha o loop (por que o jogador volta)

- **Streak diário** — jogar todo dia mantém uma sequência visível (mecânica
  de hábito padrão, sem timer de urgência agressivo — ver
  `PRODUCT_PRINCIPLES.md` §3).
- **Progresso incremental visível** — XP e avanço de território sempre
  visíveis, inclusive em territórios travados (`MONETIZATION.md` §2), para
  o jogador enxergar o que está por vir.
- **Limite diário gratuito** — 8-10 desafios/dia (sugestão do
  `MONETIZATION.md` §2, valor a confirmar) cria um ponto de parada natural
  que não frustra, e reforça o retorno no dia seguinte.
- **Explicação da resposta** — cada desafio termina explicando por que a
  resposta certa é certa, não só certo/errado. Isso é o que diferencia
  "jogo que ensina" de "quiz raso" sem parecer aula.

## 3. Sessão multi-dia (o que persiste entre sessões)

- XP acumulado e nível.
- Território(s) conquistado(s) e território atual.
- Streak diário.
- Contagem de desafios consumidos no dia corrente (reseta à meia-noite,
  fuso a definir na Foundation).
- Status de assinatura (quando existir).
- Histórico de tentativas (para ranking, dificuldade adaptativa e hint
  engine — ver documentos específicos).

## 4. Pontos de decisão do jogador dentro do loop

1. Qual território jogar (dentro do que está desbloqueado).
2. Pedir dica ou não (ver `HINT_ENGINE.md`) — sempre opcional, nunca
   obrigatório para prosseguir.
3. Continuar para o próximo desafio ou parar.
4. Compartilhar conquista ao atingir um marco (ver `GAMIFICATION.md`) —
   sempre opcional e explícito (`MENTAL_KICKOFF.md` §6).

## 5. O que o loop nunca faz

- Nunca calcula ou decide resultado no cliente.
- Nunca força continuar jogando (sem dark pattern de "mais um" insistente).
- Nunca interrompe a primeira sessão com oferta de assinatura.
- Nunca perde uma tentativa por falha de rede sem re-tentativa segura — daí
  a exigência de idempotência via `attempt_id` já definida no kickoff.
