plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasKeystoreProperties = keystorePropertiesFile.exists()
if (hasKeystoreProperties) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "com.example.pipze"
    compileSdk = 36
    ndkVersion = "29.0.14206865"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }


    buildFeatures {
        buildConfig = true
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")

        // Tenax3 is a clone of Tenax. Reuse Tenax's manifest + resources
        // so icons/launch assets remain identical without duplicating binaries.
        maybeCreate("tenax3").apply {
            manifest.srcFile("src/tenax/AndroidManifest.xml")
            res.srcDirs("src/tenax/res")
        }
    }



    defaultConfig {
        applicationId = "com.pipze.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        // Version is automatically synced from pubspec.yaml by Flutter
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "brand"
    
    productFlavors {
        create("pipze") {
            dimension = "brand"
            applicationId = "com.pipze.app"
            resValue("string", "app_name", "Pipze")
            resValue("color", "primary_color", "#5F259E")
            resValue("color", "secondary_color", "#F8F3FF")
            resValue("color", "accent_color", "#9C27B0")
            buildConfigField("String", "FLAVOR", "\"pipze\"")
            manifestPlaceholders["FLAVOR"] = "pipze"
        }

        create("goldenwolffx") {
            dimension = "brand"
            applicationId = "com.goldenwolffx.app"
            resValue("string", "app_name", "Goldenwolffx")
            resValue("color", "primary_color", "#5F259E")
            resValue("color", "secondary_color", "#F8F3FF")
            resValue("color", "accent_color", "#9C27B0")
            buildConfigField("String", "FLAVOR", "\"goldenwolffx\"")
            manifestPlaceholders["FLAVOR"] = "goldenwolffx"
        }

        
        create("octa") {
            dimension = "brand"
            applicationId = "com.example.octa"
            resValue("string", "app_name", "Octa")
            resValue("color", "primary_color", "#FF6B35")
            resValue("color", "secondary_color", "#FFF3E0")
            resValue("color", "accent_color", "#E65100")
            buildConfigField("String", "FLAVOR", "\"octa\"")
            manifestPlaceholders["FLAVOR"] = "octa"
        }
        
        create("tenax") {
            dimension = "brand"
            applicationId = "com.tenaxcode.app"
            resValue("string", "app_name", "Tenax")
            resValue("color", "primary_color", "#4A0C54")
            resValue("color", "secondary_color", "#E8F5E8")
            resValue("color", "accent_color", "#4A0C54")
            buildConfigField("String", "FLAVOR", "\"tenax\"")
            manifestPlaceholders["FLAVOR"] = "tenax"
        }

        create("tenax3") {
            dimension = "brand"
            applicationId = "com.tenaxcode.tenax3"
            resValue("string", "app_name", "Tenax3")
            resValue("color", "primary_color", "#4A0C54")
            resValue("color", "secondary_color", "#E8F5E8")
            resValue("color", "accent_color", "#4A0C54")
            buildConfigField("String", "FLAVOR", "\"tenax3\"")
            manifestPlaceholders["FLAVOR"] = "tenax3"
        }

        create("celestial") {
            dimension = "brand"
            applicationId = "com.celestial.app"
            resValue("string", "app_name", "Celestial")
            resValue("color", "primary_color", "#4A0C54")
            resValue("color", "secondary_color", "#E8F5E8")
            resValue("color", "accent_color", "#4A0C54")
            buildConfigField("String", "FLAVOR", "\"celestial\"")
            manifestPlaceholders["FLAVOR"] = "celestial"
        }
        
        create("onsa") {
            dimension = "brand"
            applicationId = "com.example.onsa"
            resValue("string", "app_name", "ONSA")
            resValue("color", "primary_color", "#193FAD")
            resValue("color", "secondary_color", "#1E2244")
            resValue("color", "accent_color", "#193FAD")
            buildConfigField("String", "FLAVOR", "\"onsa\"")
            manifestPlaceholders["FLAVOR"] = "onsa"
        }

        create("profx") {
            dimension = "brand"
            applicationId = "app.profx.trade"
            resValue("string", "app_name", "ProFX")
            resValue("color", "primary_color", "#0D7064")
            resValue("color", "secondary_color", "#E6F5F2")
            resValue("color", "accent_color", "#132E37")
            buildConfigField("String", "FLAVOR", "\"profx\"")
            manifestPlaceholders["FLAVOR"] = "profx"
        }

        create("afx") {
            dimension = "brand"
            applicationId = "app.afx.trade"
            resValue("string", "app_name", "AFX")
            resValue("color", "primary_color", "#182430")
            resValue("color", "secondary_color", "#E8F0F5")
            resValue("color", "accent_color", "#182430")
            buildConfigField("String", "FLAVOR", "\"afx\"")
            manifestPlaceholders["FLAVOR"] = "afx"
        }

        create("kantara") {
            dimension = "brand"
            applicationId = "com.kantara.app"
            resValue("string", "app_name", "Kantara")
            resValue("color", "primary_color", "#182430")
            resValue("color", "secondary_color", "#E8F0F5")
            resValue("color", "accent_color", "#182430")
            buildConfigField("String", "FLAVOR", "\"kantara\"")
            manifestPlaceholders["FLAVOR"] = "kantara"
        }

        create("tradoxy") {
            dimension = "brand"
            applicationId = "app.tradoxy.trade"
            resValue("string", "app_name", "Tradoxy")
            resValue("color", "primary_color", "#071A2D")
            resValue("color", "secondary_color", "#E8F0F5")
            resValue("color", "accent_color", "#071A2D")
            buildConfigField("String", "FLAVOR", "\"tradoxy\"")
            manifestPlaceholders["FLAVOR"] = "tradoxy"
        }

        create("askbid") {
            dimension = "brand"
            applicationId = "com.example.askbid" // Placeholder ID
            resValue("string", "app_name", "Askbid")
            resValue("color", "primary_color", "#331533")
            resValue("color", "secondary_color", "#2EB77F")
            resValue("color", "accent_color", "#2EB77F")
            buildConfigField("String", "FLAVOR", "\"askbid\"")
            manifestPlaceholders["FLAVOR"] = "askbid"
        }

        create("sr") {
            dimension = "brand"
            applicationId = "com.example.sr" // Placeholder ID
            resValue("string", "app_name", "SR")
            resValue("color", "primary_color", "#ffffff")
            resValue("color", "secondary_color", "#0A0F19")
            resValue("color", "accent_color", "#030303")
            buildConfigField("String", "FLAVOR", "\"sr\"")
            manifestPlaceholders["FLAVOR"] = "sr"
        }

        create("vr19") {
            dimension = "brand"
            applicationId = "com.example.vr19" // TODO: Update with actual application ID
            resValue("string", "app_name", "VR19")  // TODO: Update app name if needed
            resValue("color", "primary_color", "#25456f")  // TODO: Replace with actual colors
            resValue("color", "secondary_color", "#E8F5E9")
            resValue("color", "accent_color", "#4CAF50")
            buildConfigField("String", "FLAVOR", "\"vr19\"")
            manifestPlaceholders["FLAVOR"] = "vr19"
        }
    }

    signingConfigs {
        create("release") {
            if (hasKeystoreProperties) {
                val storeFilePath = (keystoreProperties["storeFile"] as String).trim()
                // Resolve relative to the Android root project (`android/`), not `android/app/`.
                storeFile = if (storeFilePath.isNotEmpty()) rootProject.file(storeFilePath) else null
                storePassword = (keystoreProperties["storePassword"] as String).trim()
                keyAlias = (keystoreProperties["keyAlias"] as String).trim()
                keyPassword = (keystoreProperties["keyPassword"] as String).trim()
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasKeystoreProperties) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            isDebuggable = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// AFX flavor currently has no Firebase config.
// Skip Google Services task for flavors without Firebase config
// to avoid requiring google-services.json.
afterEvaluate {
    tasks.matching {
        it.name.startsWith("processAfx") && it.name.endsWith("GoogleServices")
    }.configureEach {
        enabled = false
    }

  // Kantara flavor currently has no Firebase config.
  tasks.matching {
    it.name.startsWith("processKantara") && it.name.endsWith("GoogleServices")
  }.configureEach {
    enabled = false
  }

  // Askbid flavor currently has no Firebase config.
  tasks.matching {
    it.name.startsWith("processAskbid") && it.name.endsWith("GoogleServices")
  }.configureEach {
    enabled = false
  }

  // Celestial flavor currently has no dedicated Firebase config (cloned from Tenax at first).
  // Disable Google Services until a Celestial google-services.json is provided.
  tasks.matching {
    it.name.startsWith("processCelestial") && it.name.endsWith("GoogleServices")
  }.configureEach {
    enabled = false
  }

  // Goldenwolffx flavor currently has no Firebase config.
  tasks.matching {
    it.name.startsWith("processGoldenwolffx") && it.name.endsWith("GoogleServices")
  }.configureEach {
    enabled = false
  }
}



