plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // This matches the one we added above
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.revolveagro"
<<<<<<< HEAD
    compileSdk = 36
=======
    compileSdk = flutter.compileSdkVersion
>>>>>>> a097ec79059626f4258e97ebf8a5f1160a58e203
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
>>>>>>> a097ec79059626f4258e97ebf8a5f1160a58e203
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
