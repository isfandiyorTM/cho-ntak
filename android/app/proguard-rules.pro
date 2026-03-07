# ── Flutter ───────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Flutter Play Store split — classes not present outside Play Store builds
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# ── sqflite ───────────────────────────────────────────────────────────────────
-keep class com.tekartik.sqflite.** { *; }

# ── local_auth / biometric ────────────────────────────────────────────────────
-keep class androidx.biometric.** { *; }
-keep class io.flutter.plugins.localauth.** { *; }

# ── flutter_local_notifications ───────────────────────────────────────────────
-keep class com.dexterous.** { *; }

# ── shared_preferences ───────────────────────────────────────────────────────
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# ── timezone ──────────────────────────────────────────────────────────────────
-keep class com.google.android.** { *; }

# ── iconsax / fonts ───────────────────────────────────────────────────────────
-keep class **.R$* { *; }

# ── General Android ──────────────────────────────────────────────────────────
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Suppress all warnings from missing classes R8 finds in Flutter internals
-ignorewarnings