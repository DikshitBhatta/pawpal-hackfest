# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Critical fix for Stripe React Native SDK missing classes
-dontwarn com.reactnativestripesdk.**
-dontwarn com.stripe.android.pushProvisioning.**

# Keep all Stripe related classes
-keep class com.stripe.android.** { *; }
-keep class com.stripe.** { *; }

# Specifically keep the missing push provisioning classes
-keep class com.stripe.android.pushProvisioning.** { *; }

# Keep React Native Stripe SDK classes
-keep class com.reactnativestripesdk.** { *; }

# Flutter Stripe plugin compatibility
-keep class io.flutter.plugins.** { *; }

# Keep all annotation-related classes for Stripe
-keepattributes Signature, InnerClasses, EnclosingMethod
-keepattributes RuntimeVisibleAnnotations, RuntimeVisibleParameterAnnotations
-keepattributes AnnotationDefault

# Additional safety rules for potential missing classes
-keep class * extends java.lang.Exception
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Firebase compatibility (since you're using Firebase)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
