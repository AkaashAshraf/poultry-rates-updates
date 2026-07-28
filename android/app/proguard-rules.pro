-keep class com.google.firebase.** { *; }
-keep class io.flutter.plugins.** { *; }

# Not currently applied — isMinifyEnabled is off (see app/build.gradle.kts)
# specifically because R8 was stripping this exact class and crashing the
# app on launch (Firestore's offline-persistence layer depends on
# WorkManager internally). Left here so re-enabling shrinking later starts
# from a working baseline instead of rediscovering this the hard way.
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.work.ListenableWorker {
    <init>(android.content.Context, androidx.work.WorkerParameters);
}
