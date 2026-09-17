# Engenharia Geral

Documentos de features/bugs transversais — não específicos de um único
Mundo (que ficam em `Mundo_*/`) nem de uma fase de versão fechada
(`V1`-`V4`). Pasta criada em 06/09/2026 (pedido de Rhoney) pra dar
destino a esse tipo de documento em vez de deixá-lo solto na raiz do
repositório.

- `FEED_SOCIAL_V1.md` — Feed de conquistas + Seguir/Fã (piloto).
  **Implementado** (06/09/2026, backend e client, em produção).
- `BUG_PUSH_TORCIDA_E_LEMBRETES_NAO_CHEGAM.md` — investigação do bug de
  push de Torcida não chegando ao destinatário. **Corrigido**
  (06/09/2026): causa raiz confirmada por evidência real de log em
  produção (token FCM expirado/inválido, `UnregisteredError:
  NotRegistered`); `push.send_push_notification()` agora limpa
  `profile.push_token` só nesse erro específico, preservando o token em
  qualquer outra falha transitória — coberto por 3 testes
  (`tests/test_push.py`), suíte completa passando. Falta só o teste
  manual E2E em produção (Rhoney testar ADM↔conta espelho com token
  recém-registrado), que não é tarefa de código.
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
- `ADENDO_NOTIFICACAO_RANKING_NOME_REAL.md` — eleva a correção de nome
  real (documento acima) de lista pontual pra **regra geral permanente**,
  após uma 6ª ocorrência real em produção (notificação "O ranking
  mudou" mostrando apelido genérico). **Implementado** (12/09/2026) —
  varredura ampla achou e corrigiu mais 4 pontos, regra documentada como
  checklist permanente no agente `mental-security`.

- `ARQUITETURA_SUBMUNDOS_V1.md` — mecanismo de SubMundo reaproveitando
  Bloco (BLOCOS_MENUS.md) em vez de entidade nova. **Implementado**
  (13-14/09/2026): base do SubMundo Internet (Tecnologia) e Copa do
  Mundo/Futebol (Esportes).
- `BATALHAS_INTUITIVAS_E_TEMPO_REAL_V1.md` — Fase 1 (assíncrona) mais
  intuitiva: notificação "sua vez de jogar", badge de pendentes na
  Home, resultado com ícone. **Implementado** (14/09/2026). Fase 2
  (tempo real) segue não iniciada, escopo separado no próprio
  documento.
- `CORRECAO_REPETICAO_PERGUNTAS_V1.md` — bug de repetição de perguntas
  dentro do mesmo Desafio/Relâmpago. **Corrigido** (14/09/2026): causa
  raiz era a dificuldade adaptativa recomendar um nível sem conteúdo
  curado em territórios "flat" — travado na origem em
  `pick_difficulty_for`.
- `NOTIFICACAO_MOVIMENTO_PREVIA_V1.md` — notificação persistente de
  Movimento com prévia de Passos/MentalCoins/XP do dia. **Implementado**
  (14/09/2026).
- `RECUPERACAO_DE_SENHA_E_LOGIN_V1.md` — fluxo "Esqueci minha senha" via
  Supabase Auth nativo. **Implementado** (14/09/2026), 100% client-side.
- `CENTRAL_DE_NOTIFICACOES_HOME_V1.md` — histórico persistente de
  notificações, sino na Home. **Implementado** (14/09/2026), com
  correções de auditoria de segurança pré-lançamento mundial em
  17/09/2026 (FK de exclusão de conta + limpeza por retenção).

**Reorganização de 11/09/2026:** `REORGANIZACAO_MENUS_HOME_V1.md` saiu
daqui e foi pra `Home/` (junto dos demais documentos de redesign da
Home, antes espalhados entre esta pasta e `U.I/`).

**Reorganização de 17/09/2026:** os 6 documentos acima (ARQUITETURA_
SUBMUNDOS a CENTRAL_DE_NOTIFICACOES) vieram da raiz do repositório pra
cá, depois de implementados e testados.
