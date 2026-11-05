pragma ComponentBehavior: Bound
import QShopper
import QtQuick
import QtQuick.Controls.Material
import QtTest

Item {
    id: scene

    width: 432
    height: 918

    Binding {
        target: Theme
        property: "parent"
        value: scene
    }

    Component {
        id: slideshowComponent

        Background {
            anchors.fill: parent
        }
    }

    Item {
        id: preview

        anchors.fill: parent

        BackgroundImage {
            id: artwork

            anchors.fill: parent
            opacity: 1
            visible: true
        }

        TextDelegate {
            id: shortRow

            name: "Milk"
            width: parent.width
            height: Theme.pixels(9.27)
            y: Theme.pixels(25)
            dragParent: preview
        }

        TextDelegate {
            id: longRow

            name: "Whole grain bread with sunflower seeds and no added sugar"
            checked: true
            width: parent.width
            height: Theme.pixels(9.27)
            y: shortRow.y + shortRow.height
            dragParent: preview
        }
    }

    TestCase {
        readonly property var files: ["01-phone-and-pantry", "02-produce", "03-bakery", "04-dairy",
            "05-bulk-goods", "06-market-hall", "07-checkout", "08-qshopper", "09-stocktaking",
            "10-evening-produce"]

        function init() {
            failOnWarning(/.*/);
            Theme.scale = 1;
            Theme.theme = Material.Light;
            scene.width = 432;
            scene.height = 918;
        }

        function test_slideshow_sources() {
            const slideshow = createTemporaryObject(slideshowComponent, scene);
            verify(slideshow !== null);
            const catalog = slideshow.resources[0];
            const clock = slideshow.resources[1];
            clock.stop();
            compare(catalog.count, 10);
            compare(clock.interval, 7000);
            const visited = [];
            for (let index = 0; index < files.length; ++index) {
                const image = catalog.get(index);
                tryCompare(image, "status", Image.Ready);
                verify(image.source.toString().endsWith("/backgrounds/" + files[index] + ".jpg"));
                compare(image.sourceSize.width, 1080);
                compare(image.sourceSize.height, 1920);
                tryCompare(slideshow, "busy", false);
                compare(slideshow.currentItem, image);
                visited.push(image.source.toString());
                clock.triggered();
            }
            compare(new Set(visited).size, 10);
            // The original slideshow returns through the stack, then starts again.
            for (let index = files.length - 2; index >= 0; --index) {
                tryCompare(slideshow, "busy", false);
                compare(slideshow.currentItem, catalog.get(index));
                clock.triggered();
            }
            tryCompare(slideshow, "busy", false);
            compare(slideshow.currentItem, catalog.get(1));
            scene.width = 360;
            scene.height = 780;
            compare(slideshow.currentItem.width, 360);
            compare(slideshow.currentItem.height, 780);
        }

        function test_portrait_data() {
            const cases = [];
            for (const theme of [Material.Light, Material.Dark]) {
                for (const file of files) {
                    cases.push({
                                   tag: file + (theme === Material.Light ? "-light" : "-dark"),
                                   file: file,
                                   theme: theme
                               });
                }
            }
            return cases;
        }

        function test_portrait(data) {
            Theme.theme = data.theme;
            artwork.source = "qrc:/qt/qml/QShopper/backgrounds/" + data.file + ".jpg";
            tryCompare(artwork, "status", Image.Ready);
            compare(artwork.fillMode, Image.PreserveAspectCrop);
            compare(artwork.sourceSize.width, 1080);
            compare(artwork.sourceSize.height, 1920);
            for (const width of [360, 432]) {
                scene.width = width;
                scene.height = Math.round(width * 162.8 / 76.6);
                waitForRendering(preview);
                const frame = grabImage(preview);
                // Cropping must fill the entire portrait viewport, without blank bars.
                for (const x of [0, frame.width - 1]) {
                    for (const y of [0, frame.height - 1]) {
                        compare(frame.alpha(x, y), 255);
                    }
                }
                verify(!Qt.colorEqual(shortRow.contentItem.color, longRow.contentItem.color));
                compare(shortRow.contentItem.text, "Milk");
                verify(longRow.contentItem.font.strikeout);
                verify(longRow.contentItem.lineCount <= 3);
                if (width === 432) {
                    frame.save("ui013-" + data.tag + ".png");
                }
            }
        }

        name: "BackgroundArtwork"
        when: windowShown
    }
}
