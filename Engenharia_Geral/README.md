# Engenharia Geral

Documentos de features/bugs transversais — não específicos de um único
Mundo (que ficam em `Mundo_*/`) nem de uma fase de versão fechada
(`V1`-`V4`). Pasta criada em 06/09/2026 (pedido de Rhoney) pra dar
destino a esse tipo de documento em vez de deixá-lo solto na raiz do
repositório.

- `FEED_SOCIAL_V1.md` — Feed de conquistas + Seguir/Fã (piloto).
  **Implementado** (06/09/2026, backend e client, em produção).
- `BUG_PUSH_TORCIDA_E_LEMBRETES_NAO_CHEGAM.md` — investigação do bug de
  push de Torcida não chegando ao destinatário. **Em aberto**: causa
  raiz confirmada por evidência real de log em produção (token FCM
  expirado/inválido, `UnregisteredError: NotRegistered`) — falta
  decidir e aplicar a correção (ex.: limpar `push_token` inválido ao
  detectar esse erro) e confirmar separadamente a entrega dos lembretes
  24h/48h.
- `REORGANIZACAO_MENUS_HOME_V1.md` — reorganização de menus e redução
  de toques na Home (grid de atalhos, barra inferior, espaço próprio
  pro Feed). **Implementado** (06/09/2026, em produção). Movido pra
  esta pasta em 11/09/2026 (antes solto na raiz do repo).
