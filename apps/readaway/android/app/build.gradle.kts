import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "dev.readaway"
    compileSdk = flutter.compileSdkVersion
    // NDK r28+ enables 16 KB ELF segment alignment by default for all native toolchains.
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications for scheduled notifications
        // (Java 8+ API desugaring).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.readaway"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Enable 16 KB flexible page size support for any native NDK builds
        externalNativeBuild {
            cmake {
                arguments += listOf("-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON")
            }
            ndkBuild {
                arguments += listOf("APP_SUPPORT_FLEXIBLE_PAGE_SIZES=true")
            }
        }
    }

    packaging {
        jniLibs {
            // Keep native libraries uncompressed and aligned to 16 KB page boundaries in the APK
            useLegacyPackaging = false
        }
    }

    signingConfigs {
        create("release") {
            val keyAliasVal = keystoreProperties.getProperty("keyAlias")
            val keyPasswordVal = keystoreProperties.getProperty("keyPassword")
            val storePasswordVal = keystoreProperties.getProperty("storePassword")
            val storeFileProp = keystoreProperties.getProperty("storeFile")

            if (storeFileProp != null) {
                val resolvedStoreFile = if (file(storeFileProp).isAbsolute) {
                    file(storeFileProp)
                } else {
                    rootProject.file(storeFileProp)
                }
                
                if (resolvedStoreFile.exists() && keyAliasVal != null) {
                    keyAlias = keyAliasVal
                    keyPassword = keyPasswordVal ?: storePasswordVal
                    storeFile = resolvedStoreFile
                    storePassword = storePasswordVal
                }
            }
        }
    }

    buildTypes {
        release {
            val releaseConfig = signingConfigs.getByName("release")
            signingConfig = if (releaseConfig.storeFile != null && releaseConfig.storeFile!!.exists()) {
                releaseConfig
            } else {
                signingConfigs.getByName("debug")
            }

            // Enable R8 tree-shaking and resource shrinking for release builds.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.google.android.play:core:1.10.3")
    constraints {
        implementation("org.chromium.net:cronet-api:143.7445.0")
        implementation("org.chromium.net:cronet-shared:143.7445.0")
        implementation("org.chromium.net:cronet-embedded:143.7445.0")
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
