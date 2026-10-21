import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Keep release credentials in the ignored local properties file, not in this build script.
val signingPropertiesFile = rootProject.file("key.properties")
val signingProperties = Properties().apply {
    if (signingPropertiesFile.exists()) {
        signingPropertiesFile.inputStream().use { load(it) }
    }
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

    signingConfigs {
        create("release") {
            if (signingPropertiesFile.exists()) {
                storeFile = rootProject.file(signingProperties.getProperty("storeFile"))
                storePassword = signingProperties.getProperty("storePassword")
                keyAlias = signingProperties.getProperty("keyAlias")
                keyPassword = signingProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Keep local release runs working while CI uses the configured upload key.
            signingConfig = signingConfigs.getByName(
                if (signingPropertiesFile.exists()) "release" else "debug",
            )
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
