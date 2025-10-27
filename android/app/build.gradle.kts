plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.pipze"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    buildFeatures {
        buildConfig = true
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        applicationId = "com.example.pipze"
        minSdk = 21
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
    }

    flavorDimensions += "brand"
    
    productFlavors {
        create("pipze") {
            dimension = "brand"
            applicationId = "com.example.pipze"
            resValue("string", "app_name", "Pipze")
            resValue("color", "primary_color", "#5A2DD8")
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
        
        create("fleza") {
            dimension = "brand"
            applicationId = "com.example.fleza"
            resValue("string", "app_name", "Fleza")
            resValue("color", "primary_color", "#4CAF50")
            resValue("color", "secondary_color", "#E8F5E8")
            resValue("color", "accent_color", "#2E7D32")
            buildConfigField("String", "FLAVOR", "\"fleza\"")
            manifestPlaceholders["FLAVOR"] = "fleza"
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
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
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
