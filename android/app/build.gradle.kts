plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
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

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
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
            applicationId = "com.tenax.app"
            resValue("string", "app_name", "Tenax")
            resValue("color", "primary_color", "#4A0C54")
            resValue("color", "secondary_color", "#E8F5E8")
            resValue("color", "accent_color", "#4A0C54")
            buildConfigField("String", "FLAVOR", "\"tenax\"")
            manifestPlaceholders["FLAVOR"] = "tenax"
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

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
// Skip Google Services task only for AFX variants to avoid requiring google-services.json.
afterEvaluate {
    tasks.matching {
        it.name.startsWith("processAfx") && it.name.endsWith("GoogleServices")
    }.configureEach {
        enabled = false
    }
}


