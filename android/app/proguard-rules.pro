## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## Keep MainActivity (critical fix for ClassNotFoundException)
-keep class com.gopayna.app.MainActivity { *; }
-keep class com.gopayna.app.** { *; }

## Dart
-keep class androidx.lifecycle.** { *; }

## Keep WebView classes
-keep class android.webkit.** { *; }
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
    public void *(android.webkit.WebView, java.lang.String);
}

## Google Play Core (fix missing classes)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

## OkHttp / Retrofit (if used by any plugin)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

## Gson (used by many plugins)
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

## SharedPreferences
-keep class androidx.datastore.** { *; }

## URL Launcher
-keep class android.content.Intent { *; }

## Image Picker
-keep class androidx.core.content.FileProvider { *; }
-keep class androidx.exifinterface.** { *; }

## Prevent stripping of native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

## Keep Parcelables
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

## Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

## Crypto library
-keep class javax.crypto.** { *; }

## Prevent R8 from removing exception classes
-keep public class * extends java.lang.Exception
