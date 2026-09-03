plugins {
    id("com.android.application")
}

fun Project.stringProperty(name: String): String =
    providers.gradleProperty(name).orElse("").get()

android {
    namespace = "com.zuhayrkabir.localmatchtrack"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.zuhayrkabir.localmatchtrack.kotlin"
        minSdk = 24
        targetSdk = 37
        versionCode = 1
        versionName = "0.1.0"

        buildConfigField("String", "DITTO_DATABASE_ID", "\"${project.stringProperty("DITTO_DATABASE_ID")}\"")
        buildConfigField("String", "DITTO_SERVER_URL", "\"${project.stringProperty("DITTO_SERVER_URL")}\"")
        buildConfigField("String", "DITTO_PLAYGROUND_TOKEN", "\"${project.stringProperty("DITTO_PLAYGROUND_TOKEN")}\"")
    }

    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

}

dependencies {
    implementation("com.ditto:ditto-kotlin:5.1.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
}
