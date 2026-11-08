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

        function test_drawer_dims_safe_areas_data() {
            return test_theme_surfaces_data();
        }

        function test_drawer_dims_safe_areas(data) {
            Theme.theme = data.theme;
            wait(350);
            const normal = verifySurfaces();
            let drawer = null;
            for (const child of shop.data) {
                if (child instanceof Drawer) {
                    drawer = child;
                }
            }
            verify(drawer !== null);
            shop.openMenu();
            tryCompare(drawer, "opened", true);
            wait(200);
            const row = shop.itemAtIndex(0);
            const point = row.mapToItem(app.contentItem, row.width - 8, row.height / 2);
            const image = grabImage(app.contentItem);
            const dimmed = pixel(image, point);
            verify(dimmed !== normal, "The exposed shopping surface must be dimmed");
            for (const border of [
                     {
                         name: "top",
                         x: point.x,
                         y: view.topPadding / 2
                     },
                     {
                         name: "bottom",
                         x: point.x,
                         y: app.height - view.bottomPadding / 2
                     },
                     {
                         name: "right",
                         x: app.width - view.rightPadding / 2,
                         y: point.y
                     }
                 ]) {
                compare(pixel(image, border), dimmed, border.name
                        + " safe area must follow drawer dimming");
            }
            // The left inset lies under the drawer itself. Native Material
            // rendering includes its elevation shadow here; software uses the
            // scrim. Both must affect the inset and restore on close.
            verify(pixel(image, {
                             x: view.leftPadding / 2,
                             y: point.y
                         }) !== normal, "The drawer must affect the left safe area");
            compare(app.color, Qt.tint(app.Material.backgroundColor,
                                       drawer.Material.backgroundDimColor),
                    "Native icon contrast must follow the effective dimmed window background");
            drawer.close();
            tryCompare(drawer, "visible", false);
            verifySurfaces();
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
            Theme.theme = Material.Light;
            wait(350);
            const light = verifySurfaces();
            Theme.theme = Material.Dark;
            wait(350);
            const dark = verifySurfaces();
            verify(!Qt.colorEqual(light, dark), "Light and Dark must change the surface color");
            Theme.theme = Material.System;
            wait(350);
            compare(verifySurfaces(), view.Material.theme === Material.Light ? light : dark);
            Theme.theme = Material.Light;
            wait(350);
            compare(verifySurfaces(), light);
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
