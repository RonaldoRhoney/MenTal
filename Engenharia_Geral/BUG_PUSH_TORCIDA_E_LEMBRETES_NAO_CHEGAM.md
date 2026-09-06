# MENTAL — Bug: Push de Torcida não chega ao destinatário + Verificação de lembretes 24/48h

**Status:** Causa raiz confirmada e corrigida (06/09/2026) — ver seção
final. Falta só o teste de ponta a ponta em produção com um token
recém-registrado, e confirmar separadamente a entrega dos lembretes
24h/48h (nunca teve relação com este bug, mas a pergunta original segue
em aberto).
**Tipo:** Investigação de bug — causa raiz desconhecida, não presumir antes de investigar.
**Contexto de teste:** Rhoney usa duas contas (uma administrativa, outra espelho/testadora) e confirmou, testando manualmente, que reações de Torcida enviadas entre as duas contas não chegam como notificação ao destinatário.

---

## 1. Descrição do problema principal: push de Torcida não chega

Já foi formalizado em COMPARTILHAR_CONVIDAR_E_PUSH_TORCIDA.md que toda interação de Torcida (vibração, balão, coraçãozinho, joinha) deve disparar uma notificação push real ao destinatário, mesmo com o app fechado ou o celular bloqueado — reaproveitando a infraestrutura de FCM já usada para lembretes de streak e missão diária.

Teste manual de Rhoney (conta administrativa enviando Torcida para conta espelho de teste) confirma que essa notificação **não está chegando** ao destinatário. Isso quebra o propósito central da funcionalidade: a Torcida existe para gerar sinergia e sensação de comunidade entre jogadores — sem a notificação chegando, o recurso perde grande parte do seu valor, já que o destinatário só perceberia o incentivo se abrisse o app por conta própria e notasse por acaso.

## 2. Investigação necessária, sem presumir a causa

1. **Confirmar se o evento de envio de Torcida está, de fato, disparando uma tentativa de push no backend.** Verificar se a função responsável por registrar a Torcida (services.py, conforme mencionado em auditorias anteriores) está de fato chamando a rotina de envio de notificação, ou se esse disparo nunca chega a ser executado.
2. **Se o disparo está ocorrendo, verificar se a chamada ao FCM (Firebase Cloud Messaging) está sendo bem-sucedida** — checar logs de erro/resposta da API do FCM no momento do envio, não apenas assumir que "foi enviado" pelo lado do MENTAL.
3. **Verificar se o token de notificação (device token) da conta de destino está registrado corretamente no backend** — um token ausente, expirado ou desatualizado é uma causa comum desse tipo de falha silenciosa.
4. **Testar em ambas as direções** (conta ADM → conta espelho, e também conta espelho → conta ADM) para confirmar se o problema é bidirecional ou específico de uma das contas/dispositivos.
5. **Verificar se existe alguma configuração de permissão de notificação no dispositivo de teste** que possa estar bloqueando a entrega, isolando se é problema de backend, de infraestrutura de push, ou de configuração local do aparelho de teste.

## 3. Segunda pergunta: os lembretes de 24h/48h estão realmente sendo entregues?

Rhoney questiona se as notificações programadas de lembrete (ausência de 24h/48h sem uso do app, ou equivalente) estão de fato chegando aos usuários, não apenas sendo geradas no backend.

### 3.1 Investigação necessária
- Confirmar, com evidência de log real (não suposição), que os jobs/rotinas responsáveis por esses lembretes estão executando na frequência esperada.
- Confirmar que, quando executam, a chamada ao FCM para esses lembretes específicos está retornando sucesso, não apenas sendo disparada.
- Se possível, cruzar com uma conta de teste real que fique deliberadamente inativa por 24h e depois por 48h, confirmando se a notificação chega de fato no dispositivo, dentro da janela de tempo esperada.
- Reportar se esse problema (caso exista) compartilha a mesma causa raiz do bug de Torcida (ex.: problema geral na integração com FCM) ou se são causas distintas.

## 4. O que NÃO fazer nesta rodada

- Não aplicar correção alguma antes de reportar a causa raiz confirmada de cada um dos dois problemas.
- Não presumir que ambos os problemas têm a mesma causa sem confirmar isso — podem ser bugs independentes que só parecem relacionados por envolverem notificação.

## 5. Critério de aceite

- Causa raiz do bug de Torcida identificada e reportada antes de qualquer correção.
- Após a correção, teste manual (conta ADM ↔ conta espelho) confirma que a notificação chega corretamente nos dois sentidos.
- Confirmação com evidência real (não suposição) de que os lembretes de 24h/48h estão sendo entregues corretamente, ou identificação do problema caso não estejam.
- Se ambos os problemas compartilharem causa raiz (ex.: falha geral de configuração do FCM), isso deve ser reportado explicitamente, já que uma única correção poderia resolver os dois de uma vez.

## Causa raiz confirmada e correção aplicada (06/09/2026)

Evidência real: logs do Render (Rhoney compartilhou), erro
`firebase_admin._messaging_utils.UnregisteredError: NotRegistered` ao
tentar enviar a Torcida — confirma que `FIREBASE_SERVICE_ACCOUNT_JSON`
está configurado corretamente e o Firebase Admin SDK inicializa sem
problema algum (chegou a fazer a chamada real pro FCM). O problema é
específico: o `push_token` salvo pra aquele destinatário não existe
mais do lado do Google (token expira/é invalidado quando o app é
desinstalado, dados são limpos, ou o token é rotacionado sem que o
client tenha reenviado o novo via `POST /notifications/register-token`
naquele momento).

**Duas causas descartadas por evidência real, não suposição:**
`FIREBASE_SERVICE_ACCOUNT_JSON` existe no Render (confirmado no
painel); `NOTIFICATION_SCHEDULER_ENABLED` existe e está `true`
(confirmado no painel) — os lembretes 24h/48h não têm relação com este
bug específico.

**Correção**: `push.send_push_notification()` agora recebe
`db`/`profile` (não mais só a string do token) e, ao detectar
especificamente `UnregisteredError`, limpa `profile.push_token` e
commita — nunca mais insiste pra sempre no mesmo token morto. Qualquer
outra falha (rede instável, erro transitório do FCM) continua
preservando o token pra nova tentativa, distinção deliberada (só
`UnregisteredError` é uma confirmação DEFINITIVA do Google de que
aquele token nunca mais vai funcionar). Os ~9 pontos de chamada em
`services.py`/`notifications.py` foram atualizados pra passar o
profile inteiro.

Testes: `tests/test_push.py` (3 testes — token limpo e commitado só em
`UnregisteredError`, token preservado em falha genérica, nenhuma
chamada ao Firebase quando não há token). Suíte backend completa:
360/360.

**Pendente**: teste manual de ponta a ponta em produção (conta ADM →
conta espelho, com a conta espelho tendo reaberto o app pra registrar
um token novo e válido depois da limpeza do antigo) — confirmar que a
notificação chega de fato ao dispositivo agora que o token está
atualizado.
