# V7

**Status:** Em andamento. Lote de trabalho pós-V5 (V5 encerrada em
04/09/2026, V6 reservada para o Mundo dos Valores e ainda não iniciada
— nada deste lote toca em V6). Cobre a auditoria de segurança pré-AAB,
a reformulação de Movimento em gráficos ricos por período, e ajustes
sociais (Feedback/Torcida/Movimento) pedidos por Rhoney em 05/09/2026.

- `APROVACAO_CORRECOES_PRE_AAB_V1.md` — auditoria de segurança/qualidade/
  testes/conteúdo/UI-UX pré-geração do AAB. **Concluído (05/09/2026)**:
  C1 (oráculo de respostas via `/challenges/{id}/reattempt`), A1
  (bloqueio incompleto em Perfil Público/Torcida), M5 (build de release
  Android endurecido: `allowBackup=false`, R8, `INTERNET` em `main/`,
  falha explícita sem keystore), M1 (rate limiting básico + cap de
  `MovementSnapshot`), M2 (piso de tempo em Caça-palavras/Pausa para
  Aprender), M3 (fuso UTC consistente em recompensas), M4 (`max_length`
  em texto livre + escape de busca), B1 (bug real de datetime naive/
  aware em `_checkpoint_bonus`), B2 (documentação da 3ª exceção LGPD),
  B3 (remoção do resíduo de "porta de pais"), B5 (checagem de admin
  centralizada em `services.require_admin`). B4 (funções/módulos
  grandes demais) fica registrado como pendência de limpeza pós-
  lançamento, não bloqueante. Suíte backend: 327/327.
- `MOVIMENTO_GRAFICOS_RICOS_V1.md` — reformulação da tela Movimento em
  4 abas (Dia/Semana/Mês/Ano), protótipo em `U.I/movimento_rico.html`.
  **Concluído e em produção (05/09/2026)**: tela unificada
  `movement_reports_screen.dart` substituindo as 3 telas antigas de
  detalhe, histórico próprio por período (`GET /movement/history?period=`),
  card "Mês" adicionado à tela principal (faltava na leva original),
  passada de legibilidade em textos pequenos, correções pontuais (card
  "Noite" mostra "23:59" em vez de "24h", palavras cortadas nos cards de
  sessão, label da aba "Dia"→"Hoje" pra bater com o card "Hoje" da tela
  principal). Teste de widget dedicado adicionado em 05/09/2026
  (`movement_reports_screen_test.dart`, 6 testes — cada aba com seu
  próprio histórico, paginação por período, `initialPeriod`).
- `FEEDBACK_NOME_REAL_E_TORCIDA_LAYOUT_V1.md` — **Concluído (05/09/2026)**:
  mural de Feedback exibe nome real do autor (mascarado por bloqueio
  mútuo), corte de layout dos 4 ícones de Torcida no Perfil Público
  corrigido. Nesta mesma área do Perfil Público, pedido adicional de
  Rhoney (não previsto no documento original): botão "GO" convidando o
  visitado a ligar o Movimento, com notificação push de deep link —
  **implementado** (`MovementInvite`, migration 062,
  `POST /profile/{id}/invite-movement`). Tela de Perfil Público também
  compactada pra caber sem rolagem (pedido de Rhoney, 05/09/2026).
- `SCREENSHOTS_LOJA_E_AVISO_ATUALIZACAO_V1.md` — Screenshots atualizados
  da ficha da Google Play continuam sendo tarefa manual de Rhoney (fora
  do alcance do Claude Code, ver §1.3 do próprio documento) — não é
  código, não bloqueia esta pasta. Aviso gentil de nova versão
  disponível (§2): **concluído (05/09/2026)** — `GET /app/version`
  (público, sem auth) expõe `latest_version`/`min_required_version`
  configuráveis por env var; client compara com a própria versão
  instalada (`kInstalledAppVersion`) na abertura da Home, mostra diálogo
  animado (fade+escala, paleta dourado/teal) com "Atualizar" (abre a
  ficha na Play Store) e "Mais tarde" (ausente se a atualização for
  obrigatória). API do Google Play In-App Update **não adotada** nesta
  entrega (§2.3 já previa essa alternativa como válida) — abrir a ficha
  da loja é suficiente pro cenário atual sem depender de infraestrutura
  adicional.
- `BUG_ADMIN_DASHBOARD_TESTADORES_NAO_APARECEM.md` — **Encerrado
  (05/09/2026)** sem bug de dado confirmado: números do Painel Admin
  in-app comparados diretamente contra o Postgres de produção batem
  exatamente.

## Pendências desta pasta

1. B4 da auditoria de segurança (funções/módulos grandes demais,
   ex. `submit_answer` com 250 linhas, `services.py` com ~1400) —
   classificado como limpeza pós-lançamento, não bloqueante.
2. Novo deploy do backend no Render — necessário pra `/app/version` e
   `/profile/{id}/invite-movement` funcionarem em produção.
