plugins {
    id("com.android.application") version "8.7.3"
}

android {
    namespace = "com.example.ffsim"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.ffsim"
        minSdk = 23
        targetSdk = 35
        versionCode = 3
        versionName = "3.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.activity:activity:1.10.1")
}
