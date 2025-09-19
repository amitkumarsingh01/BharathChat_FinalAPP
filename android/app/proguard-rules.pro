# Keep ExoPlayer / Media3 classes used by just_audio
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# OkHttp / Okio used by http and player
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-keep class okio.** { *; }
-dontwarn okio.**

# Kotlin metadata
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# Keep Flutter and plugin registrant
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Keep Just Audio Android internals
-keep class com.ryanheise.just_audio.** { *; }
-dontwarn com.ryanheise.just_audio.**

# Keep ExoPlayer legacy package (if pulled transitively)
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**
