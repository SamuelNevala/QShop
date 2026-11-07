pragma ComponentBehavior: Bound
import QShopper
import QtQuick
import QtQuick.Controls.Material
import QtQuick.Window
import QtTest

Item {
    id: scene

    width: 640
    height: 480

    Component {
        id: metricsComponent

        Item {
            readonly property string screenName: Screen.name
            readonly property var owningWindow: Window.window

            visible: false
        }
    }

    TestCase {
        property var app
        property var shop
        property var metrics
        readonly property var entries: ["Milk",
            "Whole grain bread with sunflower seeds and no added sugar",
            "Shopping ingredients for a large family dinner including potatoes carrots onions mushrooms tomatoes pasta and cheese",
            "W".repeat(80), "Very long shopping entry ".repeat(40), "Checked item"]

        function records() {
            const values = [];
            for (let index = 0; index < shop.count; ++index) {
                if (index !== shop.model.editorIndex) {
                    const key = shop.model.index(index, 0);
                    values.push([shop.model.data(key, Qt.DisplayRole), shop.model.data(key, Qt.CheckStateRole),
                                 shop.model.data(key, Qt.UserRole + 1)]);
                }
            }
            return values;
        }

        function settle() {
            shop.forceLayout();
            tryVerify(() => {
                for (let index = 0; index < shop.count; ++index) {
                    const holder = shop.itemAtIndex(index);
                    if (!holder || !holder.item || Math.abs(holder.x) > .1 || Math.abs(
                                holder.item.x) > .1 || Math.abs(holder.y - index * holder.height) > .6
                            || holder.opacity < .99) {
                        return false;
                    }
                }
                return true;
            }, 4000, "Wait for actual production delegate layout");
        }

        function moveTo(display) {
            verify(Theme.parent === app.contentItem);
            app.screen = display;
            app.x = display.virtualX + 80;
            app.y = display.virtualY + 80;
            app.requestActivate();
            tryVerify(() => app.screen.name === display.name && metrics.screenName === display.name,
            3000, "Both the window and Theme singleton must follow the actual monitor");
            tryVerify(() => Math.abs(app.width - Math.round(Theme.pixels(76.6))) < 1.1 && Math.abs(
                                app.height - Math.round(Theme.pixels(162.8))) < 1.1, 3000,
            "Queued native window sizing must settle on the current display");
            compare(Theme.densityCorrection, display.name === "LG TV SSCR2" ? 1.5 : 1);
            fuzzyCompare(Theme.pixelsPerMillimeter, display.pixelDensity * Theme.densityCorrection
                         * Theme.effectiveScale, .001);
            settle();
            waitForRendering(app.contentItem);
        }

        function open(display, scale, theme) {
            Theme.scale = scale;
            Theme.theme = theme;
            const component = Qt.createComponent("qrc:/qt/qml/QShopper/main.qml");
            compare(component.status, Component.Ready, component.errorString());
            app = createTemporaryObject(component, null, {
                                            asynchronous: false,
                                            x: display.virtualX + 80,
                                            y: display.virtualY + 80
                                        });
            verify(app !== null);
            verify(Theme.parent === app.contentItem);
            metrics = createTemporaryObject(metricsComponent, Theme.parent);
            verify(metrics !== null);
            tryVerify(() => metrics.owningWindow === app, 2000,
            "Theme's attached screen observer must belong to the real app window");
            tryCompare(app, "visible", true);
            shop = app.contentItem.children[0].item.contentItem;
            for (const text of entries) {
                shop.model.insert(shop.count, text);
            }
            shop.setEditMode(false);
            shop.model.setChecked(shop.count - 1, true);
            InputMethod.hide();
            moveTo(display);
        }

        function capture(tag) {
            const frame = grabImage(app.contentItem);
            const sx = frame.width / app.contentItem.width;
            const sy = frame.height / app.contentItem.height;
            verify(Math.abs(frame.width - Math.round(app.contentItem.width * app.screen.devicePixelRatio)) <= 1,
                   "Render target width must follow the current monitor's DPR");
            verify(Math.abs(frame.height - Math.round(app.contentItem.height * app.screen.devicePixelRatio)) <= 1,
                   "Render target height must follow the current monitor's DPR");
            const sizes = [];
            for (let index = 0; index < shop.count; ++index) {
                const holder = shop.itemAtIndex(index);
                if (!holder.input) {
                    const row = holder.item;
                    const label = row.contentItem;
                    compare(label.text, row.name);
                    verify(label.lineCount >= 1 && label.lineCount <= 3);
                    verify(label.contentWidth <= label.width + 1);
                    verify(label.contentHeight <= label.height + 1);
                    fuzzyCompare(row.height, Theme.pixels(9.27), .01);
                    compare(label.font.strikeout, row.checked);
                    const point = row.mapToItem(app.contentItem, 0, 0);
                    const ink = label.color;
                    let pixels = 0;
                    for (let y = Math.ceil((point.y + 2) * sy); y < Math.floor((point.y
                                                                                + row.height - 2)
                                                                               * sy); ++y) {
                        for (let x = Math.ceil((point.x + 2) * sx); x < Math.floor((point.x
                                                                                    + row.width
                                                                                    - 2) * sx); ++x) {
                            const pixel = frame.pixel(x, y);
                            // Material primary text has alpha in Light mode. A fully
                            // covered glyph blends with the slideshow behind its row.
                            const tolerance = .035 + (1 - ink.a);
                            if (Math.abs(pixel.r - ink.r) < tolerance && Math.abs(pixel.g - ink.g)
                                    < tolerance && Math.abs(pixel.b - ink.b) < tolerance) {
                                ++pixels;
                            }
                        }
                    }
                    verify(pixels >= 15, "Actual rendered text must exist on " + app.screen.name
                           + ": " + row.name);
                    if (row.name === "Milk") {
                        compare(label.lineCount, 1);
                        verify(!label.truncated);
                        verify(label.fontInfo.pixelSize >= Math.round(Theme.pixels(7)) - 1);
                    }
                    sizes.push({
                                   name: row.name.slice(0, 50),
                                   lines: label.lineCount,
                                   font: label.fontInfo.pixelSize,
                                   logicalHeight: row.height,
                                   frameHeight: row.height * sy,
                                   inkPixels: pixels
                               });
                }
            }
            frame.save("display-" + tag + ".png");
            console.log("DISPLAY_RESULT", JSON.stringify({
                                                             tag: tag,
                                                             screen: app.screen.name,
                                                             screenWidth: app.screen.width,
                                                             screenHeight: app.screen.height,
                                                             dpr: app.screen.devicePixelRatio,
                                                             density: app.screen.pixelDensity,
                                                             correction: Theme.densityCorrection,
                                                             scale: Theme.scale,
                                                             window: [app.width, app.height],
                                                             frame: [frame.width, frame.height],
                                                             frameScale: [sx, sy],
                                                             rows: sizes
                                                         }));
        }

        function init() {
            failOnWarning(/.*Binding loop detected.*/);
            uiSetup.resetDatabase();
            Theme.activeList = "default";
        }

        function cleanup() {
            InputMethod.hide();
            if (app) {
                app.close();
                app.destroy();
                app = null;
            }
            wait(0);
        }

        function test_actual_monitors_data() {
            const cases = [];
            for (let screen = 0; screen < Qt.application.screens.length; ++screen) {
                for (const scale of [1, 2]) {
                    for (const dark of [false, true]) {
                        cases.push({
                                       tag: "screen" + screen + "-" + scale + "-" + (dark ? "dark" :
                                                                                            "light"),
                                       screen: screen,
                                       scale: scale,
                                       dark: dark
                                   });
                    }
                }
            }
            return cases;
        }

        function test_actual_monitors(data) {
            open(Qt.application.screens[data.screen], data.scale, data.dark ? Material.Dark :
                                                                              Material.Light);


            compare(shop.itemAtIndex(shop.count - 1).item.checked, true);
            capture(data.tag);
            compare(records().map(row => row[0]), entries);
        }

        function test_existing_window_across_monitors() {
            if (Qt.application.screens.length < 2) {
                skip("Connect two actual displays for cross-monitor transition coverage");
            }
            open(Qt.application.screens[0], 1.5, Material.Dark);
            shop.setEditMode(true);
            settle();
            const field = shop.itemAtIndex(shop.model.editorIndex).item.contentItem;
            field.text = "Draft kept across displays";
            field.forceActiveFocus();
            InputMethod.show();
            const keyboard = findChild(app, "developmentKeyboard");
            verify(keyboard !== null);
            tryCompare(keyboard, "opened", true);
            const before = records();
            for (let cycle = 0; cycle < 2; ++cycle) {
                for (let screen = 0; screen < Qt.application.screens.length; ++screen) {
                    moveTo(Qt.application.screens[screen]);
                    compare(Theme.scale, 1.5);
                    compare(field.text, "Draft kept across displays");
                    compare(records(), before,
                            "Screen movement must retain list identity, order and checks");
                    compare(keyboard.opened, true);
                    verify(keyboard.occupiedHeight > 0 && keyboard.occupiedHeight < app.height);
                    capture("move-" + cycle + "-" + screen);
                }
            }
        }

        name: "ConnectedDisplays"
        when: windowShown
    }
}
