# WorkManager is pulled in transitively by google_mobile_ads. It creates its Room
# database reflectively (Class.forName("...WorkDatabase_Impl")), so R8 renaming the
# generated *_Impl class kills the app at startup in release builds:
#   Unable to get provider androidx.startup.InitializationProvider
#   Caused by: Failed to create an instance of androidx.work.impl.WorkDatabase
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-dontwarn androidx.work.**

# androidx.startup initializers are named only in the manifest, never called from
# code, so R8 has no reference to keep them alive.
-keep class * implements androidx.startup.Initializer { *; }
