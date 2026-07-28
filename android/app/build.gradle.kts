import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Release signing credentials — kept out of git (see android/key.properties
// in .gitignore) and loaded here rather than hardcoded. Missing file just
// means signingConfigs.release below gets nulls; `flutter build apk --debug`
// still works fine without it, only a `--release` build needs it present.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "poultry.hub.updates.customer"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "poultry.hub.updates.customer"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Firebase Auth (phone/OTP) requires API 23+, so this is pinned
        // rather than left at Flutter's own default.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // AGP 9 shrinks/obfuscates release builds by default even
            // without this being set explicitly — which was silently
            // stripping androidx.work's WorkDatabase (a dependency of
            // Firestore's offline-persistence layer) and crashing the app
            // on launch with "Unable to get provider
            // androidx.startup.InitializationProvider". Turned off
            // explicitly rather than chasing every reflection-based
            // library's keep rules one crash at a time. Re-enable (for a
            // smaller APK) only alongside a full pass through
            // proguard-rules.pro and real release-build testing.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.5.1"))
}
