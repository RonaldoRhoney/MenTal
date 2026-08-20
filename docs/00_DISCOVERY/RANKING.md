# MENTAL — RANKING.md

Status: rascunho de Discovery, para aprovação de Rhoney.

## 1. Por que ranking existe

O `MONETIZATION.md` §2 já estabelece que "ranking e ranking de amigos sempre
visíveis" fazem parte do free — ranking não é feature paga, é parte do
core loop social que sustenta retenção (jogador volta para ver posição
mudar) sem depender de mídia paga (Free-First, `MENTAL_KICKOFF.md` §6).

## 2. Tipos de ranking no V1

- **Ranking geral** — todos os jogadores, por XP acumulado (janela de tempo
  a definir: total histórico vs. semanal/mensal — ranking só-histórico
  favorece quem chegou primeiro e desmotiva jogador novo; ranking com janela
  recorrente é mais justo para engajamento contínuo. Recomendação para
  Foundation: ranking semanal como padrão, com opção de ver "todos os
  tempos").
- **Ranking de amigos** — subconjunto do ranking geral filtrado por conexões
  do jogador. Depende de como "amigo" é modelado (via convite/deep link
  aceito, ou via conexão explícita) — a definir na Foundation junto com
  `DATA_MODEL.md`.

## 3. Regra técnica

Mesma regra de autoridade do backend já estabelecida (`MENTAL_KICKOFF.md`
§2, `MONETIZATION.md` §3): posição no ranking é sempre calculada e servida
pelo backend, nunca composta ou ordenada no cliente a partir de dado bruto
que possa ser adulterado.

## 4. Cuidado de privacidade (conecta com `FAMILY_SAFETY.md`)

- Ranking geral não deve expor dado pessoal além de nome de exibição
  (nickname) e XP — nunca email, nunca idade, nunca localização.
- Para usuário confirmado como criança ou com idade desconhecida, considerar
  se ranking geral (não só de amigos) deve exibir o nickname publicamente ou
  se precisa de configuração adicional de privacidade — ponto a levar para
  `SECURITY.md` na Foundation, listado também em
  `RISKS_AND_OPEN_DECISIONS.md`.

## 5. O que fica para a Foundation decidir

- Janela de tempo do ranking geral (semanal vs. histórico).
- Modelagem de "amigo" no `DATA_MODEL.md`.
- Regra de exibição de nickname para perfil de criança/idade desconhecida.
