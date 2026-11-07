pragma ComponentBehavior: Bound
import QShopper
import QShopper as Shop
import QtQuick
import QtQuick.Controls.Material as Controls
import QtQuick.Controls.Material
import QtQuick.Window
import QtTest

Item {
    id: scene

    width: 900
    height: 900
    Material.theme: Theme.theme
    Material.primary: Theme.primaryColor()
    Material.accent: Theme.accentColor()

    Binding {
        target: Theme
        property: "parent"
        value: scene
    }

    Binding {
        target: scene.Window.window.Material
        property: "theme"
        value: Theme.theme
    }

    Binding {
        target: scene.Window.window.Material
        property: "primary"
        value: Theme.primaryColor()
    }

    Binding {
        target: scene.Window.window.Material
        property: "accent"
        value: Theme.accentColor()
    }

    Rectangle {
        id: underlay

        anchors.fill: parent
        color: "white"
        z: -2
    }

    ColorModel {
        id: colors
    }

    FontLoader {
        id: icons

        source: "qrc:/qt/qml/QShopper/fa-solid-900.otf"
    }

    Weekdays {
        id: weekdays

        x: 20
        y: 10
        width: 860
    }

    InputDelegate {
        id: editor

        x: 20
        y: 150
        width: 400
        height: Theme.pixels(9.27)
        font.family: icons.name
    }

    Pulley {
        id: pulley

        x: 450
        y: 140
        width: 430
        height: Theme.pixels(35)
        font.family: icons.name
    }

    Rectangle {
        id: drawer

        x: 20
        y: 400
        width: 860
        height: 470
        color: Material.shade(scene.Material.theme === Material.Dark ? "#424242" : "white",
                              Material.Shade800)

        Material.background: color

        Shop.Slider {
            id: slider

            x: 20
            y: 35
            width: 350
            value: .5
        }

        Shop.ComboBox {
            id: combo

            x: 20
            y: 140
            width: 350
            model: ["Weekly", "Market"]
            label: "Lists"
        }

        Shop.GroupBox {
            id: group

            x: 20
            y: 280
            width: 350
            height: 110
            title: "Actions"
        }
    }

    AboutDialog {
        id: about

        x: 460
        y: 395
        width: 420
        height: 480
        modal: false
        dim: false
    }

    Shop.Menu {
        id: menuProbe

        width: 350
        height: 400
        modal: false
        dim: false

        contentItem: Shop.ComboBox {
            model: ["Weekly", "Market"]
        }
    }

    TestCase {
        id: test

        property var heldButton: null

        function composite(ink, background) {
            return Qt.rgba(ink.r * ink.a + background.r * (1 - ink.a), ink.g * ink.a + background.g
                           * (1 - ink.a), ink.b * ink.a + background.b * (1 - ink.a), 1);
        }

        function contrast(front, back) {
            function luminance(c) {
                function linear(v) {
                    return v <= .04045 ? v / 12.92 : Math.pow((v + .055) / 1.055, 2.4);
                }
                return .2126 * linear(c.r) + .7152 * linear(c.g) + .0722 * linear(c.b);
            }
            const a = luminance(composite(front, back));
            const b = luminance(back);
            return (Math.max(a, b) + .05) / (Math.min(a, b) + .05);
        }

        function matches(a, b) {
            return Math.max(Math.abs(a.r - b.r), Math.abs(a.g - b.g), Math.abs(a.b - b.b)) < .025;
        }

        function palettes() {
            const rows = [];
            for (const theme of [Material.Light, Material.Dark]) {
                for (let index = 0; index < colors.count; ++index) {
                    const color = colors.get(index);
                    rows.push({
                                  tag: (theme === Material.Light ? "Light-" : "Dark-") + color.text,
                                  theme: theme,
                                  color: color.color
                              });
                }
            }
            if (Qt.platform.pluginName === "windows") {
                for (const dark of [false, true]) {
                    rows.push({
                                  tag: "System-" + (dark ? "Dark" : "Light"),
                                  theme: Material.System,
                                  scheme: dark ? Qt.ColorScheme.Dark : Qt.ColorScheme.Light,
                                  color: Material.Yellow
                              });
                }
            }
            return rows;
        }

        function init() {
            failOnWarning(/.*Binding loop detected.*/);
            Theme.scale = 2;
            tryCompare(icons, "status", FontLoader.Ready);
            uiSetup.resetDatabase();
        }

        function cleanup() {
            if (heldButton) {
                mouseRelease(heldButton, heldButton.width / 2, heldButton.height / 2);
                heldButton = null;
            }
            about.close();
            menuProbe.close();
            Qt.inputMethod.hide();
            Qt.styleHints.colorScheme = Qt.ColorScheme.Unknown;
        }

        function apply(data) {
            if (data.scheme !== undefined) {
                Qt.styleHints.colorScheme = data.scheme;
            }
            Theme.theme = data.theme;
            Theme.primary = data.color;
            Theme.accent = data.color;
            wait(40);
        }

        function glyph(item, minimum, label) {
            const visible = grabImage(scene);
            // Control-owned TextIcon geometry survives hiding; Layout captions
            // instead keep their allocation with zero opacity.
            const controlContent = item instanceof Shop.TextIcon;
            if (controlContent) {
                item.visible = false;
            } else {
                item.opacity = 0;
            }
            wait(20);
            const background = grabImage(scene);
            if (controlContent) {
                item.visible = true;
            } else {
                item.opacity = 1;
            }
            const inkWidth = Math.min(item.width, item.contentWidth);
            const inkHeight = Math.min(item.height, item.contentHeight);
            const inkX = item.horizontalAlignment === Text.AlignHCenter ? (item.width - inkWidth)
                                                                          / 2 : 0;
            const inkY = item.verticalAlignment === Text.AlignVCenter ? (item.height - inkHeight)
                                                                        / 2 : 0;
            const box = item.mapToItem(scene, Qt.rect(inkX, inkY, inkWidth, inkHeight));
            let cores = 0;
            let worst = 100;
            for (let y = Math.max(0, Math.ceil(box.y)); y < Math.min(visible.height, Math.floor(box.y
                                                                                                + box.height)); y
                 += 2) {
                for (let x = Math.max(0, Math.ceil(box.x)); x < Math.min(visible.width, Math.floor(
                                                                             box.x + box.width)); x
                     += 2) {
                    const behind = background.pixel(x, y);
                    if (matches(visible.pixel(x, y), composite(item.color, behind))) {
                        ++cores;
                        worst = Math.min(worst, contrast(item.color, behind));
                    }
                }
            }
            verify(cores >= 3, label + " rendered cores missing");
            if (worst < minimum) {
                visible.save("ux003-" + label + ".png");
            }
            verify(worst >= minimum, label + " " + worst.toFixed(3) + ":1; expected " + minimum
                   + ":1; ink=" + item.color);
        }

        function extremes(callback) {
            for (const color of ["white", "black"]) {
                underlay.color = color;
                wait(20);
                callback();
            }
        }

        function test_day_name_data() {
            return palettes();
        }

        function test_day_name(data) {
            apply(data);
            const today = weekdays.contentItem.children.find(child => child.index === 0);
            const name = today.contentItem.children[0];
            const fill = today.background.children[0];
            compare(fill.color, Theme.primaryColor(), "The vivid primary circle is unchanged");
            extremes(() => glyph(name, 4.5, "day-name"));
        }

        function test_pressed_editor_icon_data() {
            return palettes();
        }

        function test_pressed_editor_icon(data) {
            apply(data);
            const button = editor.contentItem.children.find(child => child instanceof Shop.Icon);
            extremes(() => {
                heldButton = button;
                mousePress(button, button.width / 2, button.height / 2);
                tryCompare(button, "pressed", true);
                glyph(button.contentItem, 3, "pressed-editor-icon");
                mouseRelease(button, button.width / 2, button.height / 2);
                heldButton = null;
                compare(button.pressed, false);
            });
        }

        function test_pulley_data() {
            return palettes();
        }

        function test_pulley(data) {
            apply(data);
            verify(pulley.height > pulley.treshold);
            wait(260);
            extremes(() => glyph(pulley.contentItem, 3, "armed-pulley"));
        }

        function test_focused_combo_data() {
            return palettes();
        }

        function test_focused_combo(data) {
            apply(data);
            combo.forceActiveFocus(Qt.TabFocusReason);
            tryCompare(combo, "activeFocus", true);
            const background = combo.background;
            const frame = grabImage(scene);
            const point = background.mapToItem(scene, background.width / 2, background.border.width
                                               / 2);
            const pixel = frame.pixel(Math.round(point.x), Math.round(point.y));
            verify(matches(pixel, composite(background.border.color, drawer.color)),
                   "Actual focused border must be painted");
            const value = contrast(background.border.color, drawer.color);
            verify(value >= 3, "Focused combo border " + value.toFixed(3)
                   + ":1; expected 3:1; ink=" + background.border.color + "; background="
                   + drawer.color + "; surface=" + combo.Controls.Material.backgroundColor);
        }

        function test_slider_thumb_data() {
            return palettes();
        }

        function test_slider_thumb(data) {
            apply(data);
            editor.contentItem.forceActiveFocus(Qt.MouseFocusReason);
            compare(slider.visualFocus, false);
            const handle = slider.handle;
            compare(handle.color, Theme.accentColor(), "The vivid slider fill is unchanged");
            const frame = grabImage(scene);
            // Rasterizers snap a subpixel contour differently. Inspect its
            // painted top arc, excluding the track below and outer background.
            const point = handle.mapToItem(scene, handle.width / 2, 0);
            const extent = Math.ceil(handle.width * .15);
            let cores = 0;
            for (let y = Math.floor(point.y) - 1; y <= Math.ceil(point.y + handle.border.width)
                 + 2; ++y) {
                for (let x = Math.round(point.x) - extent; x <= Math.round(point.x) + extent; ++x) {
                    if (contrast(frame.pixel(x, y), drawer.color) >= 3) {
                        ++cores;
                    }
                }
            }
            verify(cores >= 3,
                   "The actual thumb contour needs at least three readable core pixels; found "
                   + cores);
        }

        function test_drawer_surface_data() {
            return palettes();
        }

        function test_drawer_surface(data) {
            apply(data);
            menuProbe.open();
            tryCompare(menuProbe, "opened", true);
            compare(menuProbe.Controls.Material.backgroundColor, menuProbe.background.color,
                    "The actual drawer surface must propagate through Material");
            compare(menuProbe.contentItem.Controls.Material.backgroundColor,
                    menuProbe.background.color);
        }

        function test_about_tab_data() {
            return palettes();
        }

        function test_about_tab(data) {
            apply(data);
            about.open();
            tryCompare(about, "opened", true);
            for (const name of ["qtLicenseTab", "fontAwesomeLicenseTab"]) {
                const tab = findChild(about, name);
                mouseClick(tab, tab.width / 2, tab.height / 2);
                tryCompare(tab, "checked", true);
                wait(100);
                const caption = findChild(about, name === "qtLicenseTab" ? "qtTabCaption" :
                                                                           "fontAwesomeTabCaption");
                glyph(caption, 4.5, "selected-license-tab");
            }
        }

        name: "CustomColorRoles"
        when: windowShown
    }
}
