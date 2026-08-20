# MENTAL — VISION.md

Status: rascunho de Discovery, para aprovação de Rhoney.

## 1. Problema

Jogos mobile de "treino cerebral" tendem a cair em um de dois extremos:
- Apps genéricos de puzzle sem identidade, indistinguíveis entre si,
  monetizados de forma agressiva com anúncio intrusivo.
- Apps educacionais sérios demais, que parecem estudo disfarçado e não
  prendem pelo prazer do jogo.

Nenhum dos dois entrega a sensação de **progresso e conquista pessoal**
através do uso da mente, para um público que vai de criança a idoso, de
forma simples o bastante para não precisar de tutorial longo.

## 2. Objetivo do produto

Entregar um jogo mobile gratuito-primeiro, de desafios cognitivos curtos
(palavras, números, lógica, conhecimentos gerais), onde o jogador **conquista
território** através de desempenho — tornando o esforço mental visível,
recompensador e compartilhável, sem nunca parecer "estudar" ou "treinar".

## 3. Público

Público misto, deliberadamente (ver `FAMILY_SAFETY.md`): de crianças a
idosos, com dificuldade adaptada a cada jogador. Não é um app infantil
exclusivo nem um app adulto exclusivo — é desenhado para funcionar bem nos
dois extremos e em todos os pontos entre eles.

Implicação direta: linguagem, arte e ritmo de jogo não podem assumir
letramento avançado nem pressupor familiaridade com jogos mobile complexos.
A curva de entrada precisa ser imediata (ver `PRODUCT_PRINCIPLES.md`).

## 4. Proposta de valor

> Conquiste território com a sua mente. Jogue todo dia, veja seu progresso
> crescer, e mostre o que você conquistou.

Três pilares que sustentam essa proposta:
1. **Mecânica simples, sessão curta** — cabe em qualquer intervalo do dia,
   não exige planejamento nem tempo dedicado.
2. **Progresso visível e territorial** — diferente de um placar abstrato,
   "conquistar território" é uma metáfora espacial fácil de entender em
   qualquer idade e gera um artefato visual bom para compartilhar.
3. **Justiça de resultado** — o backend é a única autoridade sobre
   score/XP/desbloqueio (`MENTAL_KICKOFF.md` §2, `MONETIZATION.md` §3); o
   jogador confia que o resultado é real, não manipulável.

## 5. Por que agora / por que RhoneyInc

MENTAL é a primeira marca-filha de consumer entertainment da RhoneyInc,
distinta dos produtos B2B/utilitários já existentes (MenuFlex, VendeFlex,
MeuPet). Reaproveita a infraestrutura de identidade compartilhada
("Uma conta, todos os softwares" — Supabase Auth central), mas com banco de
dados de jogo isolado (`MENTAL_KICKOFF.md` §2), sem misturar escopo de
negócio com os demais produtos.

## 6. Fora de escopo (V1 e além, ver também `MENTAL_KICKOFF.md` §10)

- IA generativa de conteúdo.
- Batalha em tempo real entre jogadores.
- Versão Web (prevista na arquitetura, não implementada no V1).
- Moeda virtual.
- Chat entre jogadores.
- Disputa territorial ativa entre jogadores (a "conquista" no V1 é contra o
  próprio desempenho/progresso, não PvP).
- Sistema de recompensa por indicação (o dado de origem de convite é
  capturado desde o V1, mas a recompensa em si é V2+).
