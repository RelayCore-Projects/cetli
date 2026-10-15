import java.io.FileInputStream
import java.util.Properties

// Release signing: in CI the key comes from GitHub Secrets via environment variables,
// for a local build optionally from android/key.properties. Neither is committed.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) FileInputStream(f).use { load(it) }
}

fun signingValue(property: String, env: String): String? =
    (keystoreProperties.getProperty(property) ?: System.getenv(env))?.takeIf { it.isNotBlank() }

val releaseStoreFile = signingValue("storeFile", "CETLI_KEYSTORE_PATH")

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "hu.relaycore.cetli"
    compileSdk = flutter.compileSdkVersion
    // Pinned to the NDK pre-installed on the GitHub runner image. Flutter's default
    // NDK is no longer on the image and downloading it failed (same as in Pulzar).
    ndkVersion = "29.0.14206865"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Final identifier – NEVER change it, otherwise updates will not install over older versions
        applicationId = "hu.relaycore.cetli"
        minSdk = 26 // NFR-01: Android 8.0
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (releaseStoreFile != null) {
                storeFile = file(releaseStoreFile)
                storePassword = signingValue("storePassword", "CETLI_KEYSTORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "CETLI_KEY_ALIAS")
                // In a PKCS12 keystore the key password equals the store password
                keyPassword = signingValue("keyPassword", "CETLI_KEY_PASSWORD") ?: storePassword
            }
        }
    }

    buildTypes {
        release {
            // Without a release key (e.g. a local test build) the debug key is used
            signingConfig = if (releaseStoreFile != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
