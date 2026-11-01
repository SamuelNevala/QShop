import QShopper
import QtQuick
import QtTest

Item {
    id: scene

    width: 640
    height: 480

    Binding {
        target: Theme
        property: "parent"
        value: scene
    }

    Component {
        id: shopComponent

        ShopView {
            width: 600
            height: 440
        }
    }

    Component {
        id: spyComponent

        SignalSpy {
            signalName: "swiped"
        }
    }

    TestCase {
        property var shop

        function init() {
            uiSetup.resetDatabase();
            Theme.scale = 1;
            Theme.swipeSensitivity = 1;
            Theme.activeList = "default";
            shop = createTemporaryObject(shopComponent, scene);
            verify(shop !== null);
            tryCompare(shop, "editMode", true);
            shop.model.insert(0, "milk");
            shop.model.insert(1, "bread");
        }

        function firstItem() {
            shop.forceLayout();
            tryVerify(function () {
                return shop.itemAtIndex(0) !== null;
            });
            const chooser = shop.itemAtIndex(0);
            tryCompare(chooser, "x", 0);
            tryCompare(chooser, "y", 0);
            const item = chooser.item;
            tryCompare(item, "x", 0);
            compare(item.name, "milk");
            return item;
        }

        function gesture(item, data) {
            const start = item.mapToItem(shop, item.width * (data.right ? 0.1 : 0.9), item.height
                                         / 2);


            const sign = data.right ? 1 : -1;
            const distance = item.width * (data.short ? 0.2 : data.fast ? 0.4 : 0.75);
            const touch = data.touch ? touchEvent(shop) : null;
            if (touch) {
                touch.press(0, shop, start.x, start.y).commit();
            } else {
                mousePress(shop, start.x, start.y, Qt.LeftButton, Qt.NoModifier, 0);
            }
            for (let step = 1; step <= 3; ++step) {
                if (!data.fast && step > 1) {
                    wait(200);
                }
                const x = start.x + sign * distance * step / 3;
                if (touch) {
                    touch.move(0, shop, x, start.y).commit();
                } else {
                    mouseMove(shop, x, start.y, 0);
                }
            }
            const endX = data.pullback ? start.x : start.x + sign * distance;
            if (data.pullback) {
                if (touch) {
                    touch.move(0, shop, endX, start.y).commit();
                } else {
                    mouseMove(shop, endX, start.y, 0);
                }
            }
            if (touch) {
                touch.release(0, shop, endX, start.y).commit();
            } else {
                mouseRelease(shop, endX, start.y, Qt.LeftButton, Qt.NoModifier, 0);
            }
        }

        function test_swipe_action_data() {
            const cases = [];
            for (const touch of [false, true]) {
                for (const edit of [false, true]) {
                    for (const right of [false, true]) {
                        for (const fast of [false, true]) {
                            // Native mouse cursor delivery is asynchronous; use touch
                            // timestamps for the velocity-only cases on every platform.
                            if (!touch && fast) {
                                continue;
                            }
                            cases.push({
                                           tag: (touch ? "touch" : "mouse") + "_" + (edit ? "edit" :
                                                                                            "shop") + "_"
                                                + (right ? "right" : "left") + "_" + (fast
                                                                                      ? "velocity" :
                                                                                        "distance"),
                                           touch: touch,
                                           edit: edit,
                                           right: right,
                                           fast: fast
                                       });
                        }
                    }
                }
            }
            return cases;
        }

        function test_swipe_action(data) {
            shop.setEditMode(data.edit);
            const item = firstItem();
            // Disable the velocity alternative so distance cases cannot pass through it.
            Theme.swipeSensitivity = data.fast ? 1 : 0;
            gesture(item, data);
            if (data.edit && data.right) {
                tryCompare(shop, "count", 2, 2000);
                tryVerify(function () {
                    shop.forceLayout();
                    const first = shop.itemAtIndex(0);
                    return first !== null && first.item.name === "bread";
                });
                verify(shop.model.canUndo);
            } else {
                tryCompare(item, "checked", true, 2000);
                tryCompare(item, "x", 0);
                compare(shop.count, data.edit ? 3 : 2);
            }
        }

        function test_rejected_swipe_data() {
            const cases = [];
            for (const edit of [false, true]) {
                for (const right of [false, true]) {
                    for (const pullback of [false, true]) {
                        cases.push({
                                       tag: (edit ? "edit" : "shop") + "_" + (right ? "right" :
                                                                                      "left") + "_"
                                            + (pullback ? "pullback" : "short_slow"),
                                       touch: true,
                                       edit: edit,
                                       right: right,
                                       fast: false,
                                       short: !pullback,
                                       pullback: pullback
                                   });
                    }
                }
            }
            return cases;
        }

        function test_rejected_swipe(data) {
            shop.setEditMode(data.edit);
            const item = firstItem();
            const spy = createTemporaryObject(spyComponent, scene, {
                                                  target: item
                                              });
            verify(spy.valid);
            gesture(item, data);
            // Wait past the swipe animation, then assert that no action was delivered.
            wait(350);
            compare(spy.count, 0);
            compare(item.checked, false);
            compare(item.x, 0);
            compare(shop.count, data.edit ? 3 : 2);
            compare(shop.itemAtIndex(0).item.name, "milk");
        }

        name: "SwipeInteractions"
        when: windowShown
    }
}
