pragma ComponentBehavior: Bound
import QShopper
import QtQuick
import QtQuick.Controls.Material
import QtTest

Item {
    id: scene

    width: 600
    height: 900

    Component {
        id: spyComponent

        SignalSpy {}
    }

    TestCase {
        property var app
        property var shop
        property var drawer

        function find(item, predicate) {
            if (predicate(item)) {
                return item;
            }
            for (const child of item.children) {
                const match = find(child, predicate);
                if (match) {
                    return match;
                }
            }
            return null;
        }

        function init() {
            failOnWarning(/.*Binding loop detected.*/);
            uiSetup.resetDatabase();
            Theme.activeList = "default";
            Theme.scale = 1;
            Theme.accent = Material.Green;
            const component = Qt.createComponent("qrc:/qt/qml/QShopper/main.qml");
            compare(component.status, Component.Ready, component.errorString());
            app = createTemporaryObject(component, null, {
                                            asynchronous: false
                                        });
            verify(app !== null);
            app.requestActivate();
            tryCompare(app, "active", true);
            shop = app.contentItem.children[0].item.contentItem;
            drawer = shop.data.find(child => typeof child.open === "function" && child.contentItem);
            verify(drawer !== undefined);
            Qt.inputMethod.hide();
        }

        function cleanup() {
            Qt.inputMethod.hide();
            app.close();
            app.destroy();
            wait(0);
        }

        function records() {
            const result = [];
            for (let index = 0; index < shop.model.count; ++index) {
                if (index !== shop.model.editorIndex) {
                    const modelIndex = shop.model.index(index, 0);
                    result.push([shop.model.data(modelIndex, Qt.DisplayRole), shop.model.data(modelIndex,
                                                                                              Qt.CheckStateRole),
                                 shop.model.data(modelIndex, Qt.UserRole + 1)]);
                }
            }
            return result;
        }

        function delegates() {
            return shop.contentItem.children.filter(child => child instanceof DelegateChoser &&
                                                             !child.input);
        }

        function test_clear_undo_data() {
            const cases = [];
            for (const dark of [false, true]) {
                for (const count of [3, 30]) {
                    for (const touch of [false, true]) {
                        for (const settled of [false, true]) {
                            cases.push({
                                           tag: (dark ? "dark" : "light") + "-" + count + "-" + (
                                                    touch ? "touch" : "mouse") + "-" + (settled
                                                                                        ? "settled" :
                                                                                          "fast"),
                                           dark: dark,
                                           count: count,
                                           touch: touch,
                                           settled: settled
                                       });
                        }
                    }
                }
            }
            return cases;
        }

        function test_clear_undo(data) {
            Theme.theme = data.dark ? Material.Dark : Material.Light;
            for (let index = 0; index < data.count; ++index) {
                shop.model.insert(shop.count, "Item " + index);
            }
            shop.model.setChecked(2, true);
            shop.forceLayout();
            wait(700);
            const before = records();
            compare(before.length, data.count);
            const pressed = delegates().map(row => createTemporaryObject(spyComponent, scene, {
                                                                             target: row.item,
                                                                             signalName: "pressed"
                                                                         }));
            drawer.open();
            tryCompare(drawer, "opened", true);
            const sections = drawer.contentItem;
            sections.positionViewAtIndex(1, ListView.Contain);
            sections.forceLayout();
            const clear = find(sections.itemAtIndex(1), item => item.text === "Clear\nlist");
            verify(clear !== null);
            const bar = findChild(app.contentItem.children[0].item, "undoBar");
            verify(bar !== null);
            const received = createTemporaryObject(spyComponent, scene, {
                                                       target: bar,
                                                       signalName: "undoRequested"
                                                   });
            const start = Date.now();
            mouseClick(clear, clear.width / 2, clear.height / 2);
            tryCompare(shop.model, "canUndo", true);
            // Unlike settled-path helpers, poll every frame and never wait for rows to retire.
            while (!(bar.visible && bar.enabled && !drawer.visible)) {
                verify(Date.now() - start < 1500,
                       "Undo must become available after the drawer closes");
                wait(5);
            }
            if (data.settled) {
                wait(600);
            }
            const action = findChild(bar, "undoAction");
            verify(action !== null);
            const point = action.mapToItem(app.contentItem, action.width * .5, action.height * .5);
            const image = grabImage(app.contentItem);
            // Sample clear fill away from the caption/icon, in the rendered bar itself.
            const sample = action.mapToItem(app.contentItem, action.width * .5, action.height
                                            * .85);
            const pixel = image.pixel(Math.round(sample.x), Math.round(sample.y));
            const fill = Theme.accentFillColor();
            fuzzyCompare(pixel.r, fill.r, .03);
            fuzzyCompare(pixel.g, fill.g, .03);
            fuzzyCompare(pixel.b, fill.b, .03);
            image.save("fastundo-" + data.tag + "-press.png");
            const retiring = delegates().map(row => ({
                name: row.name,
                x: row.x,
                opacity: row.opacity,
                delayed: row.ListView.delayRemove
            }));
            if (!data.settled) {
                verify(retiring.length > 0, "The fast press must overlap outgoing delegates");
                verify(retiring.some(row => row.delayed || row.x > 0 || row.opacity < 1),
                       "The real remove transition must still be active");
            }
            console.log("FAST_UNDO", JSON.stringify({
                                                        tag: data.tag,
                                                        elapsed: Date.now() - start,
                                                        point: point,
                                                        retiring: retiring
                                                    }));
            if (data.touch) {
                const pointer = touchEvent(app.contentItem);
                pointer.press(0, app.contentItem, point.x, point.y).commit();
                pointer.release(0, app.contentItem, point.x, point.y).commit();
            } else {
                mouseClick(app.contentItem, point.x, point.y);
            }
            compare(received.count, 1, "The visible Undo bar must receive the press");
            compare(pressed.reduce((total, spy) => total + spy.count, 0), 0,
                    "No outgoing row may receive the Undo press");


            tryCompare(shop.model, "canUndo", false);
            compare(records(), before, "Restore exact names, flags, order and identities");
            wait(600);
            compare(records(), before, "Retiring-row cleanup must not change the restored model");
        }

        name: "FastUndo"
        when: windowShown
    }
}
