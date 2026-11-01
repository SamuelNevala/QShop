import QShopper
import QtQuick
import QtQuick.Controls.Material
import QtTest

Item {
    id: scene

    width: 1000
    height: 720

    Binding {
        target: Theme
        property: "parent"
        value: scene
    }

    Component {
        id: rowComponent

        TextDelegate {
            height: Theme.pixels(9.27)
            dragParent: scene
        }
    }

    TestCase {
        readonly property bool hasTextFonts: Qt.fontFamilies().some(family => !family.startsWith(
                                                                                  "Font Awesome"))

        function init() {
            Theme.scale = 1;
            failOnWarning(/.*Binding loop detected.*/);
        }

        function cleanup() {
            Theme.scale = 1;
        }

        function test_entries_data() {
            const cases = [];
            for (const scale of [1, 2]) {
                for (const width of [55, 76.6, 90]) {
                    for (const entry of [
                             {
                                 name: "short",
                                 text: "Milk"
                             },
                             {
                                 name: "words",
                                 text: "Whole grain bread with sunflower seeds and no added sugar"
                             },
                             {
                                 name: "long",
                                 text: "Shopping ingredients for a large family dinner including potatoes carrots onions mushrooms tomatoes pasta and cheese"
                             },
                             {
                                 name: "unbroken",
                                 text: "W".repeat(100)
                             },
                             {
                                 name: "overflow",
                                 text: "Very long shopping entry ".repeat(40)
                             }
                         ]) {
                        cases.push({
                                       tag: entry.name + "_" + width + "mm_" + scale,
                                       entry: entry,
                                       width: width,
                                       scale: scale
                                   });
                    }
                }
            }
            return cases;
        }

        function test_entries(data) {
            Theme.scale = data.scale;
            const row = createTemporaryObject(rowComponent, scene, {
                                                  width: Theme.pixels(data.width),
                                                  name: data.entry.text
                                              });
            verify(row !== null);
            waitForRendering(row);
            const label = row.contentItem;
            verify(label.lineCount > 0 && label.lineCount <= 3, "Rendered " + label.lineCount
                   + " lines for " + data.entry.name);
            verify(label.contentWidth <= label.width + 1);
            verify(label.contentHeight <= label.height + 1);
            fuzzyCompare(row.height, Theme.pixels(9.27), 0.001);
            compare(label.text, data.entry.text);
            if (data.entry.name === "short") {
                compare(label.lineCount, 1);
                verify(!label.truncated);
                // Offscreen has only a dummy font or the app's icon font.
                // Check typography with actual fonts in the native Windows run.
                if (hasTextFonts) {
                    verify(label.fontInfo.pixelSize >= Math.round(Theme.pixels(7)) - 1);
                }
            }
            if (data.entry.name === "words" && data.width >= 76.6 && hasTextFonts) {
                verify(!label.truncated, "An ordinary long name must retain all its words");
                verify(label.fontInfo.pixelSize < Math.round(Theme.pixels(7)));
            }
            if (data.entry.name === "overflow") {
                verify(label.truncated, "Oversized input must signal omitted text");
            }
            row.checked = true;
            waitForRendering(row);
            compare(label.font.strikeout, true);
            verify(label.lineCount <= 3);
            // Reusing a row after a long name must restore large short text.
            row.name = "Milk";
            tryCompare(label, "lineCount", 1);
            verify(!label.truncated);
            if (hasTextFonts) {
                verify(label.fontInfo.pixelSize >= Math.round(Theme.pixels(7)) - 1);
            }
        }

        function test_resize_existing_row() {
            Theme.scale = 2;
            const row = createTemporaryObject(rowComponent, scene, {
                                                  width: Theme.pixels(55),
                                                  name: "W".repeat(60)
                                              });
            verify(row !== null);
            waitForRendering(row);
            const label = row.contentItem;
            verify(label.lineCount <= 3);
            const smallFont = label.fontInfo.pixelSize;
            row.width = Theme.pixels(90);
            waitForRendering(row);
            verify(label.lineCount <= 3);
            row.width = Theme.pixels(55);
            waitForRendering(row);
            compare(label.fontInfo.pixelSize, smallFont);
            verify(label.lineCount <= 3);
        }

        name: "TextFitting"
        when: windowShown
    }
}
