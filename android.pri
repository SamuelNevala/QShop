android {

#    QT += androidextras
#    # Android dependencies
#    ANDROID_DEPLOYMENT_DEPENDENCIES = \
#        jar/QtAndroid-bundled.jar \
#        jar/QtAndroidAccessibility-bundled.jar \
#        jar/QtAndroidBearer-bundled.jar \
#        lib/libQt5Core.so \
#        lib/libQt5Gui.so \
#        lib/libQt5Network.so \
#        lib/libQt5Qml.so \
#        lib/libQt5Quick.so \
#        lib/libQt5AndroidExtras.so \
#        qml/QtGraphicalEffects/qmldir \
#        qml/QtGraphicalEffects/ColorOverlay.qml \
#        qml/QtGraphicalEffects/private/SourceProxy.qml \
#        qml/QtQuick/Controls/qmldir \
#        qml/QtQuick/Controls/Private/qmldir \
#        qml/QtQuick/Controls/libqtquickcontrolsplugin.so \
#        qml/QtQuick/Controls/Styles/Android/drawables/AnimationDrawable.qml \
#        qml/QtQuick/Controls/Styles/Android/drawables/ClipDrawable.qml \
#        qml/QtQuick/Controls/Styles/Android/drawables/ColorDrawable.qml \
#        qml/QtQuick/Controls/Styles/Android/drawables/Drawable.qml \
#        qml/QtQuick/Controls/Styles/Android/drawables/DrawableLoader.qml \
#        qml/QtQuick/Controls/Styles/Android/drawables/GradientDrawable.qml \
#        qml/QtQuick/Controls/Styles/Android/drawables/ImageDrawable.qml \
#        qml/QtQuick/Controls/Styles/Android/drawables/LayerDrawable.qml \
#        qml/QtQuick/Controls/Styles/Android/drawables/NinePatchDrawable.qml \
#        qml/QtQuick/Controls/Styles/Android/drawables/RotateDrawable.qml \
#        qml/QtQuick/Controls/Styles/Android/drawables/StateDrawable.qml \
#        qml/QtQuick/Controls/Styles/Android/AndroidStyle.qml \
#        qml/QtQuick/Controls/Styles/Android/ButtonStyle.qml \
#        qml/QtQuick/Controls/Styles/Android/CursorHandleStyle.qml \
#        qml/QtQuick/Controls/Styles/Android/FocusFrameStyle.qml \
#        qml/QtQuick/Controls/Styles/Android/qmldir \
#        qml/QtQuick/Controls/Styles/Android/ScrollViewStyle.qml \
#        qml/QtQuick/Controls/Styles/Android/TextFieldStyle.qml \
#        qml/QtQuick/Controls/Styles/Android/libqtquickcontrolsandroidstyleplugin.so \
#        qml/QtQuick/Window.2/qmldir \
#        qml/QtQuick/Window.2/libwindowplugin.so \
#        qml/QtQuick.2/qmldir \
#        qml/QtQuick.2/libqtquick2plugin.so \
#        plugins/platforms/android/libqtforandroid.so

#        #qml/QtQuick/Controls/Styles/Android/CheckBoxStyle.qml \
#        #qml/QtQuick/Controls/Styles/Android/ComboBoxStyle.qml \
#        #qml/QtQuick/Controls/Styles/Android/LabelStyle.qml \
#        #qml/QtQuick/Controls/Styles/Android/RadioButtonStyle.qml \
#        #qml/QtQuick/Controls/Styles/Android/SwitchStyle.qml \
#        #qml/QtQuick/Dialogs/qmldir \
#        #qml/QtQuick/Dialogs/libdialogplugin.so \
#        #qml/QtQuick/Dialogs/Private/qmldir \
#        #qml/QtQuick/Dialogs/Private/libdialogsprivateplugin.so \
#        #qml/QtQuick/Layouts/qmldir \
#        #qml/QtQuick/Layouts/libqquicklayoutsplugin.so \
#        #qml/QtQuick/Layouts/qmldir \
#        #qml/QtQuick/Layouts/libqquicklayoutsplugin.so \
#        #plugins/position/libqtposition_android.so \
#        #plugins/position/libqtposition_positionpoll.so \
#        #plugins/bearer/libqandroidbearer.so
#        #qml/Qt/labs/settings/qmldir \
#        #qml/Qt/labs/settings/libqmlsettingsplugin.so \

    ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android
    OTHER_FILES += android/AndroidManifest.xml
}
