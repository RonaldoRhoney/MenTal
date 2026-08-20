# MENTAL — GAMIFICATION.md

Status: rascunho de Discovery, para aprovação de Rhoney.

## 1. Sistemas de gamificação do V1

### XP e nível
- Toda resposta correta gera XP, calculado exclusivamente pelo backend
  (`MENTAL_KICKOFF.md` §2). XP se acumula por território e globalmente.
- Nível é derivado do XP acumulado (fórmula exata: Foundation). Nível é
  cosmético/motivacional no V1, não desbloqueia conteúdo por si só (quem
  desbloqueia território é assinatura ou território free, não nível — para
  não confundir os dois sistemas).

### Streak diário
- Contador de dias consecutivos com pelo menos 1 desafio respondido.
- Reforça retorno diário sem timer de urgência (`PRODUCT_PRINCIPLES.md`
  §3). Regra de tolerância a falha de 1 dia (streak freeze): aberto, ponto
  de UX a decidir na Foundation — impacto direto em retenção percebida como
  justa vs. punitiva.

### Conquistas / marcos
- Eventos que geram o momento de compartilhamento
  (`MENTAL_KICKOFF.md` §6): completar um território, subir de nível, bater
  streak relevante (ex.: 7, 30 dias).
- Cada marco gera um card visual (não apenas texto) pronto para
  compartilhar — ver seção 2.

## 2. Compartilhamento (growth loop)

Dois fluxos distintos, conforme já definidos no kickoff §6 — reproduzidos e
detalhados aqui:

1. **Compartilhar conquista** — card visual gerado ao atingir um marco.
   Decisão técnica (server-side vs. client-side) fica para a Foundation
   (kickoff pede que Claude Code proponha a opção mais simples/barata de
   manter antes de implementar).
2. **Convidar (compartilhar o app)** — ação simples e sempre acessível
   (sugestão: no perfil), usando share sheet nativo (`share_plus` ou
   equivalente) — sem SDK de rede social individual.
   Deep link de convite captura origem, sem sistema de recompensa no V1
   (dado nasce pronto para viabilizar V2).

Ambos os fluxos são sempre opcionais e explícitos — nunca automáticos, nunca
obrigatórios para progredir (`MENTAL_KICKOFF.md` §6, reforçado por
`PRODUCT_PRINCIPLES.md` §3).

## 3. Selo de assinante

Cosmético apenas, visível no perfil — não gera vantagem competitiva no
ranking (`MONETIZATION.md` §2). Importante manter essa fronteira: nenhum
elemento de gamificação pode ser percebido como "pay to win", isso
contradiria a proposta de valor de justiça de resultado
(`PRODUCT_PRINCIPLES.md` §2).

## 4. O que fica para a Foundation decidir

- Fórmula de XP por dificuldade/tipo de desafio.
- Fórmula de nível a partir de XP acumulado.
- Regra de tolerância de streak (freeze ou não).
- Lista definitiva de marcos que geram card de compartilhamento no V1.
