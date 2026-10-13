# =============================================================================
# StayHub - R8 / ProGuard rules
# Keeps reflection-based plugin entry points alive while allowing aggressive
# shrinking of everything else. Verified against the plugin set in pubspec.yaml.
# =============================================================================

# --- Flutter engine ---
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# --- Google ML Kit (text recognition, barcode, face detection) ---
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.internal.mlkit_**

# --- Firebase (core, messaging, auth) ---
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# --- Google Play Core (deferred components / split install) ---
-dontwarn com.google.android.play.core.**

# --- Kotlin / coroutines ---
-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**

# --- Gson / JSON reflection used by some plugins ---
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# --- Square / OkHttp (dio native bridges, image loading) ---
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**

# --- Syncfusion (PDF viewer / XlsIO) ---
-keep class com.syncfusion.** { *; }
-dontwarn com.syncfusion.**

# --- Native / JNI bridges (image compress, jni, record, screen protector) ---
-keepclasseswithmembernames class * {
    native <methods>;
}

# --- Parcelable / Serializable (state restoration) ---
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# --- Enum valueOf/values used by reflection ---
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# --- Keep the app entry point ---
-keep class com.stayhub.app.MainActivity { *; }

# --- AndroidX Window (referenced reflectively; classes are optional at runtime) ---
# R8 reports these as missing because androidx.window probes vendor extension
# classes via reflection. They are only present on some OEM devices, so keep
# the library and silence the missing-class warnings.
-keep class androidx.window.** { *; }
-dontwarn androidx.window.**

# --- Suppress warnings for optional/desktop-only classes ---
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**
-dontwarn javax.annotation.**
-dontwarn java.lang.invoke.**
