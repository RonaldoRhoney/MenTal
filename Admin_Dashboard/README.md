# Admin Dashboard

Documentos do Painel Administrativo do MENTAL, nas suas duas versões
planejadas. Pasta criada em 11/09/2026 (reorganização por
funcionalidade — antes soltos em `U.I/`).

- `ADMIN_DASHBOARD_V1.md` — painel web externo, com maior poder e
  escopo (referência visual: `mental-admin-panel.html`, não versionado
  aqui). **Status:** fica para um outro momento — a versão que foi
  implementada e está em produção é a in-app (ver abaixo).
- `ADMIN_PAINEL_IN_APP_V1.md` — versão mais simples, dentro do próprio
  app Flutter, visível só para o admin (`rhoneyinc@gmail.com`),
  somente leitura. **Implementado e em produção**
  (`client/lib/screens/admin_metrics_screen.dart`,
  `backend/app/routers/admin_metrics.py`) — inclui visão geral,
  ranking de progresso, precisão por território, distribuição de
  feedback, métricas de Movimento, demografia, sugestões de conteúdo e
  moderação de fotos de perfil (adicionada em 07/09/2026).
