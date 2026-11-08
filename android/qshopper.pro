# Qt calls Java classes and methods by name from JNI. Retain that boundary;
# R8 can still optimize unused AndroidX code and Android resources.
-keep class org.qtproject.qt.android.** { *; }
