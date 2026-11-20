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
            hapticsSpy.clear();
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
            const endX = data.pullback ? start.x : start.x + sign * distance;
            try {
                compare(hapticsSpy.count, 0);
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
                // Feedback belongs to recognition, while the row is still uncommitted.
                if (data.fast) {
                    // Flush compressed synthetic moves while held, preserving the velocity path.
                    waitForRendering(shop);
                }
                const handler = item.data.find(child => child instanceof SwipeHandler);
                verify(handler !== undefined && handler.active);
                compare(item.checked, false);
                compare(hapticsSpy.count, shop.model.readOnly ? 0 : 1);
                if (!shop.model.readOnly) {
                    compare(hapticsSpy.signalArguments[0][0], !data.edit || data.right
                            ? Haptics.Confirm : Haptics.ToggleOn);
                }
                if (data.pullback) {
                    if (touch) {
                        touch.move(0, shop, endX, start.y).commit();
                    } else {
                        mouseMove(shop, endX, start.y, 0);
                    }
                }
            } finally {
                if (touch) {
                    touch.release(0, shop, endX, start.y).commit();
                } else {
                    mouseRelease(shop, endX, start.y, Qt.LeftButton, Qt.NoModifier, 0);
                }
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
                tryCompare(hapticsSpy, "count", 1);
                compare(hapticsSpy.signalArguments[0][0], Haptics.Confirm);
            } else {
                tryCompare(item, "checked", true, 2000);
                tryCompare(item, "x", 0);
                compare(shop.count, data.edit ? 3 : 2);
                tryCompare(hapticsSpy, "count", 1);
                compare(hapticsSpy.signalArguments[0][0], data.edit ? Haptics.ToggleOn :
                                                                      Haptics.Confirm);
            }
            wait(300);
            compare(hapticsSpy.count, 1);
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
            compare(hapticsSpy.count, 1);
        }

        function test_readonly_action_has_no_feedback_data() {
            return [
                        {
                            tag: "delete",
                            edit: true
                        },
                        {
                            tag: "check",
                            edit: false
                        }
                    ];
        }

        function test_repeated_held_swipes_data() {
            return [
                        {
                            tag: "shopping",
                            edit: false
                        },
                        {
                            tag: "editing",
                            edit: true
                        }
                    ];
        }

        function test_repeated_held_swipes(data) {
            shop.setEditMode(data.edit);
            Theme.swipeSensitivity = 0;
            const item = firstItem();
            const start = item.mapToItem(shop, item.width / 2, item.height / 2);
            const touch = touchEvent(shop);
            let x = start.x;
            touch.press(0, shop, x, start.y).commit();
            try {
                for (let leg = 0; leg < 3; ++leg) {
                    const end = start.x + item.width * (leg === 1 ? -0.3 : 0.3);
                    const from = x;
                    for (let step = 1; step <= 4; ++step) {
                        x = from + (end - from) * step / 4;
                        touch.move(0, shop, x, start.y).commit();
                        wait(30);
                    }
                    compare(hapticsSpy.count, leg + 1);
                    compare(hapticsSpy.signalArguments[leg][0], data.edit && leg === 1
                            ? Haptics.ToggleOn : Haptics.Confirm);
                    compare(item.checked, false);
                    if (leg === 0) {
                        x = start.x + item.width * 0.2;
                        touch.move(0, shop, x, start.y).commit();
                        wait(50);
                        verify(item.x > 0);
                        compare(hapticsSpy.count, 1);
                    }
                }
            } finally {
                touch.release(0, shop, x, start.y).commit();
            }
            // Each excursion is under half width, so this checks cues without committing an action.
            tryCompare(item, "x", 0);
            compare(item.checked, false);
            compare(shop.count, data.edit ? 3 : 2);
            compare(hapticsSpy.count, 3);
        }

        function test_readonly_action_has_no_feedback(data) {
            shop.setEditMode(data.edit);
            const item = firstItem();
            const count = shop.count;
            shop.model.readOnly = true;
            gesture(item, {
                        touch: true,
                        right: true,
                        fast: false
                    });
            wait(700);
            compare(shop.count, count);
            compare(item.checked, false);
            compare(hapticsSpy.count, 0);
        }

        name: "SwipeInteractions"
        when: windowShown

        SignalSpy {
            id: hapticsSpy

            target: Haptics
            signalName: "requested"
        }
    }
}
