# MENTAL — BRAND.md

Status: aprovado por Rhoney (dono). Parte oficial da Foundation.

## 1. O nome — decisão deliberada, não ingênua

"MENTAL" foi escolhido de propósito para **ressignificar** a palavra. No uso
coloquial do português brasileiro, "mental" solto carrega conotação negativa
("ele é meio mental" = tolice, desequilíbrio). O produto existe para inverter
esse significado: aqui, **mental é quem usa a mente para buscar e conquistar
algo de valor** — o oposto da gíria.

Isso é uma escolha de branding por reapropriação semântica: usar a
experiência do produto para devolver à palavra seu significado literal e
positivo. Não é um risco a esconder — é a tese central da marca, e precisa
ser reforçada ativamente em todo ponto de contato, não deixada para o usuário
inferir sozinho.

**Regra vinculante:** o nome MENTAL nunca aparece completamente sozinho, sem
o slogan por perto, em nenhum primeiro contato com um usuário novo — ícone da
Play Store com texto de apoio, listing da loja, splash screen, cards de
compartilhamento, qualquer peça de marketing. A ressignificação só funciona
se o significado pretendido estiver sempre próximo do nome até a marca
ganhar peso próprio.

## 2. Slogan oficial

> **Mental é quem conquista com a mente.**

Substitui "Jogue. Pense. Evolua." como assinatura principal da marca. Amarra
três coisas em uma frase: a ressignificação do nome, o significado que a
marca declara para a palavra, e a mecânica central do jogo (conquista de
território através de desempenho cognitivo).

Uso:
- Slogan principal: sempre junto ao nome em primeiros contatos (splash,
  ícone com texto de apoio, listing da Play Store, material de marketing).
- "Jogue. Pense. Evolua." pode ser reaproveitado como tagline secundária
  dentro do app (ex: em telas de onboarding, não na primeira tela) — não é
  descartado, apenas não é mais a assinatura de primeiro contato.

## 3. Splash screen — sequência obrigatória

A splash é o momento de maior impacto de marca e precisa carregar a
ressignificação do nome antes de qualquer outra informação. Sequência:

1. Fundo escuro, wordmark "MENTAL" central, peso tipográfico forte, sozinho
   (≈1-2s).
2. Slogan "Mental é quem conquista com a mente." aparece abaixo, mais
   discreto (≈+1s).
3. Transição direta para login/onboarding — sem terceira tela, sem telas de
   propaganda adicionais.

Duração total da sequência deve ser curta o suficiente para não violar as
diretrizes de qualidade do Google Play sobre splash screens sem propósito
funcional (não usar para carregar anúncio, não estender artificialmente).

## 4. Identidade de marca-filha

MENTAL é uma marca-filha da RhoneyInc (ver `MENTAL_KICKOFF.md`, Seção 3):
identidade visual e posicionamento próprios, não estilizada como os produtos
B2B/utilitários. Este documento (`BRAND.md`) é a fonte de verdade para nome,
slogan e primeiro contato visual — qualquer peça de marketing ou submissão
à Play Store deve ser consistente com ele.

## 5. Papel de cada parte

- **Rhoney**: aprovou nome e slogan; qualquer alteração futura de marca passa
  por ele antes de qualquer implementação.
- **Claude (arquitetura)**: garante que a regra da Seção 1 (nome nunca
  sozinho sem slogan em primeiro contato) é seguida em toda peça de UI e
  marketing revisada antes de ir ao Claude Code.
- **Claude Code**: implementa a splash screen conforme a sequência da Seção
  3, e usa o slogan oficial (Seção 2) em qualquer tela, ícone ou card de
  compartilhamento gerado no app — nunca inventa variação própria de slogan.
