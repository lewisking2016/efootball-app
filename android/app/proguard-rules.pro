# Google ML Kit Proguard Rules to prevent R8 shrinking issues during release builds
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Firebase/Firestore Proguard rules just in case
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
