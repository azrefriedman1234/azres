plugins {
  id("com.android.application")
  id("org.jetbrains.kotlin.android")
}

android {
  namespace = "com.pasiflonet.mobile"
  compileSdk = 34

  defaultConfig {
    applicationId = "com.pasiflonet.mobile"
    minSdk = 26
    targetSdk = 34
    versionCode = 1
    versionName = "1.0"
  }

  buildFeatures { compose = true }
  composeOptions { kotlinCompilerExtensionVersion = "1.5.14" }

  packaging {
    resources.excludes += setOf("META-INF/*")
  }
}

dependencies {
  // AARים שנבנים ב-CI ומועתקים לפה:
  implementation(files("libs/tdlib-built.aar"))
  implementation(files("libs/ffmpeg-kit-built.aar"))

  implementation("androidx.core:core-ktx:1.13.1")
  implementation("androidx.activity:activity-compose:1.9.2")
  implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.6")
  implementation("androidx.compose.ui:ui:1.7.4")
  implementation("androidx.compose.ui:ui-tooling-preview:1.7.4")
  implementation("androidx.compose.material3:material3:1.3.0")
  debugImplementation("androidx.compose.ui:ui-tooling:1.7.4")

  // WorkManager לרקע
  implementation("androidx.work:work-runtime-ktx:2.9.1")
}
