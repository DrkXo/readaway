## ============================================================================
## ReadAway — ProGuard / R8 Rules
## ============================================================================
## Generated for tree-shaking with all project-specific packages accounted for.
## Plugins that bundle their own consumer-rules.pro (audio_service,
## flutter_local_notifications, sqflite, just_audio, etc.) are merged
## automatically by the Android Gradle Plugin. This file covers:
##   1. Flutter engine & Dart runtime
##   2. App-specific classes (MainActivity, MethodChannel handlers)
##   3. Packages whose Android code lacks bundled ProGuard rules
##   4. JNI / native-bridge keep rules
##   5. R8 optimization flags
## ============================================================================

## ---------------------------------------------------------------------------
## 1. Flutter Engine & Dart Runtime
## ---------------------------------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Generated plugin registrant — must survive tree-shaking
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

## ---------------------------------------------------------------------------
## 2. App-specific classes
## ---------------------------------------------------------------------------

# MainActivity — custom MethodChannel handler (dev.readaway/file_opener)
-keep class dev.readaway.MainActivity { *; }
-keep class dev.readaway.** { *; }

## ---------------------------------------------------------------------------
## 3. Plugin rules (for plugins that do NOT ship consumer-rules.pro)
## ---------------------------------------------------------------------------

# --- audio_service (MediaBrowserService / MediaSession / notification) ---
-keep class com.ryanheise.audioservice.** { *; }
-keep class android.support.v4.media.** { *; }
-keep class android.support.v4.media.session.** { *; }
-keep class android.support.v4.media.session.MediaSessionCompat { *; }
-keep class android.support.v4.media.session.PlaybackStateCompat { *; }
-keep class android.support.v4.media.session.MediaControllerCompat { *; }
-keep class android.media.session.** { *; }
-keep class android.media.** { *; }

# audio_service BroadcastReceiver & services
-keep class com.ryanheise.audioservice.AudioService { *; }
-keep class com.ryanheise.audioservice.MediaButtonReceiver { *; }
-keep class com.ryanheise.audioservice.** extends android.app.Service { *; }
-keep class com.ryanheise.audioservice.** extends android.content.BroadcastReceiver { *; }

# --- flutter_local_notifications (BroadcastReceiver / AlarmManager) ---
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.** extends android.content.BroadcastReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.** extends android.app.Service { *; }

# --- just_audio (androidx.media3 / Media3 ExoPlayer) ---
-keep class com.ryanheise.just_audio.** { *; }
-keep class androidx.media3.** { *; }

# --- audio_session (AudioFocus) ---
-keep class com.ryanheise.audio_session.** { *; }

# --- file_picker ---
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# --- wakelock_plus ---
-keep class dev.fluttercommunity.plus.wakelock.** { *; }
-keep class dev.fluttercommunity.plus.wakelock.WakelockPlusPlugin { *; }

# --- package_info_plus ---
-keep class dev.fluttercommunity.packageinfo.** { *; }

# --- sqflite (sqflite_android) ---
-keep class com.tekartik.sqflite.** { *; }

# --- media_kit_libs_android_audio (loads libmpv via System.loadLibrary) ---
-keep class com.alexmercerind.media_kit_libs_android_audio.** { *; }

# --- jni / jni_flutter (dart-lang/jni — loads libdartjni) ---
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.github.dart_lang.jni_flutter.** { *; }

## ---------------------------------------------------------------------------
## 4. JNI / Native Bridge
## ---------------------------------------------------------------------------
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep classes loaded by native code via JNI reflection
-keep class * {
    @android.webkit.JavascriptInterface <methods>;
}

## ---------------------------------------------------------------------------
## 5. AndroidX / Support Library (used by plugins)
## ---------------------------------------------------------------------------
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

## ---------------------------------------------------------------------------
## 6. Enum / Serializable / Parcelable (standard Android keep rules)
## ---------------------------------------------------------------------------
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

## ---------------------------------------------------------------------------
## 7. R8 Compatibility Flags
## ---------------------------------------------------------------------------

# Allow R8 to optimize away unused entries
-allowaccessmodification

# Repackage obfuscated classes into the root package for smaller APK
-repackageclasses ''

# Preserve source file names and line numbers for crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses,EnclosingMethod

# Don't warn about missing annotations
-dontwarn javax.annotation.**

# Don't warn about Kotlin metadata (generated by dart-lang plugins)
-dontwarn kotlin.**

# Don't warn about javax.inject
-dontwarn javax.inject.**

# Don't warn about proguard annotations
-dontwarn proguard.annotation.**
