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

    function luminance(value) {
        function linear(channel) {
            return channel <= 0.04045 ? channel / 12.92 : Math.pow((channel + 0.055) / 1.055, 2.4);
        }
        return 0.2126 * linear(value.r) + 0.7152 * linear(value.g) + 0.0722 * linear(value.b);
    }

    function foregroundOn(background) {
        // Relative luminance where black and white provide equal contrast.
        return luminance(background) > 0.179 ? "black" : "white";
    }

    function contrastRatio(foreground, background) {
        const apparent = Qt.rgba(foreground.r * foreground.a + background.r * (1 - foreground.a),
                                 foreground.g * foreground.a + background.g * (1 - foreground.a),
                                 foreground.b * foreground.a + background.b * (1 - foreground.a),
                                 1);


        const front = luminance(apparent);
        const back = luminance(background);
        return (Math.max(front, back) + 0.05) / (Math.min(front, back) + 0.05);
    }

    function accentFillColor() {
        let fill = accentColor();
        const tone = Material.theme === Material.Dark ? Qt.rgba(0, 0, 0, 0.1) : Qt.rgba(1, 1, 1,
                                                                                        0.1);


        // Keep normal text; leave a small margin for 8-bit rendered-color rounding.
        for (let step = 0; step < 30 && contrastRatio(Material.primaryTextColor, fill)
             < 4.6; ++step) {
            fill = Qt.tint(fill, tone);
        }
        return fill;
    }

    function readableInk(ink, surface, opacity = 1, minimum = 4.5) {
        // Neutral translucent surfaces must work over either end of a photograph.
        const dark = luminance(surface) < 0.179;
        const background = Qt.tint(dark ? "white" : "black", Qt.alpha(surface, opacity));
        const tone = dark ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.1);
        let result = ink;
        // Preserve the selected hue; adjust only ink that needs more contrast.
        for (let step = 0; step < 30 && contrastRatio(result, background) < minimum + 0.1; ++step) {
            result = Qt.tint(result, tone);
        }
        return result;
    }

    function accentColorLighter() {
        if (accent === Material.Grey || accent === Material.Brown || accent === Material.BlueGrey) {
            return color(accent);
        }
        return Material.color(accent, Material.theme === Material.Dark ? Material.ShadeA100 :
                                                                         Material.ShadeA200);
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
