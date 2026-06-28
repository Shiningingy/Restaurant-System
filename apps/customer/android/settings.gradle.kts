pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // Pinned to AGP 8.9.x (window: 8.9.1 ≤ AGP < 9.0). The flutter_inappwebview_
    // android plugin (online-payment WebView) references the legacy
    // getDefaultProguardFile('proguard-android.txt') that AGP 9 removed, so AGP 9
    // can't evaluate it; meanwhile androidx core/browser require ≥ 8.9.1. The
    // merchant app stays on 9.0.1 (it has no webview).
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")
