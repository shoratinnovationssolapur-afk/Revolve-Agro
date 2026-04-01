plugins {
    id("com.android.application")
<<<<<<< HEAD
    id("com.google.gms.google-services") // This matches the one we added above
    id("kotlin-android")
=======
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
>>>>>>> 386a876 (initial commit)
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.revolveagro"
<<<<<<< HEAD
    compileSdk = 36
=======
    compileSdk = flutter.compileSdkVersion
>>>>>>> 386a876 (initial commit)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.revolveagro"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
<<<<<<< HEAD
        targetSdk = 36
=======
        targetSdk = flutter.targetSdkVersion
>>>>>>> 386a876 (initial commit)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
