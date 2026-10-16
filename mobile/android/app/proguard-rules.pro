# Flutter & ATLAS R8 / ProGuard Optimization Rules
# Preserve Flutter engine entry points and JNI bindings
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }

# Suppress Play Core warnings (optional deferred components not used in standalone APK)
-dontwarn com.google.android.play.core.**

# Preserve JSON serialized data models
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Preserve Secure Storage and Keystore interfaces
-keep class androidx.security.crypto.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Preserve JNI wrappers
-keepclasseswithmembernames class * {
    native <methods>;
}
