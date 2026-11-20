#include "haptics.h"

#ifdef Q_OS_ANDROID
#  include <QtCore/QJniObject>
#  include <QtCore/qcoreapplication_platform.h>
#  include <QtGui/QGuiApplication>
#endif

void Haptics::play(Feedback feedback)
{
    const char *constant = nullptr;
    switch (feedback) {
    case Confirm:
        constant = "CONFIRM";
        break;
    case ToggleOn:
        constant = "TOGGLE_ON";
        break;
    case ToggleOff:
        constant = "TOGGLE_OFF";
        break;
    case DragStart:
        constant = "DRAG_START";
        break;
    case GestureEnd:
        constant = "GESTURE_END";
        break;
    case SegmentTick:
        constant = "SEGMENT_TICK";
        break;
    case Reject:
        constant = "REJECT";
        break;
    default:
        return;
    }

    Q_EMIT requested(feedback);

#ifdef Q_OS_ANDROID
    if (QGuiApplication::applicationState() != Qt::ApplicationActive) {
        return;
    }

    QNativeInterface::QAndroidApplication::runOnAndroidMainThread([constant] {
        if (!QNativeInterface::QAndroidApplication::isActivityContext()) {
            return;
        }
        const QJniObject activity = QNativeInterface::QAndroidApplication::context();
        const auto window = activity.callMethod<QJniObject>("getWindow", "()Landroid/view/Window;");
        if (!window.isValid()) {
            return;
        }
        const auto view = window.callMethod<QJniObject>("getDecorView", "()Landroid/view/View;");
        if (!view.isValid() || !view.callMethod<jboolean>("isShown")
            || !view.callMethod<jboolean>("hasWindowFocus")) {
            return;
        }

        const auto effect = QJniObject::getStaticField<jint>(
                "androidx/core/view/HapticFeedbackConstantsCompat", constant);
        // AndroidX provides older-API fallbacks; no flags override system settings.
        QJniObject::callStaticMethod<jboolean>("androidx/core/view/ViewCompat",
                                               "performHapticFeedback", "(Landroid/view/View;I)Z",
                                               view.object<jobject>(), effect);
    });
#else
    Q_UNUSED(constant);
#endif
}
