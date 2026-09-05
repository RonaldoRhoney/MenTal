# Achado de auditoria de segurança M5 (05/09/2026): isMinifyEnabled/
# isShrinkResources ativados no buildTypes.release (app/build.gradle.kts)
# reduzem o tamanho do AAB e dificultam engenharia reversa da API —
# regras abaixo cobrem os plugins que usam nome de classe/reflexão via
# platform channel (não capturado automaticamente pelo shrink de código
# Java/Kotlin, mesmo com Dart AOT sendo o grosso do binário).

# Flutter embedding (mantém as classes referenciadas por nome no
# AndroidManifest.xml e usadas via platform channel).
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Firebase Messaging (push) — serviço referenciado por nome no manifest
# via merge automático da lib.
-keep class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.**

# flutter_foreground_task — o serviço de foreground do Movimento
# (com.pravera.flutter_foreground_task.service.ForegroundService) é
# referenciado por nome literal no AndroidManifest.xml; o handler da
# tarefa (movement_task_handler.dart) é resolvido via platform channel.
-keep class com.pravera.flutter_foreground_task.** { *; }

# Supabase Auth (login_screen.dart) usa um deep link customizado
# resolvido via Intent — nenhuma classe própria a manter, mas mantém
# avisos de dependências transitivas silenciosos.
-dontwarn io.github.jan.supabase.**
