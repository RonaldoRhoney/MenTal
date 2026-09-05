import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // V2 item 8 — Notificações (NOTIFICATIONS.md, FCM confirmado ZERO_COST
    // via skill zero-cost-api antes de integrar). Lê android/app/google-
    // services.json (não commitado — ver .gitignore).
    id("com.google.gms.google-services")
}

// Keystore de release real (android/key.properties, NUNCA commitado — ver
// .gitignore). Sem esse arquivo (ex.: checkout novo sem a keystore), o
// build de release cai pra assinatura de debug — nunca falha o build,
// só não produz um artefato publicável.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.rhoneyinc.mental"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.rhoneyinc.mental"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Achado de auditoria de segurança M5 (05/09/2026): cair
            // silenciosamente pra assinatura de debug quando key.properties
            // não existe significava que "gerar o AAB" num checkout sem a
            // keystore de produção produzia um artefato assinado com a
            // chave errada, sem erro nenhum — só seria percebido tarde
            // demais, na submissão à loja. Falha explícita é melhor que um
            // AAB inutilizável silencioso.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else if (project.hasProperty("allowInsecureDebugSigning")) {
                signingConfigs.getByName("debug")
            } else {
                throw GradleException(
                    "android/key.properties não encontrado — build de release sem a keystore de produção seria assinado com a chave de debug " +
                        "e rejeitado/inutilizável na Play Store. Para builds de desenvolvimento local (nunca pra submissão), rode com " +
                        "-PallowInsecureDebugSigning."
                )
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
