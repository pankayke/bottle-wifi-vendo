# ===== Flutter engine & plugin framework =====
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep annotations (used by Kotlin, Gson, and plugins)
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# ===== Kotlin runtime (required by Kotlin-based plugins) =====
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**
-keep class kotlin.Metadata { *; }

# ===== AndroidX (used by modern Flutter plugins) =====
-keep class androidx.** { *; }
-dontwarn androidx.**

# ===== HTTP / serialisation (if ever needed) =====
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**
-dontwarn okhttp3.**
-dontwarn okio.**

# Suppress missing Play Core classes
-dontwarn com.google.android.play.core.**

# ===== sqflite_android (v2.x uses com.tekartik namespace) =====
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**
# Legacy sqflite class name (kept for safety)
-keep class io.flutter.plugins.sqflite.** { *; }
-keep class org.sqlite.** { *; }
-dontwarn org.sqlite.**

# ===== device_info_plus =====
-keep class dev.fluttercommunity.plus.device_info.** { *; }

# ===== shared_preferences =====
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# ===== Keep all Flutter plugin registrant classes =====
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
