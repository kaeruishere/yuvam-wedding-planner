plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // 1. BURAYI EKLE: Google Services plugin'ini buraya tanıtıyoruz
    id("com.google.gms.google-services")
}

android {
    // Firebase Console'daki package name ile aynı olmalı!
    namespace = "com.kaeru.yuvam" 
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // 2. DİKKAT: Buradaki "com.example.yuvam"ı "com.kaeru.yuvam" yap kanki
        applicationId = "com.kaeru.yuvam"
        
        // 3. BURAYI EKLE: Firebase için minSdk genelde 21 istenir
        minSdk = 26 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 4. BURAYI EKLE: Metod sınırı hatasını (multidex) önlemek için
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
