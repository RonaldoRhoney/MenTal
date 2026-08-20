# MENTAL — GAMEPLAY.md

Status: rascunho de Discovery, para aprovação de Rhoney.
Escopo: apenas os 4 tipos de desafio do Vertical Slice 01
(`MENTAL_KICKOFF.md` §10).

## 1. Formato comum aos 4 tipos

Para manter a Clareza Imediata (`PRODUCT_PRINCIPLES.md` §1), todo desafio
segue a mesma estrutura de tela, independente do tipo:

- Um enunciado central, curto.
- Um conjunto de opções de resposta (múltipla escolha) OU um campo de
  resposta curta — a definir por tipo abaixo, nunca os dois misturados na
  mesma tela.
- Um único CTA de confirmar resposta.
- Acesso opcional a dica (ícone discreto, não compete com o CTA principal).
- Tempo de resposta: sem timer visível agressivo no V1 (contraria
  não-manipulação, `PRODUCT_PRINCIPLES.md` §3) — decisão de ter ou não
  cronômetro fica registrada como ponto aberto em
  `RISKS_AND_OPEN_DECISIONS.md`.

## 2. Os 4 tipos de desafio

### Palavras
- Exemplos de mecânica: anagrama, palavra oculta, sinônimo/antônimo,
  completar a palavra.
- Formato de resposta: múltipla escolha ou digitação curta, dependendo da
  mecânica específica.
- Adaptação por idade/dificuldade: tamanho e frequência de uso da palavra
  no português (palavras mais comuns para dificuldade menor).

### Números
- Exemplos de mecânica: sequência lógica numérica, operação aritmética,
  estimativa.
- Formato de resposta: múltipla escolha ou campo numérico.
- Adaptação por idade/dificuldade: complexidade da operação (soma simples
  → múltiplas operações) e tamanho dos números envolvidos.

### Lógica
- Exemplos de mecânica: padrão visual/sequencial, dedução simples,
  classificação ("qual não pertence ao grupo").
- Formato de resposta: múltipla escolha.
- Território "avançado" por padrão (`MONETIZATION.md` §2) — liberado com
  assinatura, salvo os primeiros desafios de amostra gratuitos.

### Conhecimentos gerais
- Exemplos de mecânica: pergunta objetiva de cultura geral, curiosidade.
- Formato de resposta: múltipla escolha.
- Risco de conteúdo a controlar na Foundation: fonte do banco de perguntas
  precisa ser curada para não introduzir viés, desatualização ou conteúdo
  inadequado a criança — ver `RISKS_AND_OPEN_DECISIONS.md`.
- Território "avançado" por padrão (`MONETIZATION.md` §2).

## 3. Regras comuns de correção

- Resposta correta: sempre unívoca por desafio (sem ambiguidade de múltipla
  resposta "quase certa" no V1 — isso simplifica a validação no backend e
  evita disputa de jogador sobre resultado).
- Todo desafio tem explicação da resposta correta, exibida após a resposta
  do jogador, certa ou errada (`CORE_LOOP.md` §2).
- Nenhum desafio depende de conteúdo gerado em tempo real por IA no V1
  (fora de escopo, `MENTAL_KICKOFF.md` §10) — banco de desafios é
  pré-produzido/curado.

## 4. O que fica para a Foundation decidir

- Formato exato de armazenamento do banco de desafios (schema).
- Quantidade mínima de desafios por tipo necessária para lançar o V1 sem
  repetição perceptível em uso diário.
- Se existe cronômetro visível ou não (ver `RISKS_AND_OPEN_DECISIONS.md`).
