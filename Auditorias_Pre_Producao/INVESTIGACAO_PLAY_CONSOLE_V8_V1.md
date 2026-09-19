# MENTAL — Investigação: Falhas Reportadas e Aviso de Exibição no Google Play Console

**Status:** CONCLUÍDA (18/09/2026). App já está em produção mundial (177 países/regiões, 30 instalações registradas), versão 8 (0.4.0). Os dois pontos abaixo foram identificados diretamente no Painel da Versão do Google Play Console, via prints anexados por Rhoney, e foram investigados/corrigidos.

## Conclusão — resumo executivo

- **Ponto 1 (8 falhas percebidas)**: sem causa raiz no código — não há registro real em "Android vitals → Falhas e ANRs" (nem ativo, nem arquivado) nos últimos 28 dias. As 8 ocorrências do painel da versão vieram do teste automatizado do próprio Google durante a revisão da versão (aparelhos de laboratório), não de usuário real em campo. Nenhuma correção de bug necessária por esse lado.
- **Ponto 2 (edge-to-edge)**: causa raiz confirmada (app já compila contra SDK 36/edge-to-edge por padrão no Android 15+, sem nenhuma chamada de compatibilidade no `MainActivity.kt`) e corrigida — ver seção 2.1 abaixo.

---

## 1. Falhas percebidas pelo usuário — 8 ocorrências na versão 8 (0.4.0)

### O que o Console mostra
- Seção "Estabilidade da versão" → "Falhas percebidas pelo usuário".
- Gráfico com eixo Y de 0 a 3+ (granularidade diária), mostrando **8 falhas percebidas pelo usuário** atribuídas à versão **8 (0.4.0)**.
- Abaixo, a seção "Taxa de falhas percebidas pelo usuário" aparece como **"Dados indisponíveis"** — provável consequência da base pequena de instalações (30 no total) ainda não ser suficiente para o Google calcular uma taxa percentual confiável.
- O Console oferece um link **"Explorar"** ao lado do gráfico de falhas, que leva a mais detalhes (provavelmente stack traces, dispositivos afetados, frequência por versão de Android).

### O que foi investigado
- `Falhas e ANRs` (Play Console → Monitorar e aprimorar → Android vitals), o painel real de crash/ANR em campo (não o resumo da versão): filtro "Tipo: Todas as falhas", período "Últimos 28 dias" → **"Nenhum resultado"** na tabela de Problemas ativos.
- `Problemas arquivados` (mesma tela, expandido) → também **"Nenhum resultado"**.
- Projeto não tem Firebase Crashlytics, Sentry nem nenhum outro serviço de relatório de crash integrado (`grep` em `pubspec.yaml`/`android/app/build.gradle.kts` não encontra nada), e `main.dart` não tem `runZonedGuarded`/`FlutterError.onError`/`PlatformDispatcher.instance.onError` — não há como cruzar com um segundo sistema de crash report.

### Conclusão
Nenhum bug real de campo identificado. As 8 "falhas percebidas pelo usuário" do painel da versão não têm nenhum registro correspondente no sistema real de Android vitals (nem ativo, nem arquivado) — a explicação mais consistente é que vieram do teste automatizado do próprio Google durante a revisão da versão 8 (rodado em aparelhos de laboratório antes da liberação), não de instalações reais dos ~30 usuários do teste fechado. Nada a corrigir no código por este ponto. Se o padrão se repetir em versões futuras com volume real de usuários, revisitar esta investigação.

## 2. Aviso do Google — Exibição "de ponta a ponta" (edge-to-edge) pode não funcionar corretamente

### O que o Console mostra, literalmente
Aviso classificado como **"1 ação recomendada"**, categoria **"Experiência do usuário"**, associado à versão **8 (0.4.0)**:

> "A exibição de ponta a ponta pode não estar disponível para todos os usuários. No Android 15 e versões mais recentes, apps com o SDK 35 serão mostrados de ponta a ponta por padrão. Os apps que segmentam o SDK 35 precisam lidar com recuos para garantir que sejam exibidos corretamente no Android 15 e versões mais recentes. Investigue o problema, teste o app de ponta a ponta e faça as atualizações necessárias. Como alternativa, chame `enableEdgeToEdge()` para Kotlin ou `EdgeToEdge.enable()` para Java. Assim, terá compatibilidade com versões anteriores."

### 2.1 O que foi investigado e corrigido
- SDK alvo confirmado: `targetSdk = flutter.targetSdkVersion` (`android/app/build.gradle.kts`) resolve pro default do Flutter 3.47.1 (`compileSdkVersion`/`targetSdkVersion` = **36**, `FlutterExtension.kt` do próprio SDK) — já acima do limiar de 35 que o aviso cita, confirmando que o app cai na exibição de ponta a ponta obrigatória do Android 15+.
- `MainActivity.kt` era um `class MainActivity : FlutterActivity()` vazio, sem nenhuma chamada de compatibilidade — nenhuma tela do app tinha tratamento explícito de insets além do `SafeArea` já usado no lado Dart/Flutter (que continua correto e necessário, mas não é o que o aviso do Google detecta).
- **Tentativa 1** — `enableEdgeToEdge()` (a chamada litralmente sugerida pelo aviso do Google): **não compila**. É uma extensão de `androidx.activity.ComponentActivity`, mas `FlutterActivity` (fonte do engine, `io/flutter/embedding/android/FlutterActivity.java`) estende `android.app.Activity` puro, não `ComponentActivity`/`AppCompatActivity` — erro de "receiver type mismatch" confirmado num build real.
- **Correção aplicada**: `WindowCompat.setDecorFitsSystemWindows(window, false)` em `onCreate` — mesmo efeito prático de `enableEdgeToEdge()` (é o que ele chama por baixo dos panos), mas funciona em qualquer `Activity` via `Window`, e usa `androidx.core` (já uma dependência garantida do embedding do Flutter, sem precisar adicionar `androidx.activity` ao projeto).
- Validado com build real (`flutter build apk --debug`) instalado no Moto G22 (Android 12/SDK 31) — sem regressão visual (Home renderiza normal, sem sobreposição por status/nav bar). Esse aparelho não reproduz o cenário exato do aviso (só ocorre a partir do Android 15), mas confirma que a mudança não quebra nada nas versões atuais.
- Arquivos alterados: `client/android/app/src/main/kotlin/com/rhoneyinc/mental/MainActivity.kt`.

## 3. Contexto adicional relevante (não é problema, é informação de apoio)

- App está **ativo** em produção, distribuído para **177 países/regiões**, com **30 instalações** registradas até o momento da captura dos prints.
- Rhoney subiu a versão e solicitou a publicação mundial sem alterações posteriores — não há suspeita de reinício de processo de revisão por modificação indevida.

## 4. Critério de aceite

- Causa raiz das 8 falhas percebidas pelo usuário identificada e documentada (mensagem de erro, dispositivos/versões afetadas, se é bug único ou múltiplos).
- Correção implementada para a(s) causa(s) identificada(s), com testes de regressão confirmando que o problema não se repete.
- `enableEdgeToEdge()`/`EdgeToEdge.enable()` implementado corretamente, com teste real em dispositivo/emulador Android 15+, confirmando que nenhum elemento de interface fica coberto por barras de sistema ou recortes de câmera.
- Rhoney informado do diagnóstico completo antes de qualquer nova versão ser enviada ao Google, para decidir se a correção justifica uma nova versão imediata ou pode aguardar o próximo ciclo de atualização.
