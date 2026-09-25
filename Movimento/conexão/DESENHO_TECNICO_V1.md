# Health Connect no Movimento — desenho técnico V1 (aprovado o caminho por Rhoney, 25/09/2026)

Base: os 8 arquivos desta pasta (proposta original) + revisão contra o `MovementService` real. Este documento **substitui** o orquestrador paralelo da pasta: nada dela é copiado como está.

## 1. Princípios aprovados

- Reaproveitar o `MovementService` (ciclo, linha de base, coleta, servidor). **Sem orquestrador paralelo.**
- Health Connect entra como **fonte adicional de leitura**. **Sem escrita** nesta fase.
- Só registros **automáticos** (nunca entrada manual) e **sem contar o próprio MENTAL**.
- O servidor continua a única autoridade sobre XP/MentalCoins.

## 2. Decisões que ficaram em aberto e o padrão adotado

| # | Decisão | Padrão adotado (mais seguro) |
|---|---------|------------------------------|
| 2 | Passos de relógio valem XP/MentalCoins? | **Não.** Só aparecem na tela do Movimento. Contar para XP exigiria validação de fraude no servidor (origem, plausibilidade) e é uma fase seguinte, com decisão explícita. |
| 3 | Regra "1500 passos" da notificação | **Não implementar.** A notificação persistente atual já mostra passos, MentalCoins e XP **creditados pelo servidor** (`updateNotificationPreview`), nunca um número local não confirmado. Um gatilho de 1500 passos criaria um segundo número divergente. |

## 3. Leitura correta (corrige os defeitos da proposta original)

- Total do dia = **leitura agregada do Health Connect** (`getTotalStepsInInterval`, do início do dia de Brasília até agora, `includeManualEntry: false`). O Health Connect já **deduplica fontes** (relógio + Fit + Samsung). A proposta original usava só o registro mais recente como total, o que subestima o dia.
- Sem escrita: elimina o risco de o MENTAL inflar os passos de outros apps (a proposta original gravava o total do dia a cada evento do sensor, gerando registros sobrepostos) e o ciclo de leitura de volta do próprio dado.
- Dia = **dia de Brasília** (UTC-3 fixo), igual ao resto do app (`brasilia_time.dart`), não o dia do aparelho.
- O sensor continua com a linha de base do ciclo e o ajuste de reboot (`_totalSoFar`). Não se usa `event.steps` como "passos do dia".

## 4. Exibição

Na tela Movimento, um cartão discreto: "Health Connect: N passos hoje (relógio e outros apps)". Estados: indisponível (Health Connect ausente/versão antiga), sem permissão (botão "Conectar"), conectado (mostra o total), erro (mensagem honesta). Nenhum valor daqui é enviado ao servidor nesta fase.

## 5. Plataforma, política e privacidade (bloqueadores de liberação)

- Manifest: `READ_STEPS`; `PermissionsRationaleActivity`/`ViewPermissionUsageActivity` (Android 14+); `MainActivity` como `FlutterFragmentActivity` (exigência do pacote `health` para pedir permissão). Leitura em segundo plano exigiria `READ_HEALTH_DATA_IN_BACKGROUND`: **fora do escopo** (só leitura com o app aberto).
- **Google Play Console:** declaração de permissões do Health Connect (formulário) e atualização do formulário de segurança de dados **antes de enviar o AAB com essa permissão**. Sem isso a versão pode ser rejeitada.
- **Política de privacidade (LGPD):** passos são dado de saúde (sensível). Incluir finalidade, que o dado não sai do aparelho nesta fase, consentimento explícito e como revogar. Consentimento pedido só ao tocar em "Conectar".
- Dependência `flutter_foreground_task` **permanece em ^11**; a proposta original sugeria ^8 (retrocesso), e `workmanager` não é necessário.

## 6. Testes

Interface `HealthStepsSource` injetável (fake nos testes): total, indisponível, sem permissão, erro; cartão da tela por estado; garantia de que **nenhum** valor do Health Connect chega ao `collectSteps`. Teste real no aparelho: permissão e leitura no Android com Health Connect.

## 7. Ordem

1. Decisão de liberação (item 5): quando declarar no Play Console.
2. Código + testes + manifest.
3. Teste no aparelho de Rhoney.
4. Atualização da política de privacidade e do formulário do Play.
5. Só então incluir no AAB dos testadores.
