plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "org.blooddonation.tracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Application ID
        applicationId = "org.blooddonation.tracker"
        // minSdk 23 is required for modern Firebase Auth, Cloud Firestore, and Google Maps
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Maps API key from gradle property or fallback empty
        manifestPlaceholders["MAPS_API_KEY"] = project.findProperty("MAPS_API_KEY") as? String ?: ""
    }

    buildTypes {
        release {
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Automatically apply Google Services plugin when google-services.json is supplied by developer
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

