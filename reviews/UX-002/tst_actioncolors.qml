// Explicit review probe: production components; measurements are not pass/fail accessibility certification.
pragma ComponentBehavior: Bound
import QShopper
import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Window
import QtTest

Item {
    id: scene

    width: 1120
    height: 1100
    Material.theme: Theme.theme
    Material.primary: Theme.primaryColor()
    Material.accent: Theme.accentColor()

    Binding {
        target: Theme
        property: "parent"
        value: scene
    }

    FontLoader {
        id: icons

        source: "qrc:/qt/qml/QShopper/fa-solid-900.ttf"
    }

    BackgroundImage {
        id: artwork

        anchors.fill: parent
        visible: true
        opacity: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 8

        Text {
            id: heading

            Layout.fillWidth: true
            color: scene.Material.primaryTextColor
            font.pixelSize: 24
            text: "QShopper action-color review"
        }

        Repeater {
            id: rows

            model: 8

            delegate: ColumnLayout {
                id: band

                required property int index
                readonly property bool editing: index >= 4
                readonly property bool checked: (index % 4) >= 2
                readonly property int direction: index % 2 === 0 ? 1 : -1
                property alias row: row

                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    color: scene.Material.primaryTextColor
                    font.pixelSize: 17
                    text: (band.editing ? "Edit" : "Shop") + " / " + (band.checked ? "checked" :
                                                                                     "unchecked")
                          + " / " + (band.direction > 0 ? "right" : "left") + " swipe"
                }

                Item {
                    id: viewport

                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.pixels(9.27)
                    clip: true

                    TextDelegate {
                        id: row

                        width: viewport.width
                        height: viewport.height
                        checked: band.checked
                        editMode: band.editing
                        name: "Milk"
                        index: band.index
                        dragParent: viewport
                        font.family: icons.name
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    TestCase {
        function luminance(color) {
            function linear(channel) {
                return channel <= .04045 ? channel / 12.92 : Math.pow((channel + .055) / 1.055,
                                                                      2.4);

            }
            return .2126 * linear(color.r) + .7152 * linear(color.g) + .0722 * linear(color.b);
        }

        function contrast(a, b) {
            const front = luminance(a);
            const back = luminance(b);
            return (Math.max(front, back) + .05) / (Math.min(front, back) + .05);
        }

        function loader(band) {
            return band.row.background.children.filter(child
                                                       => child instanceof IconChoser)[band.direction
                                                                                       > 0 ? 0 : 1];
        }

        function test_review_data() {
            const cases = [];
            for (const theme of [Material.Light, Material.Dark]) {
                for (const file of ["03-bakery", "10-evening-produce"]) {
                    cases.push({
                                   tag: (theme === Material.Light ? "Light-" : "Dark-") + file,
                                   theme: theme,
                                   file: file
                               });
                }
            }
            return cases;
        }

        function test_review(data) {
            failOnWarning(/.*/);
            verify(Theme.pixelsPerMillimeter > 0,
                   "A connected native display with valid density is required");
            Theme.scale = 2;
            Theme.theme = data.theme;
            Theme.primary = Material.Indigo;
            Theme.accent = Material.Green;
            artwork.source = "qrc:/qt/qml/QShopper/backgrounds/" + data.file + ".jpg";
            tryCompare(artwork, "status", Image.Ready);
            tryCompare(icons, "status", FontLoader.Ready);
            heading.text = data.tag + " / actual production swipe cues";
            for (let i = 0; i < rows.count; ++i) {
                const band = rows.itemAt(i);
                band.row.x = 0;
            }
            wait(60);
            grabImage(scene).save("ux002-" + data.tag + "-idle.png");
            for (let i = 0; i < rows.count; ++i) {
                const band = rows.itemAt(i);
                tryVerify(() => loader(band).item !== null);
                band.row.x = band.direction * band.row.width * .55;
            }
            wait(350);
            grabImage(scene).save("ux002-" + data.tag + "-moving.png");
            wait(650);
            const complete = grabImage(scene);
            complete.save("ux002-" + data.tag + "-settled.png");
            for (let i = 0; i < rows.count; ++i) {
                loader(rows.itemAt(i)).item.arrow.visible = false;
            }
            wait(30);
            const glyphs = grabImage(scene);
            for (let i = 0; i < rows.count; ++i) {
                loader(rows.itemAt(i)).visible = false;
            }
            wait(30);
            const background = grabImage(scene);
            const records = [];
            for (let i = 0; i < rows.count; ++i) {
                const band = rows.itemAt(i);
                const glyph = loader(band).item;
                const origin = glyph.mapToItem(scene, Qt.rect(0, 0, glyph.width, glyph.height));
                verify(origin.x >= 0 && origin.y >= 0 && origin.x + origin.width <= scene.width
                       && origin.y + origin.height <= scene.height);
                const ratios = [];
                for (let y = Math.ceil(origin.y); y < Math.floor(origin.y + glyph.height); ++y) {
                    for (let x = Math.ceil(origin.x); x < Math.floor(origin.x + glyph.width); ++x) {
                        const pixel = glyphs.pixel(x, y);
                        if (Math.abs(pixel.r - glyph.color.r) < .015 && Math.abs(pixel.g
                                                                                 - glyph.color.g)
                                < .015 && Math.abs(pixel.b - glyph.color.b) < .015) {
                            ratios.push(contrast(glyph.color, background.pixel(x, y)));
                        }
                    }
                }
                verify(ratios.length >= 10, "No actual opaque icon cores for row " + i);
                ratios.sort((a, b) => a - b);
                records.push({
                                 mode: band.editing ? "edit" : "shop",
                                 checked: band.checked,
                                 direction: band.direction > 0 ? "right" : "left",
                                 action: band.editing && band.direction > 0 ? "delete" :
                                                                              band.checked
                                                                              ? "uncheck" : "check",
                                 glyphCodePoint: glyph.text.charCodeAt(0).toString(16),
                                 foreground: glyph.color.toString(),
                                 rawRatio: glyph.ratio,
                                 itemOpacity: glyph.opacity,
                                 corePixels: ratios.length,
                                 minContrast: ratios[0],
                                 medianContrast: ratios[Math.floor(ratios.length / 2)],
                                 maxContrast: ratios[ratios.length - 1],
                                 iconBox: [origin.x, origin.y, glyph.width, glyph.height],
                                 arrowOnscreenAtRest: glyph.arrow.y + glyph.arrow.height > 0
                                                      && glyph.arrow.y < glyph.height
                             });
                loader(band).visible = true;
                glyph.arrow.visible = true;
            }
            console.log("UX002_DATA " + JSON.stringify({
                                                           tag: data.tag,
                                                           records: records
                                                       }));
        }

        name: "ActionColorReview"
        when: windowShown
    }
}
