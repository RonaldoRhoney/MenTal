# MENTAL — TERRITORIES.md

Status: rascunho de Discovery, para aprovação de Rhoney.

## 1. O que é um território

Território é a unidade de progresso e a metáfora central da marca — não é
apenas uma "categoria de pergunta", é o que o jogador conquista com
desempenho. Cada território está associado a um tipo de desafio
(`GAMEPLAY.md`), mas o território é a camada de jogo (progresso, XP,
desbloqueio); o tipo de desafio é a camada de conteúdo.

## 2. Mapeamento V1

| Território | Tipo de desafio | Acesso (sugestão `MONETIZATION.md` §2) |
|---|---|---|
| Palavras | Palavras | Free |
| Números | Números | Free |
| Lógica | Lógica | Assinatura (com amostra free) |
| Conhecimento | Conhecimentos gerais | Assinatura (com amostra free) |

A régua exata de quantos territórios ficam free vs. pagos é decisão final de
Rhoney antes do lançamento (`MONETIZATION.md` §7) — esta tabela é a proposta
inicial já sinalizada no material de origem, não uma decisão nova.

## 3. Condição de conquista de um território

Proposta para Discovery (a formalizar como regra de negócio na Foundation):
um território é "conquistado" (não apenas "iniciado") ao atingir um limiar
de XP ou de desafios corretos consecutivos dentro dele — o suficiente para
gerar um momento de marco compartilhável (ver `GAMIFICATION.md`), mas sem
exigir domínio perfeito (isso desmotivaria o jogador casual, contra o
princípio de gratuito-primeiro-e-joga-bem).

Valor exato do limiar: aberto, fica para a Foundation com base em curva de
dificuldade adaptativa (`ADAPTIVE_DIFFICULTY.md`).

## 4. Territórios avançados (V2+)

O kickoff (§10) menciona explicitamente que novos territórios entram em V2.
A arquitetura de dados (mapeamento território↔plano) precisa nascer
extensível — adicionar um território novo não pode exigir mudança de schema,
apenas um novo registro (ponto para `DATA_MODEL.md` na Foundation).

## 5. Território e ranking

Progresso por território alimenta o ranking (`RANKING.md`) — ranking geral
provavelmente soma XP entre territórios, não compete território por
território no V1 (simplicidade > sofisticação, `PRODUCT_PRINCIPLES.md` §7).
A definir na Foundation.

## 6. O que território não é no V1

- Não é um espaço geográfico/mapa disputado entre jogadores (isso seria
  disputa territorial ativa, fora de escopo do V1 — `MENTAL_KICKOFF.md`
  §10).
- Não tem elemento de tempo real ou PvP.
