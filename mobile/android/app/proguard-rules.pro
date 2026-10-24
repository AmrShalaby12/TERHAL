# Flutter plugins ship their own consumer rules. Keep Firebase model metadata
# and foreground-service entry points that are reached through reflection.
-keepattributes *Annotation*
-keep class io.flutter.plugins.firebase.** { *; }
-keep class com.pravera.flutter_foreground_task.** { *; }
