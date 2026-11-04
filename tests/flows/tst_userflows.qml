import QShopper
import QtQuick
import QtQuick.Controls.Material
import QtTest

Item {
    width: 600
    height: 900

    TestCase {
        property var app
        property var shop
        property var drawer

        function init() {
            failOnWarning(/.*Binding loop detected.*/);
            uiSetup.resetDatabase();
            Theme.activeList = "default";
            Theme.scale = 1;
            Theme.theme = Material.Dark;
            Theme.accent = Material.Green;
            Theme.primary = Material.Indigo;
            Theme.swipeSensitivity = 1;
            openApp();
            // Fixture setup only; every action under test uses actual controls.
            for (const name of ["milk", "bread", "cheese"]) {
                shop.model.insert(shop.model.editorIndex, name);
            }
            verifyNames(["milk", "bread", "cheese"]);
        }

        function openApp() {
            const component = Qt.createComponent("qrc:/qt/qml/QShopper/main.qml");
            compare(component.status, Component.Ready, component.errorString());
            app = createTemporaryObject(component, null, {
                                            asynchronous: false
                                        });
            verify(app !== null);
            tryCompare(app, "visible", true);
            app.requestActivate();
            tryCompare(app, "active", true);
            shop = app.contentItem.children[0].item.contentItem;
            drawer = null;
            for (const child of shop.data) {
                if (typeof child.open === "function" && child.contentItem) {
                    drawer = child;
                }
            }
            verify(drawer !== null);
            Qt.inputMethod.hide();
        }

        function cleanup() {
            Qt.inputMethod.hide();
            if (app) {
                app.close();
                app.destroy();
            }
            wait(0);
        }

        function names() {
            shop.forceLayout();
            const result = [];
            for (let index = 0; index < shop.count; ++index) {
                const row = shop.itemAtIndex(index);
                if (row && !row.editor) {
                    result.push(row.name);
                }
            }
            return result;
        }

        function verifyNames(expected) {
            try {
                tryVerify(function () {
                    return JSON.stringify(names()) === JSON.stringify(expected);
                });
            } catch (error) {
                console.log("Expected", JSON.stringify(expected), "visible", JSON.stringify(names()),
                            "count", shop.count, "editor", shop.model.editorIndex, "undo",
                            shop.model.canUndo);
                throw error;
            }
        }

        function rowNamed(name) {
            settle();
            let row = null;
            tryVerify(function () {
                shop.forceLayout();
                for (let index = 0; index < shop.count; ++index) {
                    const candidate = shop.itemAtIndex(index);
                    if (candidate && candidate.name === name && !candidate.editor) {
                        row = candidate;
                    }
                }
                return row !== null;
            });
            tryCompare(row, "x", 0);
            tryCompare(row, "y", row.index * row.height);
            tryCompare(row.item, "x", 0);
            return row.item;
        }

        function editor() {
            settle();
            shop.forceLayout();
            tryVerify(function () {
                return shop.itemAtIndex(shop.model.editorIndex) !== null;
            });
            const row = shop.itemAtIndex(shop.model.editorIndex);
            tryCompare(row, "x", 0);
            tryCompare(row, "y", row.index * row.height);
            return row.item.contentItem;
        }

        function settle() {
            shop.forceLayout();
            tryVerify(function () {
                const delegates = shop.contentItem.children.filter(function (item) {
                    return item instanceof DelegateChoser;
                });
                if (delegates.length !== shop.count || shop.moving) {
                    return false;
                }
                for (let index = 0; index < shop.count; ++index) {
                    const row = shop.itemAtIndex(index);
                    if (!row || !row.item || row.x !== 0 || row.item.x !== 0 || Math.abs(row.y
                                                                                         - index * row.height)
                            > 0.01) {
                        return false;
                    }
                }
                return true;
            });
        }

        function type(text, replace = false) {
            app.requestActivate();
            tryCompare(app, "active", true);
            const field = editor();
            waitForRendering(field);
            mouseClick(field, field.width / 2, field.height / 2);
            tryCompare(field, "activeFocus", true);
            if (replace) {
                keyClick(Qt.Key_A, Qt.ControlModifier);
            }
            for (const character of text) {
                keyClick(character.toUpperCase().charCodeAt(0));
            }
            compare(field.text, text);
        }

        function submit(text, replace = false) {
            type(text, replace);
            keyClick(Qt.Key_Return);
            tryCompare(editor(), "text", "");
        }

        function swipe(name, right = false) {
            const item = rowNamed(name);
            const point = item.mapToItem(shop, item.width * (right ? 0.1 : 0.9), item.height / 2);
            const sign = right ? 1 : -1;
            const touch = touchEvent(shop);
            touch.press(0, shop, point.x, point.y).commit();
            for (let step = 1; step <= 3; ++step) {
                touch.move(0, shop, point.x + sign * item.width * 0.75 * step / 3, point.y).commit(
                            );
            }
            touch.release(0, shop, point.x + sign * item.width * 0.75, point.y).commit();
        }

        function findControl(item, predicate) {
            if (predicate(item)) {
                return item;
            }
            for (const child of item.children) {
                const found = findControl(child, predicate);
                if (found) {
                    return found;
                }
            }
            return null;
        }

        function openDrawer() {
            const field = editor();
            mouseClick(field, field.height / 2, field.height / 2);
            tryCompare(drawer, "opened", true);
        }

        function menuSection(index) {
            const list = drawer.contentItem;
            list.positionViewAtIndex(index, ListView.Contain);
            list.forceLayout();
            tryVerify(function () {
                return list.itemAtIndex(index) !== null;
            });
            return list.itemAtIndex(index);
        }

        function menuAction(text) {
            openDrawer();
            const button = findControl(menuSection(1), function (item) {
                return item.text === text && typeof item.clicked === "function";
            });
            verify(button !== null);
            mouseClick(button, button.width / 2, button.height / 2);
            tryCompare(drawer, "visible", false);
        }

        function undo(touchInput = false) {
            const icon = findControl(app.contentItem, function (item) {
                return item.objectName === "undoAction";
            });
            verify(icon !== null);
            tryCompare(icon, "enabled", true);
            waitForRendering(icon);
            if (touchInput) {
                const touch = touchEvent(icon);
                touch.press(0, icon, icon.width / 2, icon.height / 2).commit();
                touch.release(0, icon, icon.width / 2, icon.height / 2).commit();
            } else {
                mouseClick(icon, icon.width / 2, icon.height / 2);
            }
            tryCompare(shop.model, "canUndo", false);
        }

        function choose(combo, index) {
            mouseClick(combo, combo.width / 2, combo.height * 0.7);
            tryCompare(combo.popup, "opened", true);
            const options = combo.popup.contentItem;
            options.positionViewAtIndex(index, ListView.Contain);
            options.forceLayout();
            const row = options.itemAtIndex(index);
            verify(row !== null);
            mouseClick(row, row.width / 2, row.height / 2);
            tryCompare(combo.popup, "visible", false);
            compare(combo.currentIndex, index);
        }

        function selectList(name) {
            openDrawer();
            const combo = menuSection(0);
            const index = combo.find(name);
            verify(index >= 0, "Missing list " + name);
            const id = combo.valueAt(index);
            choose(combo, index);
            tryCompare(drawer, "visible", false);
            tryCompare(Theme, "activeList", id);
            return id;
        }

        function doubleTap(name) {
            const row = rowNamed(name);
            const point = row.mapToItem(shop, row.width / 2, row.height / 2);
            const touch = touchEvent(shop);
            touch.press(0, shop, point.x, point.y).commit();
            touch.release(0, shop, point.x, point.y).commit();
            wait(50);
            touch.press(0, shop, point.x, point.y).commit();
            touch.release(0, shop, point.x, point.y).commit();
        }

        function test_insert_edit_and_clear_through_controls() {
            const bread = rowNamed("bread");
            mouseClick(bread, bread.width / 2, bread.height / 2);
            // A single tap places the editor after the tapped row.
            tryCompare(shop.model, "editorIndex", 2);
            submit("butter");
            verifyNames(["milk", "bread", "butter", "cheese"]);
            doubleTap("bread");
            tryCompare(editor(), "text", "bread");
            submit("oats", true);
            verifyNames(["milk", "oats", "butter", "cheese"]);
            type("discard");
            const field = editor();
            mouseClick(field, field.width - field.height / 2, field.height / 2);
            tryCompare(field, "text", "");
            keyClick(Qt.Key_Return);
            verifyNames(["milk", "oats", "butter", "cheese"]);
            app.close();
            app.destroy();
            wait(0);
            openApp();
            verifyNames(["milk", "oats", "butter", "cheese"]);
        }

        function test_delete_and_undo_icon() {
            swipe("bread", true);
            verifyNames(["milk", "cheese"]);
            undo();
            verifyNames(["milk", "bread", "cheese"]);
        }

        function test_drawer_removal_data() {
            return [
                        {
                            tag: "checked",
                            text: "Remove\nchecked",
                            remaining: ["bread"]
                        },
                        {
                            tag: "all_touch",
                            text: "Clear\nlist",
                            remaining: [],
                            touch: true
                        },
                        {
                            tag: "all_mouse",
                            text: "Clear\nlist",
                            remaining: []
                        }
                    ];
        }

        function test_drawer_removal(data) {
            swipe("milk");
            tryCompare(rowNamed("milk"), "checked", true);
            swipe("cheese");
            verifyNames(["bread", "cheese", "milk"]);
            menuAction(data.text);
            verifyNames(data.remaining);
            undo(data.touch === true);
            verifyNames(["bread", "cheese", "milk"]);
            compare(rowNamed("bread").checked, false);
            compare(rowNamed("cheese").checked, true);
            compare(rowNamed("milk").checked, true);
        }

        function test_remove_checked_without_checks_is_noop() {
            menuAction("Remove\nchecked");
            verifyNames(["milk", "bread", "cheese"]);
            compare(shop.model.canUndo, false);
        }

        function test_drawer_and_popup_dismissal_preserve_draft() {
            type("unfinished");
            openDrawer();
            const combo = menuSection(0);
            const original = combo.currentValue;
            mouseClick(combo, combo.width / 2, combo.height * 0.7);
            tryCompare(combo.popup, "opened", true);
            keyClick(Qt.Key_Escape);
            tryCompare(combo.popup, "visible", false);
            compare(combo.currentValue, original);
            verify(drawer.opened);
            keyClick(Qt.Key_Escape);
            tryCompare(drawer, "visible", false);
            compare(editor().text, "unfinished");
            const position = shop.model.editorIndex;
            openDrawer();
            mouseClick(app.contentItem, app.width - 2, app.height / 2);
            tryCompare(drawer, "visible", false);
            compare(editor().text, "unfinished");
            compare(shop.model.editorIndex, position);
            verifyNames(["milk", "bread", "cheese"]);
        }

        function test_correction_data() {
            return [
                        {
                            tag: "left",
                            right: false
                        },
                        {
                            tag: "right",
                            right: true
                        }
                    ];
        }

        function test_correction(data) {
            // Shopping-mode fixture; pull navigation is covered separately.
            shop.setEditMode(false);
            swipe("milk");
            tryCompare(rowNamed("milk"), "checked", true);
            swipe("bread");
            verifyNames(["cheese", "bread", "milk"]);
            swipe("bread", data.right);
            verifyNames(["bread", "cheese", "milk"]);
            compare(rowNamed("bread").checked, false);
            compare(rowNamed("milk").checked, true);
        }

        function test_catalog_create_rename_delete_undo() {
            selectList("lists");
            submit("weekly");
            const weekly = selectList("weekly");
            submit("eggs");
            verifyNames(["eggs"]);
            selectList("lists");
            doubleTap("weekly");
            tryCompare(editor(), "text", "weekly");
            submit("weekend", true);
            compare(selectList("weekend"), weekly);
            verifyNames(["eggs"]);
            selectList("lists");
            const catalogOrder = names();
            swipe("weekend", true);
            verifyNames(["default"]);
            undo();
            verifyNames(catalogOrder);
            compare(selectList("weekend"), weekly);
            verifyNames(["eggs"]);
            selectList("default");
            verifyNames(["milk", "bread", "cheese"]);
        }

        function test_undo_expires() {
            swipe("bread", true);
            verifyNames(["milk", "cheese"]);
            tryCompare(shop.model, "canUndo", true);
            const started = Date.now();
            tryCompare(shop.model, "canUndo", false, 17000);
            verify(Date.now() - started >= 14000, "Undo must not expire early without user input");
            openDrawer();
            mouseClick(app.contentItem, app.width - 2, app.height / 2);
            tryCompare(drawer, "visible", false);
            verifyNames(["milk", "cheese"]);
        }

        function test_other_interaction_preserves_undo() {
            swipe("bread", true);
            verifyNames(["milk", "cheese"]);
            tryCompare(shop.model, "canUndo", true);
            const row = rowNamed("cheese");
            mouseClick(row, row.width / 2, row.height / 2);
            compare(shop.model.canUndo, true);
            verifyNames(["milk", "cheese"]);
            undo();
            verifyNames(["milk", "bread", "cheese"]);
        }

        function test_shopping_taps_are_not_checks() {
            shop.setEditMode(false);
            const row = rowNamed("milk");
            mouseClick(row, row.width / 2, row.height / 2);
            wait(500);
            compare(row.checked, false);
            doubleTap("milk");
            wait(500);
            compare(row.checked, false);
            compare(shop.editMode, false);
            verifyNames(["milk", "bread", "cheese"]);
        }

        function test_checked_row_does_not_reorder() {
            swipe("milk");
            const row = rowNamed("milk");
            tryCompare(row, "checked", true);
            const insertion = shop.model.editorIndex;
            mouseClick(row, row.width / 2, row.height / 2);
            wait(500);
            compare(shop.model.editorIndex, insertion);
            const originalParent = row.parent;
            const point = row.mapToItem(shop, row.width / 2, row.height / 2);
            const touch = touchEvent(shop);
            touch.press(0, shop, point.x, point.y).commit();
            try {
                wait(1100);
                compare(row.state, "");
                compare(row.parent, originalParent);
            } finally {
                touch.release(0, shop, point.x, point.y).commit();
            }
            verifyNames(["bread", "cheese", "milk"]);
        }

        function test_reorder_drop_persists() {
            const row = rowNamed("milk");
            const destination = rowNamed("cheese");
            const start = row.mapToItem(shop, row.width / 2, row.height / 2);
            const end = destination.mapToItem(shop, destination.width / 2, destination.height / 2);
            const touch = touchEvent(shop);
            touch.press(0, shop, start.x, start.y).commit();
            try {
                tryCompare(row, "state", "drag", 2000);
                for (let step = 1; step <= 6; ++step) {
                    touch.move(0, shop, start.x, start.y + (end.y - start.y) * step / 6).commit();
                    wait(50);
                }
            } finally {
                touch.release(0, shop, end.x, end.y).commit();
            }
            tryCompare(row, "state", "");
            verifyNames(["bread", "cheese", "milk"]);
            app.close();
            app.destroy();
            wait(0);
            openApp();
            verifyNames(["bread", "cheese", "milk"]);
        }

        function test_settings_through_controls() {
            openDrawer();
            for (const theme of [
                     {
                         name: "Light",
                         value: Material.Light
                     },
                     {
                         name: "Dark",
                         value: Material.Dark
                     },
                     {
                         name: "System",
                         value: Material.System
                     }
                 ]) {
                const button = findControl(menuSection(2), function (item) {
                    return item.text === theme.name && typeof item.clicked === "function";
                });
                verify(button !== null);
                mouseClick(button, button.width / 2, button.height / 2);
                tryCompare(Theme, "theme", theme.value);
                verify(button.checked);
                tryVerify(function () {
                    return uiSetup.savedSetting("theme") === theme.value;
                });
            }
            for (const setting of [
                     {
                         index: 3,
                         key: "accent"
                     },
                     {
                         index: 4,
                         key: "primary"
                     }
                 ]) {
                const combo = menuSection(setting.index);
                const value = combo.valueAt(2);
                choose(combo, 2);
                compare(Theme[setting.key], value);
                tryVerify(function () {
                    return uiSetup.savedSetting(setting.key) === value;
                });
            }
            const slider = findControl(menuSection(5), function (item) {
                return item.from === 0.2 && item.to === 3;
            });
            verify(slider !== null);
            mousePress(slider.handle, slider.handle.width / 2, slider.handle.height / 2);
            const x = slider.width - slider.rightPadding - slider.handle.width / 2;
            mouseMove(slider, x, slider.height / 2, 30);
            mouseRelease(slider, x, slider.height / 2);
            tryCompare(Theme, "swipeSensitivity", 3);
            tryVerify(function () {
                return uiSetup.savedSetting("swipeSensitivity") === 3;
            });
            mouseClick(app.contentItem, app.width - 2, app.height / 2);
            tryCompare(drawer, "visible", false);
            verifyNames(["milk", "bread", "cheese"]);
        }

        function test_mode_pull_threshold() {
            // Leave enough blank space for a full resisted pull on desktop.
            app.height = Theme.pixels(250);
            waitForRendering(shop);
            function pull(millimeters) {
                tryCompare(shop, "moving", false);
                const x = shop.width / 2;
                const start = shop.height * 0.3;
                const distance = Theme.pixels(millimeters);
                const touch = touchEvent(shop);
                const pulley = findControl(shop, function (item) {
                    return item instanceof Pulley;
                });
                touch.press(0, shop, x, start).commit();
                for (let step = 1; step <= 6; ++step) {
                    wait(30);
                    touch.move(0, shop, x, start + distance * step / 6).commit();
                }
                wait(50);
                if (millimeters > 30) {
                    verify(pulley.height >= pulley.treshold, JSON.stringify({
                                                                                height: shop.height,
                                                                                start: start,
                                                                                distance: distance,
                                                                                contentY: shop.contentY,
                                                                                pulley: pulley.height,
                                                                                threshold:
                                                                                pulley.treshold
                                                                            }));
                }
                touch.release(0, shop, x, start + distance).commit();
                tryCompare(shop, "moving", false);
                // The pulley defers mode changes by 450 ms after dragEnded.
                wait(500);
            }
            pull(10);
            compare(shop.editMode, true);
            pull(120);
            tryCompare(shop, "editMode", false);
            verifyNames(["milk", "bread", "cheese"]);
            pull(120);
            tryCompare(shop, "editMode", true);
            pull(10);
            compare(shop.editMode, true);
            verifyNames(["milk", "bread", "cheese"]);
        }

        name: "UserFlows"
        when: windowShown
    }
}
