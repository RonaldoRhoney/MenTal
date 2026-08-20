# MENTAL — ADAPTIVE_DIFFICULTY.md

Status: rascunho de Discovery, para aprovação de Rhoney.

## 1. Por que dificuldade adaptativa é requisito, não extra

O público é misto — de criança a idoso (`FAMILY_SAFETY.md` §1) — e o
kickoff já trata "dificuldade adaptativa" como parte do que torna a
declaração de Target Audience honesta perante o Google Play
(`FAMILY_SAFETY.md` §6: "dificuldade adaptativa e conteúdo apropriado por
idade não são nice to have, são requisito de submissão honesta"). Ou seja:
sem isso, a app não pode alegar de boa-fé que serve esse público inteiro.

## 2. O que adapta

- **Nível de dificuldade do próximo desafio dentro de um território**, com
  base no desempenho recente do jogador naquele território (acertos,
  erros, uso de dica, tempo de resposta se vier a ser capturado).
- Não adapta o *tipo* de desafio (isso é escolha do jogador, ao selecionar
  território) — só a dificuldade dentro do tipo escolhido.

## 3. Sinal de entrada (proposta)

Backend mantém, por jogador e por território, um indicador de desempenho
recente (ex.: taxa de acerto numa janela móvel dos últimos N desafios
daquele território). O próximo desafio servido é escolhido dentro de uma
faixa de dificuldade compatível com esse indicador — sobe gradualmente após
acertos consistentes, desce após erros consecutivos, sem saltos bruscos que
frustrem ou entediem.

Fórmula exata e valor de N: aberto, decisão de Foundation/implementação —
aqui fica só o princípio de que deve ser suave e baseado em janela recente,
não em desempenho histórico total (que penalizaria um dia ruim
permanentemente).

## 4. Regra técnica

Cálculo e decisão de qual desafio servir a seguir são exclusivos do backend
(mesma regra de autoridade central já repetida em todos os documentos de
origem) — o cliente Flutter só solicita "próximo desafio" e recebe o que o
backend decidiu, nunca escolhe nível de dificuldade sozinho.

## 5. Relação com percepção de justiça

Dificuldade adaptativa não pode ser confundida com manipulação de
dificuldade para forçar assinatura (ex.: nunca tornar o free
artificialmente mais difícil para empurrar conversão) — isso violaria tanto
`PRODUCT_PRINCIPLES.md` §3 (não-manipulação) quanto a percepção de justiça
de resultado (§2). A adaptação serve exclusivamente ao ajuste de
experiência ao jogador, nunca a alavancar monetização.

## 6. O que fica para a Foundation decidir

- Fórmula exata de ajuste de dificuldade (janela, limiares de subida/descida).
- Se dado de tempo de resposta é capturado no V1 ou fica para depois.
- Faixas de dificuldade por território (quantos níveis existem).
