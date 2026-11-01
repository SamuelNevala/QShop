pragma Singleton
import QtCore
import QtQuick
import QtQuick.Controls.Material

Item {
    id: root

    // Attach this singleton Item to the app's content item so Screen follows its window.
    property bool scaleable: false
    readonly property real minimumScale: 0.25
    readonly property real maximumScale: 4.0
    readonly property real effectiveScale: scaleable && isFinite(scale) ? Math.max(minimumScale,
                                                                                   Math.min(maximumScale,
                                                                                            scale)) : 1.0
    // Only the desktop debug preview compensates for this TV's incorrect HDMI size.
    readonly property real densityCorrection: scaleable && Qt.platform.os === "windows"
                                              && Screen.name === "LG TV SSCR2" ? 1.5 : 1.0
    readonly property real pixelsPerMillimeter: Screen.pixelDensity * densityCorrection
                                                * effectiveScale
    property alias accent: settings.accent
    property alias primary: settings.primary
    property alias theme: settings.theme
    property alias activeList: settings.activeList
    property alias swipeSensitivity: settings.swipeSensitivity
    readonly property int inverseTheme: Material.theme === Material.Dark ? Material.Light :
                                                                           Material.Dark

    function scaleUp() {
        if (!scaleable) {
            return;
        }
        scale = Math.min(maximumScale, Math.round((effectiveScale + 0.1) * 100) / 100);
    }

    function scaleDown() {
        if (!scaleable) {
            return;
        }
        scale = Math.max(minimumScale, Math.round((effectiveScale - 0.1) * 100) / 100);
    }

    function pixels(millimeter) {
        return millimeter * pixelsPerMillimeter;
    }

    function millimeters(pixels) {
        return pixels / pixelsPerMillimeter;
    }

    function accentColor() {
        return colorAccent(accent);
    }

    function primaryColor() {
        return color(primary);
    }

    function accentColorLighter() {
        if (accent === Material.Grey || accent === Material.Brown || accent === Material.BlueGrey) {
            return color(accent);
        }
        return Material.color(accent, Material.theme === Material.Dark ? Material.ShadeA100 :
                                                                         Material.ShadeA200);
    }

    function primaryColorLighter() {
        return Material.color(primary, Material.theme === Material.Dark ? Material.Shade50 :
                                                                          Material.Shade300);
    }

    function color(value) {
        return Material.color(value, Material.theme === Material.Dark ? Material.Shade200 :
                                                                        Material.Shade500);
    }

    function colorAccent(value) {
        if (value === Material.Grey || value === Material.Brown || value === Material.BlueGrey) {
            return color(value);
        }
        return Material.color(value, Material.theme === Material.Dark ? Material.ShadeA200 :
                                                                        Material.ShadeA400);
    }

    Material.theme: theme
    visible: false
    scale: 2.0

    Settings {
        id: settings

        property alias scale: root.scale
        property var accent: value("accent", Material.Green)
        property var primary: value("primary", Material.Indigo)
        property int theme: value("theme", Material.Dark)
        property string activeList: value("activeList", "default")
        property real swipeSensitivity: value("swipeSensitivity", 1.0)
    }
}
