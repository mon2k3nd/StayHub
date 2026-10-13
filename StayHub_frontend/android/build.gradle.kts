allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = File(rootProject.projectDir, "../build")
subprojects {
    project.buildDir = File(rootProject.buildDir, project.name)

    // AGP 8.x requires every Android module to declare a `namespace`.
    // Some older third-party Flutter plugins (e.g. flutter_jailbreak_detection)
    // still omit it, which fails the build. Back-fill a namespace derived from
    // the plugin's AndroidManifest `package` attribute (or a fallback) so the
    // build can proceed without patching pub-cache sources.
    plugins.withId("com.android.library") {
        val androidExt = extensions.findByName("android")
        if (androidExt is com.android.build.gradle.BaseExtension &&
            androidExt.namespace == null
        ) {
            val manifest = file("src/main/AndroidManifest.xml")
            val manifestPackage = if (manifest.exists()) {
                Regex("package=\"([^\"]+)\"")
                    .find(manifest.readText())
                    ?.groupValues
                    ?.get(1)
            } else {
                null
            }
            androidExt.namespace = manifestPackage
                ?: "com.stayhub.plugin.${project.name.replace('-', '_')}"
        }
    }

    project.evaluationDependsOn(":app")
}

// Align Java/Kotlin JVM targets across all plugin modules. Some older plugins
// (e.g. flutter_image_compress_common) compile Java at 11 while the root Kotlin
// plugin defaults to 17, which fails the build with "Inconsistent JVM Target
// Compatibility Between Java and Kotlin Tasks". This runs after every project
// is evaluated, so each module's declared Java target is already known.
gradle.projectsEvaluated {
    subprojects {
        val androidExt = extensions.findByName("android")
        if (androidExt is com.android.build.gradle.BaseExtension) {
            val kotlinTarget = when (androidExt.compileOptions.targetCompatibility) {
                JavaVersion.VERSION_1_8 -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
                JavaVersion.VERSION_11 -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
                JavaVersion.VERSION_17 -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                JavaVersion.VERSION_21 -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21
                else -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
            }
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                compilerOptions.jvmTarget.set(kotlinTarget)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
