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
- `NOME_REAL_E_FOTO_EM_TODO_LUGAR_V1.md` — estende a preferência por
  nome real (em vez de apelido) a todo o app: notificações push
  (Batalha, Torcida, Movimento, território), Painel Admin (moderação de
  foto) e política de privacidade. **Implementado** (11/09/2026, ver
  seção 7 do próprio documento).
- `BUG_DESAFIO_NAO_AVANCA.md` — desafio parecia travar após responder
  (erro de API silenciosamente engolido). **ENCERRADO** (causa raiz
  corrigida em 28/08/2026, revalidado ao vivo em 07/09/2026). Movido
  pra esta pasta em 11/09/2026 (reorganização por funcionalidade, antes
  em `U.I/`).

**Reorganização de 11/09/2026:** `REORGANIZACAO_MENUS_HOME_V1.md` saiu
daqui e foi pra `Home/` (junto dos demais documentos de redesign da
Home, antes espalhados entre esta pasta e `U.I/`).
