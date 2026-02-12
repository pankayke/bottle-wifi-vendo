# Flutter-specific ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep annotations
-keepattributes *Annotation*

# Keep HTTP client classes
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**
-dontwarn okhttp3.**
-dontwarn okio.**

# Suppress missing Play Core classes (not needed for non-Play Store builds)
-dontwarn com.google.android.play.core.**
