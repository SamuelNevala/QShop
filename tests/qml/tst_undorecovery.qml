pragma ComponentBehavior: Bound

import QShopper
import QtQuick
import QtTest

Item {
    id: scene

    width: 600
    height: 700

    Binding {
        target: Theme
        property: "parent"
        value: scene
    }

    Component {
        id: undoBarComponent

        UndoBar {
            enabled: false
            width: Theme.pixels(60)
        }
    }

    Component {
        id: viewComponent

        View {
            width: 480
            height: 360
        }
    }

    TestCase {
        property var view
        property var shop

        function init() {
            failOnWarning(/.*Binding loop detected.*/);
            failOnWarning(/.*setPaused\(\) cannot be used when animation isn't running.*/);
            uiSetup.resetDatabase();
            Theme.activeList = "default";
            Theme.scale = 1;
            view = createTemporaryObject(viewComponent, scene);
            verify(view !== null);
            shop = view.contentItem;
            for (let index = 0; index < 30; ++index) {
                shop.model.insert(shop.count, "Item " + index);
            }
            shop.forceLayout();
            compare(shop.model.editorIndex, 0);
        }

        function names() {
            const result = [];
            for (let index = 0; index < shop.count; ++index) {
                if (index !== shop.model.editorIndex) {
                    result.push(shop.model.data(shop.model.index(index, 0), Qt.DisplayRole));
                }
            }
            return result;
        }

        function visibleRow(index) {
            shop.positionViewAtIndex(index, ListView.Center);
            shop.forceLayout();
            tryVerify(function () {
                return shop.itemAtIndex(index) !== null;
            });
            const chooser = shop.itemAtIndex(index);
            tryCompare(chooser, "x", 0);
            tryCompare(chooser.item, "x", 0);
            wait(500);
            return chooser.item;
        }

        function deleteRow(index) {
            const row = visibleRow(index);
            const start = row.mapToItem(shop, row.width * 0.1, row.height / 2);
            const count = shop.count;
            const touch = touchEvent(shop);
            touch.press(0, shop, start.x, start.y).commit();
            for (let step = 1; step <= 4; ++step) {
                touch.move(0, shop, start.x + row.width * 0.75 * step / 4, start.y).commit();
            }
            touch.release(0, shop, start.x + row.width * 0.75, start.y).commit();
            tryCompare(shop, "count", count - 1);
            tryCompare(shop.model, "canUndo", true);
            wait(500);
        }

        function undoBar() {
            const bar = findChild(view, "undoBar");
            verify(bar !== null, "Undo must be available outside the editor delegate");
            tryCompare(bar, "visible", true);
            return bar;
        }

        function undo(recoveryRemains = false) {
            const bar = undoBar();
            const action = findChild(bar, "undoAction");
            verify(action !== null);
            mouseClick(action, action.width / 2, action.height / 2);
            tryCompare(shop.model, "canUndo", recoveryRemains);
        }

        function test_post_reset_cleanup_undoes_one_swipe_at_a_time() {
            for (let index = 0; index < 3; ++index) {
                shop.model.setChecked(1, true);
            }
            shop.model.reset();
            const before = names();
            const identifiers = [];
            for (let index = 1; index < shop.count; ++index) {
                identifiers.push(shop.model.data(shop.model.index(index, 0), Qt.UserRole + 1));
            }
            deleteRow(1);
            deleteRow(1);
            deleteRow(1);
            compare(names(), before.slice(3));
            const bar = undoBar();
            const progress = findChild(bar, "undoCountdown");
            const expiry = findChild(bar, "undoExpiry");
            compare(bar.message, before[2] + " removed");
            undo(true);
            compare(names(), before.slice(2), "Correct only the last mistake");
            compare(bar.message, before[1] + " removed");
            compare(expiry.running, true);
            verify(progress.value > .95, "The previous action receives a fresh recovery window");
            undo(true);
            compare(names(), before.slice(1));
            compare(bar.message, before[0] + " removed");
            undo();
            compare(names(), before);
            for (let index = 1; index < shop.count; ++index) {
                compare(shop.model.data(shop.model.index(index, 0), Qt.UserRole + 1),
                        identifiers[index - 1]);
            }
        }

        function test_near_expiry_undo_restarts_previous_action() {
            const before = names();
            deleteRow(1);
            deleteRow(1);
            const bar = undoBar();
            const progress = findChild(bar, "undoCountdown");
            const expiry = findChild(bar, "undoExpiry");
            expiry.duration = 2000;
            bar.restart();
            tryVerify(function () {
                return progress.value < .2;
            }, 2500);
            undo(true);
            compare(names(), before.slice(1));
            verify(progress.value > .9, "Earlier deletion must get a full new countdown");
            wait(600);
            compare(shop.model.canUndo, true, "Earlier action survives the original expiry");
            undo();
            compare(names(), before);
            tryCompare(expiry, "running", false);
        }

        function test_expiry_discards_all_pending_actions() {
            deleteRow(1);
            deleteRow(1);
            const remaining = names();
            const bar = undoBar();
            const expiry = findChild(bar, "undoExpiry");
            expiry.duration = 200;
            bar.restart();
            tryCompare(shop.model, "canUndo", false);
            tryCompare(bar, "visible", false);
            shop.model.undo();
            compare(names(), remaining);
        }

        function test_offscreen_editor_has_reachable_undo() {
            const before = names();
            const removedId = shop.model.data(shop.model.index(20, 0), Qt.UserRole + 1);
            deleteRow(20);
            verify(shop.itemAtIndex(0) === null || shop.itemAtIndex(0).y - shop.contentY < 0);
            const bar = undoBar();
            const point = bar.parent.mapToItem(view, bar.x, bar.y);
            verify(point.y >= 0 && point.y + bar.height <= view.height);
            undo();
            compare(names(), before);
            compare(shop.model.data(shop.model.index(20, 0), Qt.UserRole + 1), removedId);
        }

        function test_scroll_keeps_recovery() {
            const before = names();
            deleteRow(20);
            const oldY = shop.contentY;
            const touch = touchEvent(shop);
            touch.press(0, shop, shop.width / 2, shop.height * 0.65).commit();
            for (let step = 1; step <= 5; ++step) {
                touch.move(0, shop, shop.width / 2, shop.height * (0.65 - step * 0.08)).commit();
                wait(20);
            }
            touch.release(0, shop, shop.width / 2, shop.height * 0.25).commit();
            tryVerify(function () {
                return shop.contentY !== oldY;
            });
            compare(shop.model.canUndo, true);
            undo();
            compare(names(), before);
        }

        function test_whole_bar_undo_data() {
            return [
                        {
                            tag: "message",
                            fraction: 0.1
                        },
                        {
                            tag: "middle",
                            fraction: 0.5
                        },
                        {
                            tag: "icon",
                            fraction: 0.92
                        }
                    ];
        }

        function test_whole_bar_undo(data) {
            const before = names();
            deleteRow(20);
            const bar = undoBar();
            tryCompare(bar, "opened", true);
            const point = bar.parent.mapToItem(view, bar.x + bar.width * data.fraction, bar.y
                                               + bar.height / 2);
            mouseClick(view, point.x, point.y);
            tryCompare(shop.model, "canUndo", false);
            compare(names(), before);
        }

        function test_editor_movement_and_submission_keep_recovery() {
            deleteRow(1);
            const row = visibleRow(3);
            mouseClick(row, row.width / 2, row.height / 2);
            tryVerify(function () {
                return shop.model.editorIndex !== 0;
            });
            compare(shop.model.canUndo, true);
            const field = visibleRow(shop.model.editorIndex).contentItem;
            field.forceActiveFocus();
            keyClick(Qt.Key_N);
            keyClick(Qt.Key_E);
            keyClick(Qt.Key_W);
            keyClick(Qt.Key_Return);
            tryCompare(field, "text", "");
            compare(shop.model.canUndo, true);
            undo();
            verify(names().includes("Item 0"));
            verify(names().includes("new"));
        }

        function test_disabled_undo_bar_creation_is_warning_free() {
            const bar = createTemporaryObject(undoBarComponent, scene);
            verify(bar !== null);
            const expiry = findChild(bar, "undoExpiry");
            compare(expiry.running, false);
            bar.enabled = true;
            bar.enabled = false;
            compare(expiry.running, false);
        }

        function test_idle_drawer_does_not_pause_animation() {
            const bar = findChild(view, "undoBar");
            const expiry = findChild(bar, "undoExpiry");
            const drawer = shop.data.find(item => typeof item.open === "function"
                                                  && item.contentItem);
            verify(drawer !== undefined);
            compare(expiry.running, false);
            drawer.open();
            tryCompare(drawer, "opened", true);
            compare(expiry.running, false);
            drawer.close();
            tryCompare(drawer, "visible", false);

            shop.model.remove(1);
            tryCompare(expiry, "running", true);
            drawer.open();
            tryCompare(drawer, "opened", true);
            tryCompare(expiry, "paused", true);
            shop.model.clearUndoStack();
            tryCompare(bar, "visible", false);
            tryCompare(expiry, "running", false);
            drawer.close();
            tryCompare(drawer, "visible", false);
            drawer.open();
            tryCompare(drawer, "opened", true);
            compare(expiry.running, false);
        }

        name: "UndoRecovery"
        when: windowShown
    }
}
