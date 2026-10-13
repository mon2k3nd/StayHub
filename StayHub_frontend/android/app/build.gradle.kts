plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.stayhub.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.stayhub.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // R8 code shrinking + obfuscation to reduce APK size and improve runtime.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")

            // NOTE: Do NOT restrict ABIs here with `ndk { abiFilters }`.
            // The Flutter Gradle plugin injects its own `ndk.abiFilters` for every
            // ABI *after* this block is evaluated, so any value set here is
            // overridden and the release APK ends up containing all ABIs
            // (~169 MB). The arm64-only release build is instead driven by
            // `--target-platform android-arm64` in build_apk.ps1, which selects
            // the ABI at the Flutter tool level before Gradle runs.
            //
            // Debug builds (`flutter run`) therefore keep ALL ABIs, so the app
            // runs on x86_64 Android emulators without the
            // `MissingLibraryException: Could not find 'libflutter.so'` crash.
        }
    }

    // NOTE: Per-ABI APK splitting is driven by the `--split-per-abi` build flag
    // (see build_apk.ps1) instead of a `splits {}` block here, because the
    // Flutter Gradle plugin already injects `ndk.abiFilters` and the two
    // configurations conflict ("Conflicting configuration ... in ndk abiFilters
    // cannot be present when splits abi filters are set").

    androidResources {
        noCompress += listOf(
            "tflite", "lite", "pb", "binarypb", "emd", "bincfg",
            "conv_model", "lstm_model", "tfl"
        )
    }

    packaging {
        resources {
            // Drop duplicate/legal metadata that bloats the APK.
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/*.kotlin_module",
                "META-INF/AL2.0",
                "META-INF/LGPL2.1",
                "DebugProbesKt.bin",
                "kotlin-tooling-metadata.json"
            )
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
