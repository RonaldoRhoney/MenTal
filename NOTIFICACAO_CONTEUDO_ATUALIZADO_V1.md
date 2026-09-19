# MENTAL — Notificação de Conteúdo Gamificado Atualizado (Mundos/SubMundos/Desafios/Relâmpagos)

**Status:** IMPLEMENTADO (19/09/2026). Integra-se à Central de Notificações já formalizada (CENTRAL_DE_NOTIFICACOES_HOME_V1.md) como um novo tipo de notificação — não é um elemento visual separado, nem um novo sistema paralelo.

## Decisões confirmadas com Rhoney (19/09/2026)

- Granularidade: por **Território inteiro** (nunca por Desafio individual) — evita enxurrada de notificações quando uma correção em massa (como a Auditoria Global de Conteúdo já feita) toca centenas/milhares de itens de uma vez.
- Retroatividade: **não** — `Territory.content_updated_at` nasce `null` pra todo território já existente. A auditoria de conteúdo já feita nesta sessão (Copa/Futebol, territórios de leitura, bloco Internet) NÃO dispara essa notificação — o campo só passa a ser preenchido a partir de agora, por scripts de carga/correção futuros.

## O que foi implementado

- `backend/migrations/081_territory_content_updated_at.sql` + `models.Territory.content_updated_at` (nullable, null por padrão).
- `services.touch_territory_content_updated(db, territory_ids)` — único ponto que grava o campo, chamado ao fim de `scripts/append_production_content.py` (conteúdo novo) e `scripts/apply_content_audit_fixes.py` (correção de itens já publicados), só pros territórios de fato tocados na rodada.
- `services.notify_content_updated_if_needed(db, profile)` — chamado dentro de `GET /progress`, ANTES de `update_last_seen` sobrescrever `Profile.last_seen_at`. Compara o `last_seen_at` ANTIGO contra `Territory.content_updated_at`; sem estado de dedup extra (o próprio avanço de `last_seen_at` a cada chamada evita repetição). Nunca dispara pra quem nunca logou antes (`last_seen_at` null).
- Corpo da notificação nomeia sempre **Mundos** (nunca Desafio/território cru) — 1 território atualizado → nome do Mundo dele; múltiplos → lista de Mundos únicos, separados por vírgula.
- Deep-link (`data.navigate`): 1 território atualizado → `"territory"` + `territory_id`, abre o Desafio daquele território direto (`client/lib/screens/notifications_screen.dart`, reaproveitando `territoryLabel()` já usado em `home_screen.dart`); múltiplos territórios → `"progress"` (tela de Mundos já existente), já que não há um destino único possível.
- Só gera a linha na Central por enquanto — sem push (não existe preferência de push dedicada pra conteúdo hoje, e o documento não exige push explicitamente).
- Testes: `backend/tests/` (suíte completa) e `client/test/notifications_screen_test.dart` (novo teste do deep-link de território) — sem regressão.

## Pendente / próximo passo

- `apply_content_audit_fixes.py` também ganhou o hook, mas só terá efeito na PRÓXIMA vez que rodar — a rodada já executada nesta sessão não retroage (decisão acima).
- Migration 081 precisa rodar em produção antes do próximo deploy do backend.

---

## 1. Objetivo

Quando o usuário atualiza o app (nova versão) e faz login em seguida, ele deve ser avisado, de forma clara e destacada, sobre qual conteúdo gamificado foi alterado desde a última vez que usou o app — seja Mundo, SubMundo, Bloco, Desafio ou Relâmpago — para que ele saiba exatamente onde encontrar as novidades ou correções, sem precisar procurar por conta própria.

## 2. Gatilho — quando a notificação deve surgir

- A notificação surge **apenas quando houve uma atualização real de conteúdo gamificado**, disparada no **próximo login do usuário após a atualização ter sido publicada** — nunca de forma recorrente, repetitiva ou "toda hora", conforme reforçado explicitamente por Rhoney.
- Cobre **qualquer tipo de atualização de conteúdo gamificado**, sem distinção entre motivo — inclui tanto conteúdo **novo** (Mundo/SubMundo/Desafio/Relâmpago recém-adicionado) quanto conteúdo **corrigido** (ex.: perguntas/respostas ajustadas a partir da Auditoria Global de Conteúdo, ou qualquer outra correção de conteúdo já publicado).
- Se não houve nenhuma atualização de conteúdo desde o último acesso do usuário, nenhuma notificação desse tipo deve ser gerada — a ausência de novidade é o estado padrão, não a exceção.

## 3. Onde a notificação aparece

- **Integrada à Central de Notificações** já especificada em CENTRAL_DE_NOTIFICACOES_HOME_V1.md — este documento define um **novo tipo de notificação** dentro daquele sistema já aprovado, não um componente visual separado.
- Segue o mesmo comportamento já definido para a Central: ícone de sino na Home com indicador de não lida, histórico persistente por um período, opção de "marcar todas como lidas", e navegação direta ao tocar na notificação.
- Ao tocar nesta notificação específica, o usuário deve ser levado diretamente ao Mundo/SubMundo/Desafio/Relâmpago que foi atualizado — mesmo princípio de navegação direta já estabelecido para outras notificações do app (ex.: notificação de Movimento leva direto à tela de Movimentos).

## 4. Conteúdo da notificação

- Deve identificar claramente **qual conteúdo específico** foi atualizado (nome do Mundo/SubMundo/Desafio/Relâmpago), não uma mensagem genérica do tipo "o app foi atualizado".
- Se múltiplos conteúdos foram atualizados na mesma versão, avaliar se agrupa numa única notificação (ex.: "3 Desafios foram atualizados: [lista]") ou gera uma notificação por item — Claude Code deve propor a abordagem mais adequada tecnicamente, priorizando não sobrecarregar a Central com muitas notificações separadas de uma vez só.

## 5. Escopo técnico (a propor em detalhe por Claude Code)

- Definir como o sistema identifica, tecnicamente, que um Mundo/SubMundo/Desafio/Relâmpago foi "atualizado" desde o último acesso do usuário (ex.: timestamp de última modificação no conteúdo, comparado ao timestamp do último login do usuário).
- Gerar a notificação correspondente na Central de Notificações no momento do primeiro login após a atualização, para cada usuário individualmente (o "desde a última vez que ESTE usuário acessou", não uma data fixa global).
- Garantir que a notificação não seja duplicada em logins subsequentes, uma vez já gerada e/ou lida.
- Implementar a navegação direta ao conteúdo específico a partir do toque na notificação.

## 6. Critério de aceite

- Notificação aparece na Central apenas quando há atualização real de conteúdo gamificado, no primeiro login do usuário após essa atualização.
- Nenhuma notificação recorrente ou repetitiva é gerada sem uma atualização real correspondente.
- Notificação identifica claramente qual conteúdo foi atualizado.
- Tocar na notificação leva o usuário diretamente ao Mundo/SubMundo/Desafio/Relâmpago correspondente.
- Comportamento de leitura/histórico segue exatamente o já definido para a Central de Notificações, sem lógica de dispensa duplicada ou divergente.
