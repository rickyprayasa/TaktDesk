import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload key for Google Play, read from android/key.properties (git-ignored).
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasUploadKey = keystoreProperties.getProperty("storeFile") != null

// `flutter build --dart-define=K=V` reaches Gradle as -Pdart-defines (each
// define base64, comma separated).
val dartDefines: Set<String> = (project.findProperty("dart-defines") as String?)
    ?.split(",")?.filter { it.isNotBlank() }
    ?.map { String(Base64.getDecoder().decode(it)) }?.toSet() ?: emptySet()

// A PRO-simulation build (developer-pro APK) unlocks Studio PRO without paying,
// so it must never look like the store app: its own application ID (installs
// next to the Play version), its own name, and the debug key instead of the
// upload key.
val isProSimulationBuild = "ENABLE_PRO_SIMULATION=true" in dartDefines

android {
    namespace = "com.zykl.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.zykl.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion.coerceAtLeast(24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLabel"] = "@string/app_name"
        if (isProSimulationBuild) {
            applicationIdSuffix = ".devpro"
            manifestPlaceholders["appLabel"] = "ZYKL DEV PRO"
        }
    }

    signingConfigs {
        if (hasUploadKey) {
            create("upload") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (hasUploadKey && !isProSimulationBuild) "upload" else "debug",
            )
        }
    }
}

// Fail closed: a store release without the upload key would silently be
// debug-signed. Set ZYKL_ALLOW_DEBUG_RELEASE=1 for a throwaway local release.
gradle.taskGraph.whenReady {
    val storeRelease = allTasks.any { it.project == project && it.name in setOf("assembleRelease", "bundleRelease") }
    if (storeRelease && !hasUploadKey && !isProSimulationBuild && System.getenv("ZYKL_ALLOW_DEBUG_RELEASE") != "1") {
        throw GradleException(
            "ZYKL: android/key.properties is missing, so this release would be signed with the debug key. " +
                "Restore key.properties, or set ZYKL_ALLOW_DEBUG_RELEASE=1 for a local-only build.",
        )
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

dependencies {
    implementation("androidx.media:media:1.7.0")
}

