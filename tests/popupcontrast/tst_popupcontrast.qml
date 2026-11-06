pragma ComponentBehavior: Bound
import QShopper
import QShopper as Shop
import QtQuick
import QtQuick.Controls.Material
import QtQuick.Window
import QtTest

Item {
    id: scene

    width: 900
    height: 850
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
        anchors.fill: parent
        color: scene.Material.backgroundColor
    }

    ColorModel {
        id: colors
    }

    ColorComboBox {
        id: accent

        x: 30
        y: 30
        width: 240
        label: "Accent"
        colorFunction: Theme.colorAccent
    }

    ColorComboBox {
        id: primary

        x: 320
        y: 30
        width: 240
        label: "Primary"
    }

    Shop.ComboBox {
        id: lists

        x: 610
        y: 30
        width: 240
        label: "Lists"
        model: ["Market", "Weekly", "Other"]
    }

    TestCase {
        id: test

        function contrast(front, back) {
            function luminance(color) {
                function linear(channel) {
                    return channel <= 0.04045 ? channel / 12.92 : Math.pow((channel + 0.055) / 1.055,
                                                                           2.4);
                }
                return .2126 * linear(color.r) + .7152 * linear(color.g) + .0722 * linear(color.b);
            }
            const apparent = Qt.rgba(front.r * front.a + back.r * (1 - front.a), front.g * front.a
                                     + back.g * (1 - front.a), front.b * front.a + back.b * (1
                                                                                             - front.a),
                                     1);
            const a = luminance(apparent);
            const b = luminance(back);
            return (Math.max(a, b) + .05) / (Math.min(a, b) + .05);
        }

        function init() {
            failOnWarning(/.*/);
            verify(Theme.pixelsPerMillimeter > 0);
            // Larger native glyphs provide fully covered pixels despite antialiasing.
            Theme.scale = Qt.platform.pluginName === "windows" ? 2 : 1;
        }

        function cleanup() {
            for (const picker of [accent, primary, lists]) {
                picker.popup.close();
                tryCompare(picker.popup, "visible", false);
            }
            Qt.styleHints.colorScheme = Qt.ColorScheme.Unknown;
        }

        function test_selected_data() {
            const rows = [];
            const modes = [
                      {
                          name: "Light",
                          theme: Material.Light,
                          scheme: Qt.ColorScheme.Light
                      },
                      {
                          name: "Dark",
                          theme: Material.Dark,
                          scheme: Qt.ColorScheme.Dark
                      }
                  ];
            if (Qt.platform.pluginName === "windows") {
                modes.push({
                               name: "SystemLight",
                               theme: Material.System,
                               scheme: Qt.ColorScheme.Light
                           });
                modes.push({
                               name: "SystemDark",
                               theme: Material.System,
                               scheme: Qt.ColorScheme.Dark
                           });
            }
            for (const mode of modes) {
                for (const picker of [accent, primary, lists]) {
                    for (let index = 0; index < colors.count; ++index) {
                        if (mode.theme !== Material.System || [2, 9, 17].includes(index)) {
                            rows.push({
                                          tag: mode.name + "-" + picker.label + "-" + colors.get(
                                                   index).text,
                                          theme: mode.theme,
                                          scheme: mode.scheme,
                                          picker: picker,
                                          index: index
                                      });
                        }
                    }
                }
            }
            return rows;
        }

        function checkCaption(picker, row, tag) {
            const label = picker === lists ? row.contentItem : row.contentItem.children.find(child
                                                                                             => child instanceof Text);
            verify(label !== undefined);
            compare(row.font.pixelSize, picker.font.pixelSize, "Preserve caller font size");
            wait(100);
            label.opacity = 0;
            wait(20);
            const point = label.mapToItem(scene, label.width / 2, label.height / 2);
            const frame = grabImage(scene);
            verify(point.x >= 0 && point.y >= 0 && point.x < frame.width && point.y < frame.height);
            const background = frame.pixel(Math.round(point.x), Math.round(point.y));
            label.opacity = 1;
            wait(20);
            const ratio = contrast(label.color, background);
            verify(ratio >= 4.5, tag + ": " + ratio.toFixed(3) + ":1; " + label.color + " on "
                   + background);
            verify(row.font.bold, "Current entry must retain a non-color selection cue");
            const actual = grabImage(scene);
            const origin = label.mapToItem(scene, 0, 0);
            const ink = Qt.rgba(label.color.r * label.color.a + background.r * (1 - label.color.a),
                                label.color.g * label.color.a + background.g * (1 - label.color.a),
                                label.color.b * label.color.a + background.b * (1 - label.color.a),
                                1);
            let glyphs = 0;
            for (let y = Math.ceil(origin.y); y < Math.min(actual.height, Math.floor(origin.y
                                                                                     + label.height)); ++y) {
                for (let x = Math.ceil(origin.x); x < Math.min(actual.width, Math.floor(origin.x
                                                                                        + label.width)); ++x) {
                    const pixel = actual.pixel(x, y);
                    if (Math.abs(pixel.r - ink.r) < .04 && Math.abs(pixel.g - ink.g) < .04
                            && Math.abs(pixel.b - ink.b) < .04) {
                        ++glyphs;
                    }
                }
            }
            if (glyphs < 4) {
                actual.save("ui026-caption-failure.png");
            }
            verify(glyphs >= 4, tag + ": actual caption cores missing; size="
                   + label.font.pixelSize + ", foreground=" + label.color + ", background="
                   + background);
        }

        function test_selected(data) {
            Qt.styleHints.colorScheme = data.scheme;
            Theme.theme = data.theme;
            const picker = data.picker;
            const color = colors.get(data.index).color;
            Theme.primary = color;
            Theme.accent = color;
            tryCompare(scene.Material, "theme", data.scheme === Qt.ColorScheme.Dark ? Material.Dark :
                                                                                      Material.Light);
            picker.currentIndex = picker === lists ? 1 : data.index;
            picker.popup.open();
            tryCompare(picker.popup, "opened", true);
            const view = picker.popup.contentItem;
            view.positionViewAtIndex(picker.currentIndex, ListView.Center);
            view.forceLayout();
            tryVerify(() => view.itemAtIndex(picker.currentIndex) !== null);
            let row = view.itemAtIndex(picker.currentIndex);
            checkCaption(picker, row, data.tag + " highlighted");
            // Keyboard navigation can highlight another entry while current stays selected.
            picker.forceActiveFocus();
            keyClick(picker.currentIndex === picker.count - 1 ? Qt.Key_Up : Qt.Key_Down);
            tryVerify(() => picker.highlightedIndex !== picker.currentIndex);
            row = view.itemAtIndex(picker.currentIndex);
            verify(row !== null);
            checkCaption(picker, row, data.tag + " current without highlight");
            const next = (picker.currentIndex + 1) % picker.count;
            picker.currentIndex = next;
            view.positionViewAtIndex(next, ListView.Center);
            view.forceLayout();
            tryVerify(() => view.itemAtIndex(next) !== null);
            checkCaption(picker, view.itemAtIndex(next), data.tag + " changed selection");
            Theme.accent = colors.get((data.index + 7) % colors.count).color;
            checkCaption(picker, view.itemAtIndex(next), data.tag + " live palette change");
            if (picker !== lists) {
                compare(picker.contentItem.swatchColor, picker.colorFunction(picker.currentValue),
                        "Keep vivid swatches");
            }
        }

        name: "PopupContrast"
        when: windowShown
    }
}
