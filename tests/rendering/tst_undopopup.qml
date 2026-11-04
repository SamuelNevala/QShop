pragma ComponentBehavior: Bound
import QShopper
import QtQuick
import QtQuick.Controls.Material
import QtTest

Item {
    id: scene

    width: 1000
    height: 900

    Binding {
        target: Theme
        property: "parent"
        value: scene
    }

    Component {
        id: underlayComponent

        Rectangle {
            anchors.fill: parent
            z: 100
            color: "#204060"
        }
    }

    Component {
        id: viewComponent

        View {
            width: Theme.pixels(76.6)
            height: Theme.pixels(90)
        }
    }

    TestCase {
        property var view
        property var shop
        property var popup
        property var progress
        property var expiry
        property var underlay

        function init() {
            failOnWarning(/.*Binding loop detected.*/);
            uiSetup.resetDatabase();
            Theme.activeList = "default";
            Theme.scale = 1;
            Theme.theme = Material.Light;
        }

        function open() {
            view = createTemporaryObject(viewComponent, scene);
            verify(view !== null);
            shop = view.contentItem;
            underlay = createTemporaryObject(underlayComponent, shop);
            verify(underlay !== null);
            shop.model.insert(1, "Milk");
            shop.model.insert(2, "Bread");
            shop.model.insert(3, "Oats");
            shop.model.remove(1);
            popup = findChild(view, "undoBar");
            progress = findChild(popup, "undoCountdown");
            expiry = findChild(popup, "undoExpiry");
            verify(progress !== null && expiry !== null);
            tryCompare(popup, "opened", true);
            wait(100);
        }

        function sample(image, fraction) {
            const point = popup.parent.mapToItem(scene, popup.x + popup.width * fraction, popup.y
                                                 + popup.height * 0.88);
            return image.pixel(Math.round(point.x), Math.round(point.y));
        }

        function compareColor(actual, expected) {
            fuzzyCompare(actual.r, expected.r, 0.025);
            fuzzyCompare(actual.g, expected.g, 0.025);
            fuzzyCompare(actual.b, expected.b, 0.025);
        }

        function verifySolidForeground(image, icon) {
            verify(icon !== undefined);
            const origin = icon.mapToItem(scene, 0, 0);
            const foreground = icon.color;
            const accent = Theme.accentColor();
            const expected = Qt.rgba(foreground.r * foreground.a + accent.r * (1 - foreground.a),
                                     foreground.g * foreground.a + accent.g * (1 - foreground.a),
                                     foreground.b * foreground.a + accent.b * (1 - foreground.a),
                                     1);
            let solidPixels = 0;
            for (let y = 0; y < Math.floor(icon.height); ++y) {
                for (let x = 0; x < Math.floor(icon.width); ++x) {
                    const pixel = image.pixel(Math.round(origin.x) + x, Math.round(origin.y) + y);
                    if (Math.abs(pixel.r - expected.r) < 0.025 && Math.abs(pixel.g - expected.g)
                            < 0.025 && Math.abs(pixel.b - expected.b) < 0.025) {
                        ++solidPixels;
                    }
                }
            }
            verify(solidPixels > 0, "Text and icon must retain their full foreground color");
        }

        function test_fill_data() {
            return [
                        {
                            tag: "light-1",
                            theme: Material.Light,
                            scale: 1
                        },
                        {
                            tag: "dark-1",
                            theme: Material.Dark,
                            scale: 1
                        },
                        {
                            tag: "light-2",
                            theme: Material.Light,
                            scale: 2
                        },
                        {
                            tag: "dark-2",
                            theme: Material.Dark,
                            scale: 2
                        }
                    ];
        }

        function test_fill(data) {
            Theme.theme = data.theme;
            Theme.scale = data.scale;
            open();
            expiry.pause();
            const action = findChild(popup, "undoAction");
            const fill = findChild(popup, "undoRemainingFill");
            const surface = popup.Material.backgroundColor;
            const background = Qt.rgba(surface.r * 0.2 + underlay.color.r * 0.8, surface.g * 0.2
                                       + underlay.color.g * 0.8, surface.b * 0.2 + underlay.color.b
                                       * 0.8, 1);
            for (const millimeters of [60, 76.6]) {
                view.width = Theme.pixels(millimeters);
                wait(50);
                const original = action.mapToItem(scene, 0, 0);
                for (const value of [1, 0.5, 0]) {
                    progress.value = value;
                    wait(70);
                    // Grab the actual overlay together with its owning window.
                    const image = grabImage(scene);
                    const expected = Theme.accentColor();
                    compareColor(sample(image, 0.15), value > 0 ? expected : background);
                    compareColor(sample(image, 0.8), value === 1 ? expected : background);
                    if (value === 1) {
                        verifySolidForeground(image, popup.contentItem.children.find(item
                                                                                     => item.text
                                                                                        === "\uf0e2"));
                        verifySolidForeground(image, popup.contentItem.children.find(item
                                                                                     => item.text
                                                                                        === popup.message));
                    }
                    fuzzyCompare(fill.height, popup.height, 0.01);
                    fuzzyCompare(action.width, popup.width, 0.51);
                    fuzzyCompare(action.height, Theme.pixels(9.27), 0.51);
                    const point = action.mapToItem(scene, 0, 0);
                    fuzzyCompare(point.x, original.x, 0.01);
                    fuzzyCompare(point.y, original.y, 0.01);
                }
            }
        }

        function test_pause_resume_and_new_deletion_restart() {
            open();
            tryVerify(function () {
                return progress.value < 0.97;
            });
            const drawer = view.contentItem.data.find(item => typeof item.open === "function"
                                                              && item.contentItem);
            verify(drawer !== undefined);
            drawer.open();
            tryCompare(drawer, "opened", true);
            const held = progress.value;
            wait(250);
            compare(progress.value, held);
            drawer.close();
            tryCompare(drawer, "visible", false);
            tryVerify(function () {
                return progress.value < held;
            });
            const before = progress.value;
            shop.model.remove(1);
            verify(progress.value > before);
            compare(shop.model.undoMessage, "2 items removed");
        }

        function test_undo_preserves_text_focus_and_draft() {
            open();
            shop.forceLayout();
            const field = shop.itemAtIndex(shop.model.editorIndex).item.contentItem;
            field.forceActiveFocus();
            field.insert(0, "draft");
            tryCompare(field, "activeFocus", true);
            const action = findChild(popup, "undoAction");
            mouseClick(action, action.width / 2, action.height / 2);
            tryCompare(shop.model, "canUndo", false);
            compare(field.text, "draft");
            compare(field.activeFocus, true);
        }

        function cleanup() {
            if (popup) {
                popup.close();
            }
            Qt.inputMethod.hide();
            Theme.scale = 1;
        }

        name: "UndoPopupRendering"
        when: windowShown
    }
}
