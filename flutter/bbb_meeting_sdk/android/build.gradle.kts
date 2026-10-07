// Flutter plugin module for the BigBlueButton meeting SDK (org.bigbluebutton.bbb:meeting-sdk-fused-release).
// Layout follows Flutter's own plugin template (flutter create --template=plugin, Flutter 3.47); the
// Flutter Gradle plugin applies kotlin-android to this project itself.
group = "org.bigbluebutton.bbb.flutter"
version = "0.1.0"

buildscript {
    val kotlinVersion = "2.4.0"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

val bbbSdkVersion = "0.1.0"

// The SDK's static Maven repository (github.com/ahmad-bbbb/bigbluebutton-mobile-sdk-maven), or the
// android/maven folder of an SDK build checkout next to the plugin. Override with
// `bbbSdkMavenUrl=<https or file:// URL>` in the app's gradle.properties.
val localMaven = File(projectDir, "../../../android/maven")
val bbbSdkMavenUrl: String = (findProperty("bbbSdkMavenUrl") as String?)
    ?: if (localMaven.isDirectory) localMaven.toURI().toString()
    else "https://raw.githubusercontent.com/ahmad-bbbb/bigbluebutton-mobile-sdk-maven/main"

/**
 * A debug build of the host app selects the *debug* variants of react-android / hermes-android.
 * Their native libraries do not match the release-built SDK and crash at startup (SIGSEGV).
 * Keep the variant Gradle picks, but hand it the release AAR.
 */
abstract class BbbReleaseNativeLibsRule : ComponentMetadataRule {
    override fun execute(context: ComponentMetadataContext) {
        val id = context.details.id
        val releaseAar = "${id.name}-${id.version}-release.aar"
        listOf("debugVariantDefaultApiPublication", "debugVariantDefaultRuntimePublication").forEach { variant ->
            context.details.withVariant(variant) {
                withFiles {
                    removeAllFiles()
                    addFile(releaseAar)
                }
            }
        }
    }
}

rootProject.allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri(bbbSdkMavenUrl)
            content { includeGroup("org.bigbluebutton.bbb") }   // only the SDK comes from here
        }
    }
    configurations.all {
        // fbjni 0.8.x (NDK 28) crashes React Native 0.86 at startup; keep the version RN pins.
        resolutionStrategy.force("com.facebook.fbjni:fbjni:0.7.0")
    }
    dependencies.components {
        withModule<BbbReleaseNativeLibsRule>("com.facebook.react:react-android")
        // Hermes is published under com.facebook.hermes (React Native 0.86); the old group is a no-op.
        withModule<BbbReleaseNativeLibsRule>("com.facebook.hermes:hermes-android")
        withModule<BbbReleaseNativeLibsRule>("com.facebook.react:hermes-android")
    }
}

plugins {
    id("com.android.library")
}

android {
    namespace = "org.bigbluebutton.bbb.flutter"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
        // R8 keep rules for the fused SDK AAR (see consumer-rules.pro); applied to the host app.
        consumerProguardFiles("consumer-rules.pro")
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    api("org.bigbluebutton.bbb:meeting-sdk-fused-release:$bbbSdkVersion")
    // Kept outside the fused AAR by expo-brownfield; the SDK needs them at runtime.
    api("com.google.android.material:material:1.12.0")
    api("com.google.guava:guava:33.4.0-android")
}
