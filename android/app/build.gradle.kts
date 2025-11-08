// ✅ CRITICAL: Required imports for signing configuration
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ✅ Load signing configuration
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val requiredKeystoreKeys = listOf("keyAlias", "keyPassword", "storeFile", "storePassword")
val hasReleaseSigningConfig = if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
    requiredKeystoreKeys.all { !keystoreProperties.getProperty(it).isNullOrBlank() }
} else {
    false
}

android {
    namespace = "com.example.flutter_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // ✅ Signing configurations
    signingConfigs {
        if (hasReleaseSigningConfig) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.flutter_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // ✅ Use release signing configuration when available, otherwise fall back to debug
            signingConfig = if (hasReleaseSigningConfig) {
                signingConfigs.getByName("release")
            } else {
                println("Warning: Using debug signing config because release keystore was not found or is incomplete.")
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
