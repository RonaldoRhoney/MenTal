# MENTAL — Ranking Enriquecido: Conquistas, MentalCoins e Passos por Jogador

**Status:** Aprovado para implementação.
**Referência visual:** ranking_enriquecido.html (protótipo estático HTML/CSS — reproduzir estrutura, hierarquia, cores e proporções exatamente como demonstrado).
**Documento relacionado:** PERFIL_PUBLICO_E_TORCIDA_V1.md — o toque em qualquer linha do Ranking leva ao perfil público completo já especificado naquele documento; este documento trata apenas do enriquecimento visual da lista do Ranking em si.

---

## 1. Objetivo

O Ranking hoje mostra apenas nome e XP de cada jogador — informação pobre demais para transmitir o desempenho real de cada um. Esta especificação exige que cada linha do Ranking mostre um resumo rico das conquistas do jogador, tornando a tela mais intuitiva, elegante e informativa, sem exigir que o usuário abra o perfil de cada pessoa para entender o quanto ela evoluiu.

## 2. O que cada linha do Ranking deve exibir

Além do que já existe hoje (posição, avatar, nome, XP), cada linha passa a exibir um conjunto de badges compactas com:

- 🔥 **Streak atual** (sequência de dias) do jogador.
- 🌍 **Mundos completos**, no formato "completos/total" (ex.: "2/4").
- 🏆 **Total de conquistas/badges** obtidas pelo jogador.
- 🪙 **MentalCoins conquistados**, usando o ícone oficial do MentalCoins (círculo dourado com a letra "M", o mesmo já usado no card de identidade da Home) — não um emoji de moeda genérico.
- 👟 **Total de passos** registrados pelo jogador (via Movimento), em formato compacto (ex.: "8.4k").

## 3. Destaque visual para o 1º lugar

- A linha do 1º colocado recebe tratamento visual diferenciado: ícone de coroa, borda dourada ao redor do avatar, e fundo do card com gradiente sutil na paleta de conquista (dourado/âmbar) — reforçando a sensação de topo do ranking sem comprometer a legibilidade das demais linhas.

## 4. Indicação clara de que a linha é interativa

- Cada linha do Ranking deve ter uma seta (chevron) ao final, sinalizando visualmente que é possível tocar para ver mais.
- Uma dica textual breve deve aparecer no topo da lista (ex.: "Toque em qualquer jogador para ver o desempenho completo"), orientando o usuário sobre essa interação.
- Ao tocar em qualquer linha, o app deve abrir o perfil público completo daquele jogador, reaproveitando o fluxo e as regras já definidas em PERFIL_PUBLICO_E_TORCIDA_V1.md — este documento não altera nada daquela especificação, apenas reforça que o Ranking passa a ser um dos pontos de entrada visuais para ela.

## 5. Padrão visual

- Badges compactas ("pills"), organizadas em linha abaixo do nome do jogador, com quebra automática para a linha seguinte caso não caibam todas no mesmo espaço horizontal (telas menores).
- Paleta de conquista já estabelecida no app (dourado/âmbar para destaque e vitória, teal/verde-água para elementos regulares), sem introduzir cores novas fora do padrão já existente.
- Selo de nível sobreposto ao avatar de cada jogador (mesmo padrão já usado no card de identidade da Home).

## 6. Escopo técnico (alto nível — arquitetura detalhada a propor por Claude Code)

- O endpoint que já alimenta o Ranking hoje deve ser expandido para retornar, junto com nome e XP, os dados adicionais necessários para as badges (streak, Mundos completos/total, contagem de conquistas, saldo de MentalCoins, total de passos) — sempre a partir de dados já existentes no backend, sem necessidade de nova lógica de cálculo, apenas de exposição desses campos já calculados em outras telas.
- Nenhum dado sensível deve ser exposto no Ranking — apenas os mesmos dados já públicos usados no perfil (mesmo princípio de PERFIL_PUBLICO_E_TORCIDA_V1.md e USER_PROFILE.md).
- Ícone de MentalCoins deve reaproveitar o asset visual já existente no app (o mesmo círculo dourado com "M"), não recriar um ícone novo do zero.

## 7. Critério de aceite

- Cada linha do Ranking exibe corretamente streak, Mundos completos, conquistas, MentalCoins (com ícone oficial "M") e passos totais do jogador.
- O 1º colocado tem destaque visual diferenciado (coroa, borda dourada, fundo em gradiente).
- Todas as linhas têm indicação visual de que são tocáveis (chevron), e o toque leva ao perfil público completo já especificado em PERFIL_PUBLICO_E_TORCIDA_V1.md.
- Badges quebram linha corretamente em telas menores, sem cortar informação nem quebrar o layout.
- Nenhuma cor fora da paleta padrão do app foi introduzida.
