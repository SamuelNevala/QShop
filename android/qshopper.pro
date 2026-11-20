# Qt calls Java classes and methods by name from JNI. Retain that boundary;
# R8 can still optimize unused AndroidX code and Android resources.
-keep class org.qtproject.qt.android.** { *; }

# The haptics bridge reaches these members by JNI name.
-keep class androidx.core.view.HapticFeedbackConstantsCompat {
    public static final int CONFIRM;
    public static final int TOGGLE_ON;
    public static final int TOGGLE_OFF;
    public static final int DRAG_START;
    public static final int GESTURE_END;
    public static final int SEGMENT_TICK;
    public static final int REJECT;
}
-keep class androidx.core.view.ViewCompat {
    public static boolean performHapticFeedback(android.view.View, int);
}
