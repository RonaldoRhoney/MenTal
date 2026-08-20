# MENTAL — HINT_ENGINE.md

Status: rascunho de Discovery, para aprovação de Rhoney.

## 1. Papel da dica no produto

A dica existe para manter o jogador dentro do loop sem frustração, sem
transformar o jogo em teste de "acertar ou falhar". É parte de por que
MENTAL não parece "estudar" (`VISION.md` §1) — errar não é beco sem saída,
é convite a pensar de novo com uma pista.

Uso de dica é sempre opcional (`CORE_LOOP.md` §4) e nunca é pré-requisito
para responder.

## 2. Estrutura: dicas progressivas

- Cada desafio tem uma sequência de dicas, da mais sutil para a mais
  explícita (ex.: dica 1 elimina uma opção errada / dá uma pista indireta;
  dica 2 aproxima mais da resposta).
- Quantidade de dicas por desafio no free é limitada; assinatura libera
  "quantidade maior de dicas progressivas" (`MONETIZATION.md` §2) — o
  mecanismo de dica já existe no free, a assinatura amplia, não introduz do
  zero.
- Pedir dica tem custo dentro do jogo (proposta para Foundation avaliar:
  reduz o XP ganho naquele desafio, proporcional ao número de dicas usadas)
  — mantém a dica útil sem torná-la "resposta de graça", preservando
  justiça de resultado (`PRODUCT_PRINCIPLES.md` §2).

## 3. Regra técnica

Mesma regra de autoridade do backend: o conteúdo da dica e a contagem de
dicas usadas/disponíveis são servidos e controlados pelo backend, nunca
pré-carregados de forma que o cliente possa expor a resposta antes da hora
(ex.: não enviar a resposta correta ao cliente antes da confirmação —
apenas o conteúdo da dica). Ponto de atenção de segurança a levar para
`SECURITY.md`/`API_CONTRACT.md` na Foundation.

## 4. Relação com dificuldade adaptativa

O hint engine e a dificuldade adaptativa (`ADAPTIVE_DIFFICULTY.md`)
compartilham o mesmo sinal de entrada (desempenho do jogador), mas agem em
momentos diferentes: dificuldade adaptativa decide *qual* desafio oferecer a
seguir; hint engine ajuda *dentro* do desafio já oferecido. Não confundir os
dois na Foundation — são dois componentes de backend distintos, mesmo que
consumam dado semelhante.

## 5. O que fica para a Foundation decidir

- Número de níveis de dica por desafio (2? 3?).
- Fórmula de penalidade de XP por dica usada, se houver.
- Quantidade de dicas disponíveis no free vs. assinatura.
