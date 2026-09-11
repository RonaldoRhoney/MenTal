# MENTAL — Nome Real e Foto de Perfil Refletidos em Todos os Menus

**Status:** Implementado (11/09/2026) — ver seção 7.
**Documento relacionado:** FEEDBACK_NOME_REAL_E_TORCIDA_LAYOUT_V1.md (já corrigiu isso especificamente para o mural de Feedback — este documento estende a mesma regra para todo o restante do app, incluindo Painel Admin e notificações de Torcida).

---

## 1. Problema identificado

Print do Painel Admin (ranking de 30 dias) confirma que vários usuários ainda aparecem como "Jogador-XXXXX" (apelido genérico) em vez do nome real cadastrado. O mesmo problema acontece nas notificações de Torcida: quando um usuário recebe uma interação, o nome de quem enviou aparece como código genérico, não como nome real.

Isso é uma inconsistência com decisões já tomadas: nome real já é o padrão público do app desde USER_PROFILE.md, e a correção anterior (FEEDBACK_NOME_REAL_E_TORCIDA_LAYOUT_V1.md) já resolveu isso para o mural de Feedback — mas o mesmo ajuste não foi replicado nos demais pontos do app que também exibem nome de usuário.

## 2. Escopo da correção — nome real em TODO lugar

Aplicar exibição de nome real (nunca "Jogador-XXXXX") em absolutamente todos os pontos do app que hoje mostram nome de usuário, incluindo mas não se limitando a:
- Painel Admin (todos os rankings e listagens, incluindo o de 30 dias mostrado no print).
- Ranking (Global e Amigos).
- Notificações de Torcida (quem enviou a interação).
- Feed (autor de cada evento de conquista).
- Amigos (lista de amigos).
- Batalhas (histórico e adversário).
- Qualquer outro ponto do app, hoje existente ou futuro, que exiba identificação de usuário.

A mesma checagem de bloqueio já aplicada ao Feedback (usuários bloqueados entre si não veem o nome real um do outro) deve valer identicamente em todos esses pontos, sem exceção.

## 3. Escopo da correção — foto de perfil em TODO lugar

Além do nome, a **foto de perfil real do usuário** (quando aprovada, conforme fluxo já existente de moderação de foto) deve aparecer em todos os mesmos pontos listados na seção 2, substituindo o ícone genérico de silhueta hoje usado — Painel Admin, Ranking, notificações de Torcida, Feed, Amigos, Batalhas, e qualquer outro menu que hoje exiba nome de usuário.

Para usuários sem foto aprovada (ainda em análise, ou que optaram por não enviar), manter o ícone genérico atual como estado padrão — a correção é sobre exibir a foto real quando ela existe e está aprovada, não sobre forçar todo usuário a ter foto.

## 4. Princípio geral desta correção

Nome e foto de perfil já são dados públicos por decisão de produto (USER_PROFILE.md). A partir desta correção, **qualquer tela nova criada no futuro que exiba identificação de usuário deve, por padrão, usar nome real + foto real (quando aprovada)**, nunca reintroduzir o apelido genérico como exibição principal — isso deve se tornar um padrão de desenvolvimento consistente daqui em diante, não uma correção pontual a ser refeita a cada nova tela.

## 5. Escopo técnico (alto nível — arquitetura detalhada a propor por Claude Code)

- Identificar todos os pontos do código/frontend que hoje consultam ou exibem o apelido genérico em vez do nome real e da foto de perfil — incluindo Painel Admin, que pode estar numa base de código/consulta diferente do restante do app cliente.
- Centralizar, se ainda não existir, um único componente/função de exibição de identidade de usuário (nome + foto + fallback genérico quando aplicável) reaproveitado em todas as telas — evitando que cada tela implemente essa lógica de forma isolada e inconsistente, o que provavelmente é a causa raiz de esse ajuste não ter se propagado a todos os lugares na correção anterior.
- Aplicar a mesma checagem de bloqueio (`is_blocked_either_way`) em qualquer novo ponto de exibição identificado.

## 6. Critério de aceite

- Nenhum usuário aparece como "Jogador-XXXXX" em nenhuma tela do app, incluindo Painel Admin, quando o usuário tiver nome real cadastrado.
- Foto de perfil real aparece em todos os pontos listados na seção 3, quando aprovada; ícone genérico permanece como fallback apenas para quem não tem foto aprovada.
- Notificações de Torcida exibem nome real (e foto, quando aplicável) de quem enviou a interação.
- Verificação de bloqueio continua valendo em todos esses pontos, sem exceção.
- Nova tela criada a partir de agora, que exiba identificação de usuário, já nasce seguindo esse padrão por default.

## 7. Implementação (11/09/2026)

Investigação encontrou os pontos que ainda não herdavam o padrão
`real_name or nickname` já estabelecido no restante do app (Feed,
`/progress`, `/social/friend-requests`, `battles_screen.dart`,
`friends_screen.dart`):

- `backend/app/services.py` — 5 templates de notificação push usavam
  `.nickname` direto: desafio de Batalha recebido, resultado de Batalha
  (empate/vitória/derrota), território "assumido"/perdido, Torcida
  recebida, convite de Movimento. Todos corrigidos pra
  `profile.real_name or profile.nickname`.
- `backend/app/schemas.py` / `routers/profile.py` —
  `AdminPendingPhotoItem` (moderação de foto no Painel Admin, criada em
  07/09/2026 durante a correção de "nome e foto visíveis") não incluía
  `real_name`. Campo adicionado.
- `client/lib/screens/admin_metrics_screen.dart` — `_PendingPhotoRow`
  exibia `nickname` cru. Extraída a função `_displayName()`
  (reaproveitada também por `_TopProgressorTile`, que já tinha a mesma
  lógica duplicada inline) pra centralizar o fallback nome real → apelido.
- `store_assets/mental-privacidade.html` (§2.3) — corrigida a frase que
  dizia que o mural de Feedback mostra "o apelido de quem enviou": hoje
  mostra o nome real, com fallback pro apelido só se o nome real ainda
  não tiver sido preenchido (comportamento já implementado desde
  FEEDBACK_NOME_REAL_E_TORCIDA_LAYOUT_V1.md, a política é que estava
  desatualizada).

Suíte: 398/398 backend (2 testes novos), 152/152 client (1 teste novo).
Nenhum ponto adicional de exibição de nome de usuário sem o fallback
`real_name` foi encontrado na varredura.
