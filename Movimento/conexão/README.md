# Módulo de Passos — MENTAL

Implementação do contador de passos em tempo real com notificação
persistente e integração Health Connect (Google Fit e outros apps).

## Decisões de produto confirmadas
- Notificação atualiza a cada **1500 passos** acumulados (fixo, não configurável)
- Health Connect em modo **leitura e escrita** (MENTAL também é fonte de dados)
- Reconciliação: **wearable sempre tem prioridade** sobre o sensor do celular
  quando há leitura recente (< 2h) de um wearable no dia

## Arquivos criados
```
lib/
  models/
    step_reading.dart              # Modelo de leitura com origem (celular/wearable)
  services/
    step_reconciliation_service.dart  # Decide qual fonte "vale" no momento
    step_notification_service.dart    # Gatilho dos 1500 passos
    health_connect_service.dart       # Leitura/escrita no Health Connect
    step_tracking_orchestrator.dart   # Liga tudo (ponto de entrada do módulo)
pubspec_dependencies.yaml          # Pacotes a adicionar no pubspec.yaml
android_config/
  AndroidManifest_additions.xml    # Permissões e serviço a adicionar
```

## Como plugar no projeto existente
1. Copiar `lib/models` e `lib/services` para dentro do projeto Flutter do MENTAL
2. Adicionar as dependências de `pubspec_dependencies.yaml` ao `pubspec.yaml` e rodar `flutter pub get`
3. Mesclar `AndroidManifest_additions.xml` no `AndroidManifest.xml` real do projeto
4. Instanciar `StepTrackingOrchestrator` uma vez (ex: num singleton/provider) e chamar `.start()` na inicialização do app
5. Consumir `orchestrator.reconciledSteps` na tela de Movimento pra manter a UI e a notificação sincronizadas com a mesma fonte de verdade

## Pendências técnicas (não bloqueiam o código, mas precisam de decisão/implementação antes de ir pra produção)
- **Plugin real de notificação ongoing**: `step_notification_service.dart` está com stub comentado para `flutter_foreground_task`; falta ligar de fato ao iniciar o foreground service
- **Listener passivo nativo do Health Connect**: o orquestrador usa um timer de 15 min como sync de segurança; o listener passivo (mais eficiente em bateria) exige código nativo Kotlin, não coberto pelo pacote `health` — avaliar se vale o esforço extra ou se o timer de 15 min já atende
- **PermissionsRationaleActivity**: obrigatória a partir do Android 14 para apps que leem dados de saúde — só o esqueleto do intent-filter foi deixado comentado no manifest
- **Reset diário**: `resetForNewDay()` existe nos serviços mas precisa ser agendado (ex: `WorkManager` à meia-noite ou verificação de virada de dia na primeira leitura do dia)
- **Tela de configuração**: nenhuma UI foi criada ainda (nem para permissões, nem para status de conexão com Health Connect)
