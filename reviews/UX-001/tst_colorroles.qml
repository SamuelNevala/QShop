// Review probe, run explicitly; it records current behavior without changing the app.
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

    readonly property real screenDensity: Screen.pixelDensity
    readonly property string screenName: Screen.name

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

    // main.qml sets these on its Window, including the popup overlay's parent.
    Binding {
        target: scene.Window.window ? scene.Window.window.Material : null
        property: "theme"
        value: Theme.theme
    }

    Binding {
        target: scene.Window.window ? scene.Window.window.Material : null
        property: "primary"
        value: Theme.primaryColor()
    }

    Binding {
        target: scene.Window.window ? scene.Window.window.Material : null
        property: "accent"
        value: Theme.accentColor()
    }

    BackgroundImage {
        id: artwork

        anchors.fill: parent
        source: "qrc:/qt/qml/QShopper/backgrounds/03-bakery.jpg"
        visible: true
        opacity: 1
    }

    Rectangle {
        anchors.fill: parent
        color: scene.Material.backgroundColor
        opacity: 0.8
    }

    Shop.Menu {
        id: drawer

        Material.theme: Theme.theme
        Material.primary: Theme.primaryColor()
        Material.accent: Theme.accentColor()
    }

    Rectangle {
        x: 30
        y: 125
        width: 840
        height: 285
        color: drawer.background.color
    }

    Weekdays {
        id: weekdays

        x: 40
        y: 40
        width: 820
    }

    FontLoader {
        id: icons

        source: "qrc:/qt/qml/QShopper/fa-solid-900.ttf"
    }

    IconButton {
        id: selected

        x: 60
        y: 180
        highlighted: true
        text: "Selected"
        icon.name: "\uf186"
        font.family: icons.name
    }

    Controls.RoundButton {
        id: stock

        property int primaryEnum: Theme.primary
        property int accentEnum: Theme.accent

        x: 195
        y: 180
        highlighted: true
        text: "Qt enum"
        Material.primary: primaryEnum
        Material.accent: accentEnum
    }

    ColorComboBox {
        id: accentPicker

        x: 380
        y: 180
        width: 220
        label: "Accent"
        colorFunction: Theme.colorAccent
    }

    ColorComboBox {
        id: primaryPicker

        x: 620
        y: 180
        width: 220
        label: "Primary"
    }

    Shop.Slider {
        id: slider

        x: 60
        y: 320
        width: 720
        value: 0.6
    }

    UndoBar {
        id: undo

        x: 40
        y: 520
        width: 820
        message: "Milk removed"
        font.family: icons.name
    }

    TestCase {
        function init() {
            verify(scene.screenDensity > 0 && isFinite(scene.screenDensity),
                   "Invalid screen density on " + scene.screenName
                   + "; use a connected native display or the documented offscreen palette probe.");
        }

        function pixel(frame, x, y) {
            verify(x >= 0 && y >= 0 && x < frame.width && y < frame.height, "Sample " + x + "," + y
                   + " outside " + frame.width + "x" + frame.height);
            const color = frame.pixel(x, y);
            verify(color !== undefined, "Unavailable pixel " + x + "," + y);
            return color;
        }

        function composite(front, back) {
            return Qt.rgba(front.r * front.a + back.r * (1 - front.a), front.g * front.a + back.g * (
                               1 - front.a), front.b * front.a + back.b * (1 - front.a), 1);
        }

        function luminance(color) {
            function linear(value) {
                return value <= 0.04045 ? value / 12.92 : Math.pow((value + 0.055) / 1.055, 2.4);
            }
            return 0.2126 * linear(color.r) + 0.7152 * linear(color.g) + 0.0722 * linear(color.b);
        }

        function contrast(front, back) {
            const a = luminance(composite(front, back));
            const b = luminance(back);
            return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
        }

        function sample(item, x, y) {
            const point = item.mapToItem(scene, x, y);
            return pixel(grabImage(scene), Math.round(point.x), Math.round(point.y));
        }

        function pick(primary, accent) {
            Theme.primary = primary;
            Theme.accent = accent;
            // Review changes are programmatic; real picker activation sets these first.
            primaryPicker.currentIndex = primaryPicker.indexOfValue(primary);
            accentPicker.currentIndex = accentPicker.indexOfValue(accent);
        }

        function popupContrast(picker, tag) {
            picker.popup.open();
            tryCompare(picker.popup, "opened", true);
            const list = picker.popup.contentItem;
            list.positionViewAtIndex(picker.currentIndex, ListView.Center);
            list.forceLayout();
            tryVerify(() => list.itemAtIndex(picker.currentIndex) !== null);
            const row = list.itemAtIndex(picker.currentIndex);
            const label = row.contentItem.children.find(child => child instanceof Text);
            verify(label !== undefined);
            const foreground = label.color;
            label.opacity = 0;
            waitForRendering(scene);
            const point = label.mapToItem(scene, label.width / 2, label.height / 2);
            const background = pixel(grabImage(scene), Math.round(point.x), Math.round(point.y));
            label.opacity = 1;
            waitForRendering(scene);
            grabImage(scene).save("ux001-popup-" + tag + ".png");
            picker.popup.close();
            tryCompare(picker.popup, "visible", false);
            return {
                foreground: foreground.toString(),
                background: background.toString(),
                ratio: contrast(foreground, background)
            };
        }

        function record(mode, name) {
            const today = weekdays.contentItem.children.find(child => child.index === 0);
            verify(today !== undefined);
            const circle = today.background.children[0];
            const number = today.contentItem.children[1];
            const glyph = selected.contentItem.children.find(child => child instanceof TextIcon);
            const caption = undo.contentItem.children.find(child
                                                           => child instanceof Controls.Label);
            const fill = findChild(undo, "undoRemainingFill");
            const fillPixel = sample(fill, fill.width * 0.25, fill.height * 0.15);
            return {
                mode: mode,
                palette: name,
                resolvedTheme: scene.Material.theme,
                primary: scene.Material.primary.toString(),
                accent: scene.Material.accent.toString(),
                qtPrimary: stock.Material.primary.toString(),
                qtAccent: stock.Material.accent.toString(),
                drawerBackground: drawer.background.color.toString(),
                drawerTheme: drawer.Material.theme,
                currentDayForeground: number.color.toString(),
                currentDayContrast: contrast(number.color, circle.color),
                currentDayNameContrast: contrast(today.contentItem.children[0].color, sample(
                                                     weekdays, weekdays.width - 3, 2)),
                qtCurrentDayNameContrast: contrast(stock.Material.primary, sample(weekdays,
                                                                                  weekdays.width - 3,
                                                                                  2)),
                qtCurrentDayNumberContrast: contrast(number.color, stock.Material.primary),
                iconForeground: glyph.color.toString(),
                iconContrast: contrast(glyph.color, selected.background.color),
                stockIconContrast: contrast(stock.Material.primaryHighlightedTextColor,
                                            stock.background.color),
                undoForeground: caption.color.toString(),
                undoFillPixel: fillPixel.toString(),
                undoFillContrast: contrast(caption.color, fillPixel),
                accentOnDrawerContrast: contrast(scene.Material.accentColor,
                                                 drawer.background.color),
                primarySwatch: primaryPicker.contentItem.swatchColor.toString(),
                accentSwatch: accentPicker.contentItem.swatchColor.toString()
            };
        }

        function test_review_data() {
            return [
                        {
                            tag: "Light",
                            theme: Material.Light,
                            system: Qt.ColorScheme.Light
                        },
                        {
                            tag: "Dark",
                            theme: Material.Dark,
                            system: Qt.ColorScheme.Dark
                        },
                        {
                            tag: "SystemLight",
                            theme: Material.System,
                            system: Qt.ColorScheme.Light
                        },
                        {
                            tag: "SystemDark",
                            theme: Material.System,
                            system: Qt.ColorScheme.Dark
                        }
                    ];
        }

        function test_review(data) {
            failOnWarning(/.*/);
            Qt.styleHints.colorScheme = data.system;
            Theme.scale = 1;
            Theme.theme = data.theme;
            tryCompare(scene.Material, "theme", data.system === Qt.ColorScheme.Dark ? Material.Dark :
                                                                                      Material.Light);
            tryCompare(artwork, "status", Image.Ready);
            tryCompare(icons, "status", FontLoader.Ready);
            undo.open();
            tryCompare(undo, "opened", true);
            findChild(undo, "undoExpiry").stop();
            findChild(undo, "undoCountdown").value = 1;
            const rows = [];
            for (let index = 0; index < primaryPicker.model.count; ++index) {
                const entry = primaryPicker.model.get(index);
                pick(entry.color, entry.color);
                waitForRendering(scene);
                const result = record(data.tag, entry.text);
                compare(result.primary, result.primarySwatch);
                compare(result.accent, result.accentSwatch);
                rows.push(result);
            }
            const pairs = [
                      {
                          tag: "defaults",
                          primary: Material.Indigo,
                          accent: Material.Green
                      },
                      {
                          tag: "orange-purple",
                          primary: Material.DeepOrange,
                          accent: Material.Purple
                      },
                      {
                          tag: "yellow-lime",
                          primary: Material.Yellow,
                          accent: Material.Lime
                      },
                      {
                          tag: "brown-grey",
                          primary: Material.Brown,
                          accent: Material.Grey
                      }
                  ];
            for (const pair of pairs) {
                pick(pair.primary, pair.accent);
                waitForRendering(scene);
                const result = record(data.tag, pair.tag);
                result.selectedPopup = popupContrast(accentPicker, data.tag + "-" + pair.tag);
                rows.push(result);
                grabImage(scene).save("ux001-" + data.tag + "-" + pair.tag + ".png");
            }
            console.log("UX001_DATA " + JSON.stringify(rows));
            undo.close();
        }

        function test_underlay_data() {
            const files = ["01-phone-and-pantry", "02-produce", "03-bakery", "04-dairy",
                           "05-bulk-goods", "06-market-hall", "07-checkout", "08-qshopper",
                           "09-stocktaking", "10-evening-produce"];
            const rows = [];
            for (const theme of [Material.Light, Material.Dark]) {
                for (const file of files) {
                    rows.push({
                                  tag: (theme === Material.Light ? "Light-" : "Dark-") + file,
                                  theme: theme,
                                  file: file
                              });
                }
            }
            return rows;
        }

        function test_underlay(data) {
            failOnWarning(/.*/);
            Theme.theme = data.theme;
            pick(Material.Indigo, Material.Green);
            artwork.source = "qrc:/qt/qml/QShopper/backgrounds/" + data.file + ".jpg";
            tryCompare(artwork, "status", Image.Ready);
            undo.open();
            tryCompare(undo, "opened", true);
            findChild(undo, "undoExpiry").stop();
            const progress = findChild(undo, "undoCountdown");
            const label = undo.contentItem.children.find(child => child instanceof Controls.Label);
            const point = label.mapToItem(scene, 0, label.height / 2);
            const ratios = [];
            for (const position of [1, 0.5, 0]) {
                progress.value = position;
                label.opacity = 0;
                waitForRendering(scene);
                const frame = grabImage(scene);
                const samples = [];
                for (let index = 1; index < 10; ++index) {
                    const background = pixel(frame, Math.round(point.x + label.width * index / 10),
                                             Math.round(point.y));
                    samples.push(contrast(label.color, background));
                }
                ratios.push({
                                fill: position,
                                min: Math.min(...samples),
                                max: Math.max(...samples)
                            });
                label.opacity = 1;
                waitForRendering(scene);
                grabImage(scene).save("ux001-underlay-" + data.tag + "-" + position + ".png");
            }
            console.log("UX001_UNDERLAY " + JSON.stringify({
                                                               tag: data.tag,
                                                               ratios: ratios
                                                           }));
            undo.close();
        }

        name: "ColorRoleReview"
        when: windowShown
    }
}
