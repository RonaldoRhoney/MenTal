# MENTAL — Torcida com Múltiplos Incentivos Visuais (evolução de Torcida)

**Status:** Aprovado para formalização de escopo.
**Substitui/expande:** a seção 4 (Torcida) de PERFIL_PUBLICO_E_TORCIDA_V1.md, que previa uma única reação genérica. Este documento formaliza a expansão para múltiplos tipos de incentivo visual, mantendo todos os demais princípios daquele documento (acesso a partir de ponto de contato prévio, dados exibidos, escopo de "ajudar" fora desta entrega).

---

## 1. Conceito

Ao visitar o perfil público de outro usuário (fluxo já definido em PERFIL_PUBLICO_E_TORCIDA_V1.md — acesso a partir de Ranking, Amigos, Batalhas ou Hall da Fama), o usuário pode enviar um ou mais **incentivos visuais pré-definidos**, demonstrando torcida/apoio. **Nunca texto livre, nunca comentário** — este é o princípio inegociável de toda a feature, reforçado explicitamente nesta expansão.

## 2. Tipos de incentivo (conjunto inicial)

- **Vibração** — ícone de celebração/energia (ex.: raio ou estrela, a definir na curadoria visual).
- **Balão** — ícone de balão festivo.
- **Coraçãozinho** — ícone de coração.
- **Joinha** — ícone de polegar para cima.

Cada tipo é um botão/ícone próprio na tela de perfil — não um menu de texto, não um campo de digitação. O conjunto pode ser expandido no futuro (ex.: mais ícones), mas o princípio de "sempre ícone pré-definido, nunca texto" nunca muda.

## 3. Regras de uso

- **Múltiplos incentivos por visita são permitidos** — o usuário pode enviar mais de um tipo (ex.: coraçãozinho e joinha) ao mesmo jogador na mesma visita ou em visitas diferentes, sem excluir uma opção por causa da outra.
- **Limite diário por usuário-alvo** — mesmo princípio já definido em PERFIL_PUBLICO_E_TORCIDA_V1.md (seção 4): limite razoável de envios por dia para um mesmo destinatário, a definir com Claude Code, evitando volume excessivo mesmo sendo conteúdo positivo.
- **Sem limite diferenciado por tipo de ícone nesta entrega** — o limite é agregado (soma de todos os tipos enviados a uma mesma pessoa no dia), não um limite separado por vibração/balão/coração/joinha. Se necessário ajustar depois, é decisão futura de curadoria de produto.

## 4. Notificação ao destinatário

- O destinatário recebe uma notificação simples informando que recebeu um incentivo, incluindo qual tipo foi enviado (ex.: "Fulano te mandou um 💚" ou equivalente visual) — mesmo padrão não-humilhante já usado em Batalhas e Disputa Territorial.
- Nunca combina múltiplos incentivos numa mensagem só se forem enviados em momentos diferentes — cada envio gera sua própria notificação.

## 5. O que continua fora de escopo (reforço do documento original)

- **Nunca texto livre ou comentário**, sob nenhuma circunstância — nem como opção adicional, nem como "legenda" de um incentivo visual.
- **"Ajudar" de forma mais ativa** (mensagem, doação de XP, dica) permanece fora de escopo, exatamente como já registrado em PERFIL_PUBLICO_E_TORCIDA_V1.md seção 5 — este documento expande apenas o leque de reações visuais, não abre a porta para texto.

## 6. Escopo técnico (alto nível — arquitetura detalhada a propor por Claude Code)

- Reaproveita a estrutura de dado já prevista para Torcida (quem enviou, para quem, quando) — apenas adiciona um campo de "tipo de incentivo" em vez de um único tipo fixo.
- Autoridade sobre limite diário e validação de envio permanece 100% no backend.
- Curadoria visual dos 4 ícones deve seguir a identidade visual já estabelecida no app (paleta de conquista definida em Home/Movimento).

## 7. Critério de aceite

- Usuário consegue enviar qualquer um dos 4 tipos de incentivo ao visitar o perfil de outro usuário.
- Múltiplos tipos podem ser enviados à mesma pessoa, respeitando o limite diário agregado.
- Nenhum campo de texto livre ou comentário existe em qualquer parte deste fluxo.
- Destinatário recebe notificação identificando o tipo de incentivo recebido.
- Fluxo de acesso ao perfil (a partir de ponto de contato prévio) permanece inalterado, conforme PERFIL_PUBLICO_E_TORCIDA_V1.md.
