import QShopper
import QtQuick
import QtQuick.Controls.Material
import QtTest

Item {
    id: scene

    width: 480
    height: 720

    Rectangle {
        anchors.fill: parent
        color: "#c06040"
    }

    Component {
        id: shopComponent

        ShopView {
            width: scene.width
            Material.theme: Theme.theme
        }
    }

    TestCase {
        property var shop
        property var filler
        property color rowColor

        function init() {
            uiSetup.resetDatabase();
            Theme.activeList = "default";
            Theme.scale = 1;
            Theme.theme = Material.Dark;
            shop = createTemporaryObject(shopComponent, scene, {
                                             height: scene.height
                                         });
            verify(shop !== null);
            filler = findChild(shop, "emptyAreaBackground");
            verify(filler !== null);
        }

        function populate(count) {
            for (let i = 0; i < count; ++i) {
                shop.model.insert(i, "Item " + i);
            }
            shop.setEditMode(false);
            shop.forceLayout();
            wait(650);
            shop.positionViewAtBeginning();
            wait(30);
            const image = grabImage(scene);
            rowColor = image.pixel(scene.width - 5, Math.round(Theme.pixels(9.27) / 2));
        }

        function verifyBackground(label, checkPixels = true) {
            shop.forceLayout();
            wait(30);
            // All rows have the same fixed height. The entire model, rather than
            // the currently instantiated delegates, determines the uncovered area.
            let reference = null;
            for (let index = 0; index < shop.count && !reference; ++index) {
                reference = shop.itemAtIndex(index);
            }
            verify(reference !== null);
            const rowHeight = reference.height;
            const referenceY = reference.mapToItem(shop, 0, 0).y;
            const end = referenceY + (shop.count - reference.index) * rowHeight;
            const expectedTop = Math.max(0, end);
            const image = grabImage(scene);
            // Sample the right edge away from labels/icons. Extra filler beneath
            // a delegate compounds its opacity, producing a visible dark block.
            for (let y = 5; checkPixels && y < shop.height - 5; y += 7) {
                const offset = ((y - referenceY) % rowHeight + rowHeight) % rowHeight;
                // Fractional row edges can overlap by a rasterized pixel; sample interiors.
                if (offset > 2 && offset < rowHeight - 2) {
                    compare(image.pixel(scene.width - 5, y), rowColor, label + ": background discontinuity at y="
                            + y);
                }
            }
            if (expectedTop < shop.height) {
                verify(Math.abs(filler.y - expectedTop) < 1, label + ": filler starts at " + filler.y + ", list ends at "
                       + end);
            } else {
                verify(filler.y >= shop.height, label + ": filler at " + filler.y
                       + " overlaps delegates ending at " + end);
            }
        }

        function test_virtualized_scrolling_data() {
            return [
                        {
                            tag: "34_compact",
                            count: 34,
                            height: 360,
                            theme: Material.Dark
                        },
                        {
                            tag: "35_compact",
                            count: 35,
                            height: 360,
                            theme: Material.Dark
                        },
                        {
                            tag: "80_compact",
                            count: 80,
                            height: 360,
                            theme: Material.Dark
                        },
                        {
                            tag: "35_tall",
                            count: 35,
                            height: 720,
                            theme: Material.Light
                        },
                        {
                            tag: "80_tall",
                            count: 80,
                            height: 720,
                            theme: Material.Light
                        }
                    ];
        }

        function test_virtualized_scrolling(data) {
            shop.height = data.height;
            Theme.theme = data.theme;
            populate(data.count);
            for (const index of [0, Math.floor(data.count / 2), data.count - 1, Math.floor(
                                     data.count / 2), 0]) {
                shop.positionViewAtIndex(index, ListView.Beginning);
                wait(100);
                verifyBackground("row " + index);
            }
        }

        function test_empty_and_short_lists() {
            populate(0);
            compare(filler.y, 0);
            compare(filler.height, shop.height);
            populate(3);
            verifyBackground("short list");
            shop.model.toggleChecked(0);
            wait(600);
            // Checked rows deliberately use the inverse theme; check geometry only.
            compare(filler.y, shop.count * Theme.pixels(9.27));
            shop.setEditMode(true);
            shop.model.moveEditor(2);
            wait(650);
            compare(filler.y, shop.count * Theme.pixels(9.27));
            shop.removeAll();
            wait(650);
            compare(shop.count, 1);
            compare(filler.y, Theme.pixels(9.27));
        }

        function test_mutations_at_end() {
            populate(80);
            shop.positionViewAtEnd();
            wait(100);
            shop.model.toggleChecked(10);
            wait(650);
            verifyBackground("checked item", false);
            shop.setEditMode(true);
            shop.model.moveEditor(77);
            shop.positionViewAtEnd();
            wait(650);
            verifyBackground("moved editor", false);
            shop.removeAll();
            wait(900);
            compare(shop.count, 1);
            compare(filler.y, Theme.pixels(9.27));
            compare(filler.height, shop.height - filler.y);
        }

        function test_touch_scroll_and_viewport_resize() {
            populate(80);
            const touch = touchEvent(shop);
            for (let i = 0; i < 8; ++i) {
                touch.press(0, shop, 240, shop.height * 0.8).commit();
                wait(30);
                touch.move(0, shop, 240, shop.height * 0.55).commit();
                wait(30);
                touch.move(0, shop, 240, shop.height * 0.3).commit();
                wait(30);
                touch.release(0, shop, 240, shop.height * 0.2).commit();
                tryCompare(shop, "moving", false, 5000);
                verifyBackground("touch scroll " + i);
            }
            verify(shop.contentY > Theme.pixels(9.27) * 20);
            // Android native IME coverage additionally verifies the real resize.
            for (const height of [360, 720]) {
                shop.height = height;
                shop.positionViewAtEnd();
                wait(100);
                verifyBackground("resized " + height);
            }
        }

        name: "ListBackground"
        when: windowShown
    }
}
