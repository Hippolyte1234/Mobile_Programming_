plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.shoe_vault_project"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Syntaxe stricte Kotlin DSL
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        // jvmTarget doit être une String
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.shoe_vault_project"
        // Indispensable pour le desugaring
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
