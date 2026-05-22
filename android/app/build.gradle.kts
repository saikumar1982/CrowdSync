plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.crowdsync.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.crowdsync.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "mode"
    productFlavors {
        create("star") {
            dimension = "mode"
            applicationIdSuffix = ".star"
            resValue("string", "app_name", "CrowdSync Star")
        }
        create("mesh") {
            dimension = "mode"
            applicationIdSuffix = ".mesh"
            resValue("string", "app_name", "CrowdSync Mesh")
        }
        create("router") {
            dimension = "mode"
            applicationIdSuffix = ".router"
            resValue("string", "app_name", "CrowdSync Router")
        }
        create("all") {
            dimension = "mode"
            resValue("string", "app_name", "CrowdSync")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
