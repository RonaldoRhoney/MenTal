# MENTAL — Central de Notificações na Home

**Status:** IMPLEMENTADO (14/09/2026). Interpretação da seção 1 confirmada por Rhoney antes de iniciar: histórico persistente de verdade, não um atalho visual sem memória.

## O que foi implementado

- `mental.notifications` (nova tabela, `migrations/075_notifications_central.sql`) — uma linha por evento notificável, com tipo, título, corpo, payload de navegação (`data`) e estado de leitura (`read_at`).
- `services.create_notification()` — ponto único que grava a Central E, opcionalmente, dispara o push (que **continua existindo normalmente**, seção 3, nunca substituído). A linha da Central é criada **sempre**, mesmo quando o push não é enviado (preferência desligada, sem token) — a Central nunca depende do FCM.
- Todas as origens já existentes foram unificadas nesse ponto único (seção 4): Batalha (desafio recebido, sua vez de jogar, resultado), Torcida, Movimento (convite, relatório de ciclo, convite diário de ativação), disputa territorial, reengajamento (24h/48h), ultrapassagem no ranking semanal — e duas origens que **nunca tinham nenhum aviso antes** (achado ao mapear tudo pra unificar): pedido e aceite de amizade, agora com push + Central.
- Endpoints: `GET /notifications` (paginado por cursor, mesmo padrão do Feed), `GET /notifications/unread-count` (badge leve), `POST /notifications/{id}/read`, `POST /notifications/mark-all-read`.
- Retenção: 30 dias (prazo sugerido pelo próprio documento, seção 3), filtrado na listagem E apagado de verdade por um cron diário (`app/scheduler.py::_run_notifications_purge_job`, 04:00 horário de Brasília, `services.purge_old_notifications`) — achado da auditoria de segurança pré-lançamento mundial (17/09/2026, A2): antes só filtrava na leitura, nunca apagava.
- FK de `mental.notifications.user_id` pra `auth.users(id) on delete cascade` — achado A1 da mesma auditoria: a migration 075 original não tinha essa FK, deixando notificação (com nome real de terceiros no corpo) órfã pra sempre após exclusão de conta. Corrigido em `migrations/077_fk_notifications.sql`.
- Client: sino no canto superior direito da Home (pedido de Rhoney, fixo independente da rolagem) com badge de não lidas; `NotificationsScreen` nova, com ícone/cor por tipo, distinção visual lido/não lido, "marcar todas como lidas", e toque navegando direto pra tela relacionada (Batalhas/Movimento/Amigos/Progresso/Perfil Público) via o mesmo payload `data.navigate` já usado no push.
- Testes: `tests/test_notifications_central.py` (6 testes backend, incluindo a prova de que a Central existe mesmo sem push) + `test/notifications_screen_test.dart` (4 testes client).

---

## 1. Entendimento da solicitação

Rhoney pediu um **botão na Home** que funcione como **central única de notificações** — reunindo em um só lugar:
- Interações de **outros usuários** direcionadas ao usuário atual (ex.: alguém desafiou para uma Batalha, alguém torceu, alguém enviou um convite de Movimento, alguém comentou/reagiu, um pedido de amizade).
- **Avisos e alertas do próprio app** (ex.: conquistas desbloqueadas, lembretes de streak, anúncios de novidades, avisos do sistema).

Ou seja: não é apenas uma notificação push isolada (que já existe hoje para casos como Batalha e Torcida, segundo o histórico do projeto) — é um **local persistente e centralizado dentro do app**, onde o usuário pode abrir e ver o histórico dessas notificações, mesmo que já tenha dispensado o push original ou estivesse com o app fechado quando ela chegou.

**Se essa leitura estiver correta**, o restante deste documento segue essa direção. Se a intenção for mais restrita (por exemplo, só um atalho visual sem histórico persistente), isso precisa ser sinalizado antes de qualquer implementação.

## 2. Escopo da funcionalidade

### 2.1 O botão na Home
- Ícone de sino (ou equivalente) visível na Home, com indicador visual de notificações não lidas (badge numérico ou ponto de destaque).
- Ao tocar, abre a Central de Notificações — uma tela/painel listando as notificações em ordem cronológica (mais recente primeiro).

### 2.2 Tipos de notificação a centralizar
Com base no que já existe hoje no MENTAL, a central deveria agregar, no mínimo:
- Desafios de Batalha recebidos e resultado de Batalhas concluídas.
- Interações de Torcida.
- Convites/atividades de Movimento (se aplicável).
- Pedidos e aceites de Amizade.
- Avisos do sistema (conquistas, marcos de streak, novidades do app).

Cada tipo deve ter identidade visual própria (ícone/cor) para facilitar o reconhecimento rápido dentro da lista.

### 2.3 Estado de leitura
- Notificações não lidas devem ser visualmente diferenciadas das já lidas.
- Tocar em uma notificação deve marcá-la como lida e, quando fizer sentido, levar o usuário diretamente à tela relacionada (ex.: notificação de Batalha leva à tela de Batalhas, seguindo o mesmo princípio de navegação direta já estabelecido para a notificação de Movimento).

## 3. Decisões já definidas por Rhoney (não reabrir)

- **Persistência**: as notificações **ficam guardadas por um período** (histórico), não somem imediatamente após lidas. Claude Code deve propor um prazo técnico razoável (ex.: 30 dias) e confirmar com Rhoney antes de implementar, mas o princípio de manter histórico está aprovado.
- **Limpeza**: **deve existir a opção "marcar todas como lidas"**.
- **Relação com o push**: a notificação push **continua existindo normalmente**, exatamente como hoje — a Central de Notificações funciona como histórico/espelho complementar, não como substituta.

## 4. Escopo técnico (a propor em detalhe por Claude Code)

- Modelar a entidade "Notificação" no banco de dados, se ainda não existir de forma centralizada, com tipo, remetente (quando aplicável), estado de leitura, timestamp e link de destino.
- Unificar as origens de notificação já existentes (Batalha, Torcida, Movimento, Amizade, sistema) para que todas alimentem essa mesma estrutura central, em vez de cada uma ter sua lógica isolada.
- Implementar o ícone/badge na Home e a tela da Central de Notificações no Flutter.
- Confirmar impacto de performance/custo ao consultar essa lista com frequência, dado que o projeto roda hoje no Render Free.

## 5. Critério de aceite

- Botão de notificações visível na Home, com indicador de não lidas.
- Central agrega corretamente todos os tipos de notificação listados na seção 2.2.
- Tocar numa notificação marca como lida e navega para a tela correta quando aplicável.
- Botão "marcar todas como lidas" funcional na Central.
- Notificações permanecem visíveis no histórico pelo período definido, mesmo após lidas.
- Notificações push continuam disparando normalmente, em paralelo à Central.
