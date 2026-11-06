pragma ComponentBehavior: Bound
import QShopper
import QtQuick
import QtQuick.Controls.Material
import QtQuick.Window
import QtTest

Item {
    id: scene

    width: 800
    height: 500
    Material.theme: Theme.theme
    Material.primary: Theme.primaryColor()
    Material.accent: Theme.accentColor()

    Binding {
        target: Theme
        property: "parent"
        value: scene
    }

    Binding {
        target: scene.Window.window ? scene.Window.window.Material : null
        property: "theme"
        value: Theme.theme
    }

    Image {
        id: artwork

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
    }

    Rectangle {
        id: extreme

        anchors.fill: parent
        visible: false
    }

    FontLoader {
        id: icons

        source: "qrc:/qt/qml/QShopper/fa-solid-900.ttf"
    }

    Component {
        id: shopComponent

        ShopView {
            x: 20
            y: 40
            width: 760
            height: 420
            fontFamily: icons.name
        }
    }

    TestCase {
        property var shop
        property var pointer
        property point start
        property point end

        function luminance(color) {
            function linear(value) {
                return value <= .04045 ? value / 12.92 : Math.pow((value + .055) / 1.055, 2.4);
            }
            return .2126 * linear(color.r) + .7152 * linear(color.g) + .0722 * linear(color.b);
        }

        function contrast(front, back) {
            const a = luminance(front);
            const b = luminance(back);
            return (Math.max(a, b) + .05) / (Math.min(a, b) + .05);
        }

        function composite(front, back) {
            return Qt.rgba(front.r * front.a + back.r * (1 - front.a), front.g * front.a + back.g * (
                               1 - front.a), front.b * front.a + back.b * (1 - front.a), 1);
        }

        function matches(a, b) {
            return Math.abs(a.r - b.r) < .025 && Math.abs(a.g - b.g) < .025 && Math.abs(a.b - b.b)
                    < .025;
        }

        function item() {
            shop.forceLayout();
            for (let index = 0; index < shop.count; ++index) {
                const holder = shop.itemAtIndex(index);
                if (holder && holder.item instanceof TextDelegate && holder.item.name === "Milk") {
                    return holder.item;
                }
            }
            return null;
        }

        function init() {
            failOnWarning(/.*Binding loop detected.*/);
            verify(Theme.pixelsPerMillimeter > 0);
            uiSetup.resetDatabase();
            Theme.scale = 2;
            Theme.swipeSensitivity = 0;
            Theme.activeList = "default";
            tryCompare(icons, "status", FontLoader.Ready);
        }

        function cleanup() {
            if (pointer) {
                pointer.release(0, scene, end.x, end.y).commit();
                pointer = null;
            }
            Qt.inputMethod.hide();
            Qt.styleHints.colorScheme = Qt.ColorScheme.Unknown;
        }

        function test_held_swipe_data() {
            const cases = [];
            for (const theme of [Material.Light, Material.Dark]) {
                for (const edit of [false, true]) {
                    for (const checked of [false, true]) {
                        for (const right of [false, true]) {
                            for (const background of ["white", "black", "03-bakery",
                                                      "10-evening-produce"]) {
                                cases.push({
                                               tag: (theme === Material.Light ? "Light" : "Dark")
                                                    + "-" + (edit ? "edit" : "shop") + "-" + (
                                                        checked ? "checked" : "unchecked") + "-" + (
                                                        right ? "right" : "left") + "-" + background,
                                               theme: theme,
                                               edit: edit,
                                               checked: checked,
                                               right: right,
                                               background: background
                                           });
                            }
                        }
                    }
                }
            }
            if (Qt.platform.pluginName === "windows") {
                for (const dark of [false, true]) {
                    cases.push({
                                   tag: "System-" + (dark ? "Dark" : "Light"),
                                   theme: Material.System,
                                   scheme: dark ? Qt.ColorScheme.Dark : Qt.ColorScheme.Light,
                                   edit: true,
                                   checked: false,
                                   right: true,
                                   background: "white"
                               });
                }
            }
            return cases;
        }

        function test_held_swipe(data) {
            if (data.scheme !== undefined) {
                Qt.styleHints.colorScheme = data.scheme;
            }
            Theme.theme = data.theme;
            Theme.primary = Material.Indigo;
            Theme.accent = Material.Purple;
            extreme.visible = data.background === "white" || data.background === "black";
            extreme.color = data.background === "black" ? "black" : "white";
            if (!extreme.visible) {
                artwork.source = "qrc:/qt/qml/QShopper/backgrounds/" + data.background + ".jpg";
                tryCompare(artwork, "status", Image.Ready);
            }
            shop = createTemporaryObject(shopComponent, scene);
            verify(shop !== null);
            shop.model.insert(0, "Milk");
            shop.setEditMode(data.edit);
            tryVerify(() => item() !== null);
            if (data.checked) {
                shop.model.setChecked(item().index, true);
            }
            tryVerify(() => item() !== null && item().checked === data.checked);
            const row = item();
            tryCompare(row, "x", 0);
            wait(50);
            tryVerify(() => Math.abs(row.parent.x) < .01 && row.parent.opacity === 1 && Math.abs(
                                row.parent.y - row.index * row.height) < .51, 2000,
            "Wait for production add/move transitions before input");
            start = row.mapToItem(scene, row.width * (data.right ? .15 : .85), row.height / 2);
            end = Qt.point(start.x + row.width * (data.right ? .6 : -.6), start.y);
            pointer = touchEvent(scene);
            pointer.press(0, scene, start.x, start.y).commit();
            for (let step = 1; step <= 4; ++step) {
                pointer.move(0, scene, start.x + (end.x - start.x) * step / 4, start.y).commit();
                wait(30);
            }
            verify(Math.abs(row.x) > row.width / 2,
                   "Actual held drag must cross the distance threshold; x=" + row.x);
            wait(280);
            const loader = row.background.children.filter(child
                                                          => child instanceof IconChoser)[data.right
                                                                                          ? 0 : 1];
            verify(loader.item !== null);
            const icon = loader.item;
            if (icon.animation.running) {
                icon.animation.pause();
            }
            const arrow = icon.arrow;
            const visible = grabImage(scene);
            arrow.visible = false;
            wait(25);
            const body = grabImage(scene);
            loader.visible = false;
            wait(25);
            const background = grabImage(scene);
            const bounds = icon.mapToItem(scene, Qt.rect(0, 0, icon.width, icon.height));
            let bodyCores = 0;
            let minimum = 100;
            let arrowCores = 0;
            let arrowEdge = 0;
            let minimumArrow = 100;
            for (let y = Math.ceil(bounds.y); y < Math.floor(bounds.y + bounds.height); ++y) {
                for (let x = Math.ceil(bounds.x); x < Math.floor(bounds.x + bounds.width); ++x) {
                    const behind = background.pixel(x, y);
                    if (matches(body.pixel(x, y), icon.color)) {
                        ++bodyCores;
                        minimum = Math.min(minimum, contrast(icon.color, behind));
                    }
                    const old = body.pixel(x, y);
                    const actual = visible.pixel(x, y);
                    if (!matches(actual, old)) {
                        if (matches(actual, composite(arrow.color, old))) {
                            ++arrowCores;
                            minimumArrow = Math.min(minimumArrow, contrast(composite(arrow.color,
                                                                                     old), old));
                        }
                        // A white arrow can only lighten its backdrop; darker changed
                        // pixels belong to its outline, including antialiased strokes.
                        if (luminance(actual) < luminance(old) - .02 && contrast(actual, old)
                                >= 3) {

                            ++arrowEdge;
                        }
                    }
                }
            }
            verify(bodyCores >= 20, "Rendered cart/bin body cores missing");
            verify(minimum >= 3, "Held swipe body contrast " + minimum.toFixed(3)
                   + ":1, expected 3:1");
            verify(arrowCores >= 3, "The arrow must remain distinguishable from its body");
            verify(minimumArrow >= 3 || arrowEdge >= 3,
                   "Arrow ink or visible outline must contrast with its actual adjacent surface");
            visible.save("ui028-" + data.tag + ".png");
            loader.visible = true;
            arrow.visible = true;
            const originalTheme = Theme.theme;
            const bodyInk = icon.color;
            const arrowInk = arrow.color;
            Theme.theme = scene.Material.theme === Material.Dark ? Material.Light : Material.Dark;
            Theme.accent = Material.Yellow;
            Theme.primary = Material.Grey;
            wait(40);
            compare(icon.color, bodyInk, "A live theme change keeps the semantic body foreground");
            compare(arrow.color, arrowInk, "A live theme change keeps the contrasting arrow");
            const live = grabImage(scene);
            for (let y = Math.ceil(bounds.y); y < Math.floor(bounds.y + bounds.height); ++y) {
                for (let x = Math.ceil(bounds.x); x < Math.floor(bounds.x + bounds.width); ++x) {
                    const old = visible.pixel(x, y);
                    if (matches(old, bodyInk) || matches(old, arrowInk)) {
                        verify(matches(live.pixel(x, y), old),
                               "Rendered feedback must survive live theme/palette changes");
                    }
                }
            }
            Theme.theme = originalTheme;
            if (icon.animation.paused) {
                icon.animation.resume();
            }
            pointer.release(0, scene, end.x, end.y).commit();
            pointer = null;
            if (data.edit && data.right) {
                tryVerify(() => shop.model.canUndo);
                compare(shop.model.undoMessage, "Milk removed");
                shop.model.undo();
                tryVerify(() => item() !== null);
                compare(item().checked, data.checked);
            } else {
                tryVerify(() => item() !== null && item().checked !== data.checked);
            }
            tryCompare(item(), "x", 0);
            Theme.accent = Material.Yellow;
            Theme.primary = Material.Grey;
            compare(item().contentItem.text, "Milk", "Theme choices must not change saved content");
        }

        name: "SwipeFeedbackContrast"
        when: windowShown
    }
}
