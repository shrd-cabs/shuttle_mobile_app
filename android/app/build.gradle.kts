import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

// ===============================================================
// RELEASE SIGNING CONFIGURATION
// ---------------------------------------------------------------
// Loads the private signing values from:
// android/key.properties
//
// Never commit key.properties or the upload keystore to Git.
// ===============================================================
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (!keystorePropertiesFile.exists()) {
    throw GradleException(
        "Missing android/key.properties. " +
            "Create it before building a signed release.",
    )
}

keystoreProperties.load(
    FileInputStream(keystorePropertiesFile),
)

android {
    namespace = "com.shrdcabs.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.shrdcabs.app"

        minSdk = flutter.minSdkVersion
        targetSdk = 35

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ===========================================================
    // PLAY STORE UPLOAD KEY
    // ===========================================================
    signingConfigs {
        create("release") {
            keyAlias =
                keystoreProperties.getProperty("keyAlias")

            keyPassword =
                keystoreProperties.getProperty("keyPassword")

            storePassword =
                keystoreProperties.getProperty("storePassword")

            storeFile =
                file(
                    keystoreProperties.getProperty("storeFile"),
                )
        }
    }

    buildTypes {
        release {
            // Keep code shrinking disabled for the first release
            // to minimise release-only plugin compatibility issues.
            isMinifyEnabled = false
            isShrinkResources = false

            // Sign using the permanent Play Store upload key.
            signingConfig =
                signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget =
            org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}