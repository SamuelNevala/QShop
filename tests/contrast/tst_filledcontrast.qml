pragma ComponentBehavior: Bound
import QShopper
import QtQuick
import QtQuick.Controls.Material as Controls
import QtQuick.Controls.Material
import QtTest

Item {
    id: scene

    width: 800
    height: 720
    Material.theme: Theme.theme
    Material.primary: Theme.primaryColor()
    Material.accent: Theme.accentColor()

    Binding {
        target: Theme
        property: "parent"
        value: scene
    }

    BackgroundImage {
        id: artwork

        anchors.fill: parent
        source: "qrc:/qt/qml/QShopper/backgrounds/08-qshopper.jpg"
        opacity: 1
        visible: true
    }

    Rectangle {
        anchors.fill: parent
        color: scene.Material.backgroundColor
        opacity: 0.8
    }

    Weekdays {
        id: weekdays

        x: 20
        y: 20
        width: 760
    }

    FontLoader {
        id: icons

        source: "qrc:/qt/qml/QShopper/fa-solid-900.ttf"
    }

    IconButton {
        id: selected

        x: 50
        y: 180
        width: Theme.pixels(18)
        text: "Selected"
        highlighted: true
        icon.name: "\uf186"
        font.family: icons.name
    }

    ColorModel {
        id: colors
    }

    TextItem {
        id: normalText

        visible: false
    }

    UndoBar {
        id: undo

        x: 20
        y: 420
        width: 760
        message: "Milk removed"
        font.family: icons.name
    }

    TestCase {
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

        function readable(front, back, minimum, label) {
            const ratio = contrast(front, back);
            verify(ratio >= minimum, label + ": " + ratio.toFixed(3) + ":1, expected " + minimum
                   + ":1; foreground " + front + ", background " + back);
        }

        function solidGlyph(frame, item, front, back) {
            const target = composite(front, back);
            const origin = item.mapToItem(scene, 0, 0);
            let count = 0;
            for (let y = Math.max(0, Math.ceil(origin.y)); y < Math.min(frame.height, Math.floor(
                                                                            origin.y
                                                                            + item.height)); ++y) {
                for (let x = Math.max(0, Math.ceil(origin.x)); x < Math.min(frame.width, Math.floor(
                                                                                origin.x
                                                                                + item.width)); ++x) {
                    const pixel = frame.pixel(x, y);
                    if (Math.abs(pixel.r - target.r) < 0.025 && Math.abs(pixel.g - target.g) < 0.025
                            && Math.abs(pixel.b - target.b) < 0.025) {
                        ++count;
                    }
                }
            }
            verify(count >= 4, "Actual foreground pixels missing for " + item.text);
        }

        function palettes() {
            const cases = [];
            for (const theme of [Material.Light, Material.Dark]) {
                for (let index = 0; index < colors.count; ++index) {
                    const entry = colors.get(index);
                    cases.push({
                                   tag: (theme === Material.Light ? "Light-" : "Dark-") + entry.text,
                                   theme: theme,
                                   color: entry.color
                               });
                }
            }
            return cases;
        }

        function apply(data) {
            Theme.theme = data.theme;
            Theme.primary = data.color;
            Theme.accent = data.color;
            selected.display = Controls.AbstractButton.TextUnderIcon;
            selected.flat = false;
            selected.enabled = true;
            wait(30);
        }

        function init() {
            failOnWarning(/.*/);
            verify(Theme.pixelsPerMillimeter > 0, "A valid display density is required");
            Theme.scale = 2;
            tryCompare(icons, "status", FontLoader.Ready);
            tryCompare(artwork, "status", Image.Ready);
        }

        function cleanup() {
            undo.close();
            Theme.scale = 1;
        }

        function test_day_data() {
            return palettes();
        }

        function test_day(data) {
            apply(data);
            const today = weekdays.contentItem.children.find(child => child.index === 0);
            verify(today !== undefined);
            const number = today.contentItem.children[1];
            const circle = today.background.children[0];
            readable(number.color, circle.color, 4.5, "Current day number");
            compare(circle.color, Theme.primaryColor(), "Keep the selected primary fill");
            // UI-029 may adjust the name's ink; the selected primary fill stays vivid.
            solidGlyph(grabImage(scene), number, number.color, circle.color);
        }

        function test_selected_button_data() {
            return palettes();
        }

        function test_selected_button(data) {
            apply(data);
            const icon = selected.contentItem.children.find(child => child instanceof TextIcon);
            const caption = selected.contentItem.children.find(child => child instanceof Text && !(
                                                                            child instanceof TextIcon));
            for (const mode of [Controls.AbstractButton.TextUnderIcon,
                                Controls.AbstractButton.IconOnly,
                                Controls.AbstractButton.TextBesideIcon,
                                Controls.AbstractButton.TextOnly]) {
                selected.display = mode;
                wait(30);
                compare(selected.background.color, Theme.accentColor(),
                        "Keep the vivid accent fill");
                if (icon.visible) {
                    readable(icon.color, selected.background.color, 3, "Selected icon");
                    solidGlyph(grabImage(scene), icon, icon.color, selected.background.color);
                }
                if (caption.visible && mode !== Controls.AbstractButton.TextUnderIcon) {
                    readable(caption.color, selected.background.color, 4.5, "Caption inside fill");
                }
                if (mode === Controls.AbstractButton.TextUnderIcon) {
                    compare(caption.color, selected.Material.foreground,
                            "Caption outside the circle keeps normal theme text");
                }
            }
        }

        function test_undo_data() {
            return palettes();
        }

        function test_undo(data) {
            apply(data);
            undo.open();
            tryCompare(undo, "opened", true);
            findChild(undo, "undoExpiry").stop();
            const progress = findChild(undo, "undoCountdown");
            progress.value = 1;
            wait(30);
            const label = undo.contentItem.children.find(child => child instanceof Controls.Label);
            const icon = undo.contentItem.children.find(child => child instanceof TextIcon);
            const fill = findChild(undo, "undoRemainingFill");
            const point = fill.mapToItem(scene, fill.width * 0.15, fill.height * 0.88);
            const frame = grabImage(scene);
            const background = frame.pixel(Math.round(point.x), Math.round(point.y));
            compare(fill.color.a, 1, "Fill remains opaque");
            compare(label.color, normalText.color, "Preserve UI-024 foreground policy");
            compare(icon.color, label.color);
            readable(label.color, background, 4.5, "Undo text on actual fill");
            readable(icon.color, background, 3, "Undo icon on actual fill");
            solidGlyph(frame, label, label.color, background);
            solidGlyph(frame, icon, icon.color, background);
            frame.save("ui025-undo-" + data.tag + ".png");
        }

        function test_underlays_data() {
            const files = ["01-phone-and-pantry", "02-produce", "03-bakery", "04-dairy",
                           "05-bulk-goods", "06-market-hall", "07-checkout", "08-qshopper",
                           "09-stocktaking", "10-evening-produce"];
            const cases = [];
            for (const theme of [Material.Light, Material.Dark]) {
                for (const file of files) {
                    cases.push({
                                   tag: (theme === Material.Light ? "Light-" : "Dark-") + file,
                                   theme: theme,
                                   file: file
                               });
                }
            }
            return cases;
        }

        function test_underlays(data) {
            apply({
                      theme: data.theme,
                      color: Material.Green
                  });
            artwork.source = "qrc:/qt/qml/QShopper/backgrounds/" + data.file + ".jpg";
            tryCompare(artwork, "status", Image.Ready);
            undo.open();
            tryCompare(undo, "opened", true);
            findChild(undo, "undoExpiry").stop();
            const progress = findChild(undo, "undoCountdown");
            const label = undo.contentItem.children.find(child => child instanceof Controls.Label);
            const point = label.mapToItem(scene, 0, label.height / 2);
            for (const value of [1, 0.5, 0]) {
                progress.value = value;
                label.opacity = 0;
                wait(30);
                const frame = grabImage(scene);
                for (let index = 1; index < 10; ++index) {
                    const background = frame.pixel(Math.round(point.x + label.width * index / 10),
                                                   Math.round(point.y));
                    readable(label.color, background, 4.5, "Undo message area at fill " + value);
                }
                label.opacity = 1;
            }
        }

        name: "FilledContrast"
        when: windowShown
    }
}
