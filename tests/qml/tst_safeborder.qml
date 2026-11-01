import QShopper
import QtQuick
import QtQuick.Controls.Material
import QtTest

Item {
    width: 600
    height: 780

    Component {
        id: backdropComponent

        Rectangle {
            anchors.fill: parent
            color: "#c06040"
            z: -1
        }
    }

    TestCase {
        property var app
        property var view
        property var shop

        function init() {
            uiSetup.resetDatabase();
            Theme.activeList = "default";
            Theme.scale = 1;
            Theme.theme = Material.Dark;
            const component = Qt.createComponent("qrc:/qt/qml/QShopper/main.qml");
            compare(component.status, Component.Ready, component.errorString());
            app = createTemporaryObject(component, null, {
                                            asynchronous: false
                                        });
            verify(app !== null);
            tryCompare(app, "visible", true);
            app.requestActivate();
            tryCompare(app, "active", true);
            view = app.contentItem.children[0].item;
            shop = view.contentItem;
            // Compare the actual row and border composites over the same stable
            // underlay; different wallpaper pixels cannot establish a mismatch.
            let artwork = null;
            for (const child of view.background.children) {
                if (child instanceof Background) {
                    artwork = child;
                }
            }
            verify(artwork !== null);
            artwork.visible = false;
            verify(createTemporaryObject(backdropComponent, view.background) !== null);
            const safe = app.contentItem.SafeArea.additionalMargins;
            safe.top = 48;
            safe.bottom = 52;
            safe.left = 28;
            safe.right = 32;
            shop.model.insert(0, "Milk");
            shop.model.insert(1, "Bread");
            shop.model.insert(2, "Apples");
            shop.setEditMode(false);
            wait(650);
            app.width = 600;
            app.height = 780;
            shop.forceLayout();
            wait(50);
        }

        function cleanup() {
            if (app) {
                app.close();
                app.destroy();
            }
            Theme.theme = Material.Dark;
            wait(0);
        }

        function pixel(image, point) {
            return image.pixel(Math.floor(point.x), Math.floor(point.y));
        }

        function verifySurfaces() {
            shop.forceLayout();
            verify(view.topPadding >= 48);
            verify(view.bottomPadding >= 52);
            verify(view.leftPadding >= 28);
            verify(view.rightPadding >= 32);
            const row = shop.itemAtIndex(0);
            verify(row !== null);
            const point = row.mapToItem(app.contentItem, row.width - 8, row.height / 2);
            const image = grabImage(app.contentItem);
            const expected = pixel(image, point);
            const borders = [
                      {
                          name: "top",
                          x: app.width * 0.75,
                          y: view.topPadding / 2
                      },
                      {
                          name: "bottom",
                          x: app.width * 0.75,
                          y: app.height - view.bottomPadding / 2
                      },
                      {
                          name: "left",
                          x: view.leftPadding / 2,
                          y: point.y
                      },
                      {
                          name: "right",
                          x: app.width - view.rightPadding / 2,
                          y: point.y
                      }
                  ];
            for (const border of borders) {
                compare(pixel(image, border), expected, border.name
                        + " border differs from unchecked row");
            }
            compare(pixel(image, shop.mapToItem(app.contentItem, shop.width - 8, shop.height - 12)),
                    expected, "Empty-area surface differs");
            return expected;
        }

        function test_theme_surfaces_data() {
            return [
                        {
                            tag: "light",
                            theme: Material.Light
                        },
                        {
                            tag: "dark",
                            theme: Material.Dark
                        },
                        {
                            tag: "system",
                            theme: Material.System
                        }
                    ];
        }

        function test_theme_surfaces(data) {
            Theme.theme = data.theme;
            wait(350);
            const expected = verifySurfaces();
            shop.model.toggleChecked(0);
            wait(650);
            verifySurfaces();
            const checked = shop.itemAtIndex(shop.count - 1);
            verify(checked.checked);
            const image = grabImage(app.contentItem);
            verify(!Qt.colorEqual(pixel(image, checked.mapToItem(app.contentItem, checked.width - 8,
                                                                 checked.height / 2)), expected),
                   "Checked row loses its contrasting surface");
        }

        function test_live_theme_changes() {
            for (const theme of [Material.Light, Material.Dark, Material.System, Material.Light]) {
                Theme.theme = theme;
                wait(350);
                verifySurfaces();
            }
        }

        function test_resized_safe_areas_in_edit_mode() {
            shop.setEditMode(true);
            wait(650);
            // Standalone viewport simulation complements the real Android IME run.
            app.height = 520;
            app.contentItem.SafeArea.additionalMargins.bottom = 120;
            shop.forceLayout();
            wait(50);
            const row = shop.itemAtIndex(1);
            const image = grabImage(app.contentItem);
            const rowPixel = pixel(image, row.mapToItem(app.contentItem, row.width - 8, row.height
                                                        / 2));
            compare(pixel(image, {
                              x: app.width * 0.75,
                              y: view.topPadding / 2
                          }), rowPixel);
            verify(shop.y >= 48);
            verify(shop.y + shop.height <= app.height - 120);
        }

        name: "SafeBorderColors"
        when: windowShown
    }
}
