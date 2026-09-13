plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.github.vauvenal5.yaga"
//    compileSdk = flutter.compileSdkVersion
    compileSdk = 36
//    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.github.vauvenal5.yaga"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        //minSdk = flutter.minSdkVersion
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

// Rename the release APK with the app version after Gradle packages it.
tasks.register("versionReleaseApk") {
    val apk = layout.buildDirectory.file("outputs/flutter-apk/app-release.apk")
    val versionedApk = layout.buildDirectory.file("outputs/flutter-apk/app-release-${flutter.versionName}.apk")

    doLast {
        val source = apk.get().asFile
        check(source.exists()) { "Release APK not found: $source" }
        source.copyTo(versionedApk.get().asFile, overwrite = true)
    }
}

tasks.matching { it.name == "assembleRelease" }.configureEach {
    finalizedBy("versionReleaseApk")
}
