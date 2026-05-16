import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val admobAppIdProp = (project.findProperty("ADMOB_APP_ID") as String?)?.trim().orEmpty()
val admobAppId = if (admobAppIdProp.isNotEmpty()) {
    admobAppIdProp
} else {
    // OfficeTools Pro production AdMob app id (override with -PADMOB_APP_ID=... if needed).
    "ca-app-pub-9040268910945565~1320297049"
}

android {
    namespace = "com.example.office_toolspro"
    // ML Kit selfie segmentation (via Flutter plugin) expects compileSdk >= 35.
    compileSdk = maxOf(flutter.compileSdkVersion, 35)
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.officetoolspro.app"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["ADMOB_APP_ID"] = admobAppId
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile")!!)
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Flutter release (also use --obfuscate --split-debug-info --tree-shake-icons):
            // flutter build appbundle --release -PADMOB_APP_ID=<your_admob_app_id>
            // Fail fast only when building a release artifact.
            val buildingRelease = gradle.startParameter.taskNames.any {
                it.contains("Release", ignoreCase = true)
            }
            if (buildingRelease &&
                admobAppId.startsWith("ca-app-pub-3940256099942544~")
            ) {
                throw GradleException(
                    "Set ADMOB_APP_ID for release builds (do not ship sample AdMob app id)."
                )
            }
            signingConfig =
                if (hasReleaseKeystore) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            // Smaller APK sideloads; Play App Bundle splits per ABI automatically.
            ndk {
                abiFilters += listOf("armeabi-v7a", "arm64-v8a")
            }
        }
    }
}

flutter {
    source = "../.."
}
