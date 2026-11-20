import QShopper
import QtQuick
import QtTest

Item {
    width: 600
    height: 900

    TestCase {
        property var app
        property var view
        property var shop
        property var panel
        property var keyboardApi

        function editor() {
            shop.forceLayout();
            tryVerify(function () {
                return shop.itemAtIndex(shop.model.editorIndex) !== null;
            });
            const chooser = shop.itemAtIndex(shop.model.editorIndex);
            tryCompare(chooser, "x", 0);
            return chooser.item.contentItem;
        }

        function findKey(item, predicate) {
            if (item.visible && item.enabled && predicate(item)) {
                return item;
            }
            for (let child of item.children) {
                const found = findKey(child, predicate);
                if (found !== null) {
                    return found;
                }
            }
            return null;
        }

        function tapKey(code) {
            let key = null;
            tryVerify(function () {
                key = findKey(panel, function (item) {
                    return item.key === code;
                });
                return key !== null;
            });
            mouseClick(key, key.width / 2, key.height / 2);
        }

        function init() {
            failOnWarning(/.*Binding loop detected.*/);
            uiSetup.resetDatabase();
            Theme.activeList = "default";
            Theme.scale = 1;
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
            tryCompare(shop, "editMode", true);
            panel = findChild(app, "developmentKeyboard");
            verify(panel !== null);
            verify(panel.available);
            // Keep the keyboard-only test imports out of whole-source deployment scans.
            keyboardApi = Qt.createQmlObject(`
                import QtQuick
                import QtQuick.VirtualKeyboard
                import QtQuick.VirtualKeyboard.Settings
                QtObject {
                    readonly property int hideKeyType: QtVirtualKeyboard.KeyType.HideKeyboardKey
                    function setLocale() { VirtualKeyboardSettings.locale = "en_GB" }
                    function preedit(text) { InputContext.preeditText = text }
                    function commit() { InputContext.commit() }
                }`, panel);
            keyboardApi.setLocale();
            editor().forceActiveFocus();
            Qt.inputMethod.show();
            tryCompare(panel, "opened", true);
            wait(100);
        }

        function cleanup() {
            if (keyboardApi) {
                keyboardApi.preedit("");
            }
            Qt.inputMethod.hide();
            wait(100);
            if (app) {
                app.close();
                app.destroy();
            }
            wait(0);
            Theme.scale = 1;
        }

        function test_enter_keeps_keyboard_open_with_composed_input() {
            const field = editor();
            for (let code of [Qt.Key_M, Qt.Key_I, Qt.Key_L, Qt.Key_K])
                tapKey(code);
            tryVerify(function () {
                return (field.text + field.preeditText).toLowerCase() === "milk";
            });
            tapKey(Qt.Key_Return);
            tryCompare(shop.model, "count", 2);
            compare(editor(), field);
            tryCompare(field, "text", "");
            wait(200);
            verify(Qt.inputMethod.visible);
            verify(panel.opened);
            verify(field.activeFocus);
            keyboardApi.preedit("Bread");
            tryCompare(field, "preeditText", "Bread");
            keyboardApi.commit();
            tryCompare(field, "text", "Bread");
            tapKey(Qt.Key_Return);
            tryCompare(shop.model, "count", 3);
            compare(editor(), field);
            tryCompare(field, "text", "");
            wait(200);
            verify(Qt.inputMethod.visible);
            verify(panel.opened);
            shop.forceLayout();
            compare(shop.itemAtIndex(0).name.toLowerCase(), "milk");
            compare(shop.itemAtIndex(1).name, "Bread");
            tapKey(Qt.Key_Return);
            compare(shop.model.count, 3);
            verify(Qt.inputMethod.visible);
        }

        function test_mode_entry_waits_for_editor_tap_data() {
            return [
                        {
                            tag: "first_entry",
                            rounds: 1,
                            back: false
                        },
                        {
                            tag: "reentry_after_pull",
                            rounds: 2,
                            back: false
                        },
                        {
                            tag: "reentry_after_back",
                            rounds: 2,
                            back: true
                        }
                    ];
        }

        function test_mode_entry_waits_for_editor_tap(data) {
            // Restart with a saved, nonempty list, as in the phone report.
            shop.model.insert(0, "Original item");
            app.close();
            app.destroy();
            wait(0);
            const component = Qt.createComponent("qrc:/qt/qml/QShopper/main.qml");
            app = createTemporaryObject(component, null, {
                                            asynchronous: false
                                        });
            verify(app !== null);
            app.requestActivate();
            tryCompare(app, "active", true);
            view = app.contentItem.children[0].item;
            shop = view.contentItem;
            panel = findChild(app, "developmentKeyboard");
            compare(shop.editMode, false);
            app.height = Theme.pixels(250);
            const shortcut = findChild(view, "androidBackShortcut");
            shortcut.enabled = Qt.binding(function () {
                return view.backNavigationActive;
            });

            function pullToMode(mode) {
                // Let keyboard resizing finish before choosing the gesture coordinates.
                wait(300);
                tryCompare(shop, "moving", false);
                shop.positionViewAtBeginning();
                tryCompare(shop, "contentY", shop.originY);
                waitForRendering(shop);
                const x = shop.width / 2;
                const y = shop.height * 0.3;
                const distance = Theme.pixels(120);
                const touch = touchEvent(shop);
                touch.press(0, shop, x, y).commit();
                for (let step = 1; step <= 6; ++step) {
                    touch.move(0, shop, x, y + distance * step / 6).commit();
                    wait(30);
                }
                touch.release(0, shop, x, y + distance).commit();
                tryCompare(shop, "editMode", mode);
                tryCompare(shop, "moving", false);
                wait(500);
            }

            for (let round = 0; round < data.rounds; ++round) {
                pullToMode(true);
                const field = editor();
                if (round === data.rounds - 1) {
                    tryCompare(field, "activeFocus", false);
                    compare(field.focus, false);
                    verify(!Qt.inputMethod.visible);
                }
                mouseClick(field, field.width / 2, field.height / 2);
                tryCompare(field, "activeFocus", true);
                tryCompare(panel, "opened", true);
                field.text = "Unsubmitted draft";
                if (data.back) {
                    keyClick(Qt.Key_Back);
                    tryCompare(Qt.inputMethod, "visible", false);
                    keyClick(Qt.Key_Back);
                    tryCompare(shop, "editMode", false);
                } else {
                    pullToMode(false);
                }
                tryCompare(Qt.inputMethod, "visible", false);
                compare(shop.count, 1);
                compare(shop.model.data(shop.model.index(0, 0), Qt.DisplayRole), "Original item");
            }
        }

        function test_hide_button_and_reopen_preserve_window_and_input() {
            const field = editor();
            field.text = "Unfinished draft";
            const editorIndex = shop.model.editorIndex;
            const windowHeight = app.height;
            const reducedHeight = shop.height;
            const closeKey = findKey(panel, function (item) {
                return item.keyType === keyboardApi.hideKeyType;
            });
            verify(closeKey !== null);
            mouseClick(closeKey, closeKey.width / 2, closeKey.height / 2);
            tryCompare(Qt.inputMethod, "visible", false);
            tryCompare(field, "activeFocus", false);
            compare(field.text, "Unfinished draft");
            compare(shop.model.editorIndex, editorIndex);
            verify(shop.editMode);
            tryCompare(panel, "visible", false);
            compare(panel.occupiedHeight, 0);
            compare(app.height, windowHeight);
            verify(shop.height > reducedHeight);
            wait(200);
            verify(!Qt.inputMethod.visible);
            mouseClick(field, field.width / 2, field.height / 2);
            tryCompare(panel, "opened", true);
            verify(field.activeFocus);
            compare(field.text, "Unfinished draft");
            compare(app.height, windowHeight);
        }

        function test_clear_keeps_text_focus_and_keyboard_data() {
            return [
                        {
                            tag: "mouse_committed",
                            touch: false,
                            preedit: false
                        },
                        {
                            tag: "touch_committed",
                            touch: true,
                            preedit: false
                        },
                        {
                            tag: "mouse_preedit",
                            touch: false,
                            preedit: true
                        },
                        {
                            tag: "touch_preedit",
                            touch: true,
                            preedit: true
                        }
                    ];
        }

        function test_clear_keeps_text_focus_and_keyboard(data) {
            shop.model.insert(0, "Milk");
            shop.model.insert(shop.count, "Bread");
            const insertionIndex = shop.model.editorIndex;
            const field = editor();
            field.forceActiveFocus();
            Qt.inputMethod.show();
            tryCompare(field, "activeFocus", true);
            tryCompare(panel, "opened", true);
            const milkId = shop.model.data(shop.model.index(0, 0), Qt.UserRole + 1);
            const breadId = shop.model.data(shop.model.index(2, 0), Qt.UserRole + 1);
            for (let attempt = 0; attempt < 2; ++attempt) {
                if (data.preedit) {
                    const draft = "Discard " + attempt;
                    keyboardApi.preedit(draft);
                    tryCompare(field, "preeditText", draft);
                } else {
                    field.text = "Discard";
                    tryCompare(field, "text", "Discard");
                }
                const clear = findKey(field, function (item) {
                    return item.text === "\uf057" && typeof item.clicked === "function";
                });
                verify(clear !== null);
                if (data.touch) {
                    const touch = touchEvent(clear);
                    touch.press(0, clear, clear.width / 2, clear.height / 2).commit();
                    touch.release(0, clear, clear.width / 2, clear.height / 2).commit();
                } else {
                    mouseClick(clear, clear.width / 2, clear.height / 2);
                }
                tryCompare(field, "text", "");
                tryCompare(field, "preeditText", "");
                wait(300);
                verify(field.activeFocus, "Clear must retain the editor's text focus");
                verify(Qt.inputMethod.visible, "Clear must keep the keyboard open");
                verify(panel.opened);
                compare(shop.model.editorIndex, insertionIndex);
                compare(shop.count, 3);
            }
            // Continue from the keyboard without tapping or refocusing the editor.
            for (let code of [Qt.Key_E, Qt.Key_G, Qt.Key_G]) {
                tapKey(code);
            }
            tapKey(Qt.Key_Return);
            tryCompare(field, "text", "");
            compare(shop.count, 4);
            compare(shop.model.data(shop.model.index(insertionIndex, 0), Qt.DisplayRole).toLowerCase(
                        ), "egg");
            compare(shop.model.data(shop.model.index(0, 0), Qt.UserRole + 1), milkId);
            compare(shop.model.data(shop.model.index(3, 0), Qt.UserRole + 1), breadId);
            verify(field.activeFocus);
            verify(Qt.inputMethod.visible);
        }

        function test_zoom_and_drawer_dismissal() {
            const firstHeight = panel.height;
            compare(panel.scale, 1);
            if (previewExpected) {
                Theme.scale = 1.5;
                tryVerify(function () {
                    return panel.height > firstHeight;
                });
            }
            tryCompare(panel, "width", view.width);
            compare(shop.height, view.availableHeight);
            verify(shop.height < view.height);
            verify(Qt.inputMethod.visible);
            shop.openMenu();
            tryCompare(Qt.inputMethod, "visible", false);
            tryCompare(panel, "visible", false);
            for (let child of shop.data) {
                if (typeof child.close === "function" && child.contentItem) {
                    child.close();
                }
            }
            wait(300);
            mouseClick(editor(), editor().width / 2, editor().height / 2);
            tryCompare(panel, "opened", true);
        }

        function test_clear_does_not_reopen_hidden_keyboard() {
            const field = editor();
            field.text = "Discard";
            Qt.inputMethod.hide();
            tryCompare(Qt.inputMethod, "visible", false);
            const clear = findKey(field, function (item) {
                return item.text === "\uf057" && typeof item.clicked === "function";
            });
            verify(clear !== null);
            mouseClick(clear, clear.width / 2, clear.height / 2);
            tryCompare(field, "text", "");
            wait(300);
            verify(!field.activeFocus);
            verify(!Qt.inputMethod.visible, "Clear must not reopen a deliberately hidden keyboard");
        }

        function test_keyboard_dismissal_preserves_pending_replacement() {
            shop.model.insert(0, "Original item");
            shop.forceLayout();
            wait(800);
            const row = shop.itemAtIndex(0).item;
            const point = row.mapToItem(shop, row.width / 2, row.height / 2);
            const touch = touchEvent(shop);
            touch.press(0, shop, point.x, point.y).commit();
            touch.release(0, shop, point.x, point.y).commit();
            wait(50);
            touch.press(0, shop, point.x, point.y).commit();
            touch.release(0, shop, point.x, point.y).commit();
            const field = editor();
            tryCompare(field, "text", "Original item");
            tryCompare(Qt.inputMethod, "visible", true);
            field.text = "Replacement draft";
            const editorIndex = shop.model.editorIndex;
            const count = shop.count;
            Qt.inputMethod.hide();
            tryCompare(Qt.inputMethod, "visible", false);
            tryCompare(field, "activeFocus", false);
            compare(field.text, "Replacement draft");
            compare(shop.model.editorIndex, editorIndex);
            compare(shop.count, count);
            verify(shop.editMode);
            mouseClick(field, field.width / 2, field.height / 2);
            tryCompare(panel, "opened", true);
            verify(field.activeFocus);
            tapKey(Qt.Key_Return);
            tryCompare(field, "text", "");
            compare(shop.model.data(shop.model.index(0, 0), Qt.DisplayRole), "Replacement draft");
            compare(shop.count, 2);
            verify(Qt.inputMethod.visible);
        }

        function test_offscreen_editor_keeps_draft_focus_and_keyboard_data() {
            return [
                        {
                            tag: "40_items",
                            count: 40
                        },
                        {
                            tag: "200_items",
                            count: 200
                        }
                    ];
        }

        function test_offscreen_editor_keeps_draft_focus_and_keyboard(data) {
            for (let index = 0; index < data.count; ++index) {
                shop.model.insert(shop.count, "Long list " + index);
            }
            const field = editor();
            field.text = "Unsubmitted draft";
            wait(800);
            shop.positionViewAtEnd();
            shop.forceLayout();
            wait(500);
            verify(Qt.inputMethod.visible, "Scrolling must not dismiss the keyboard");
            verify(field !== null, "The editor must survive outside the delegate cache");
            verify(field.activeFocus);
            compare(field.text, "Unsubmitted draft");
            if (data.count > 40) {
                verify(shop.contentY > shop.cacheBuffer + Theme.pixels(9.27));
                // Ordinary rows still release; retaining the editor must not cache the list.
                compare(shop.itemAtIndex(1), null);
            }
            shop.positionViewAtBeginning();
            compare(editor(), field);
            tapKey(Qt.Key_Return);
            tryCompare(field, "text", "");
            compare(shop.model.data(shop.model.index(0, 0), Qt.DisplayRole), "Unsubmitted draft");
            compare(shop.count, data.count + 2);
            verify(Qt.inputMethod.visible);
        }

        function test_end_editor_remains_visible_when_keyboard_opens() {
            Qt.inputMethod.hide();
            tryCompare(Qt.inputMethod, "visible", false);
            for (let index = 0; index < 80; ++index) {
                shop.model.insert(shop.count, "Long list " + index);
            }
            shop.model.moveEditor(shop.count - 1);
            shop.positionViewAtEnd();
            const field = editor();
            wait(800);
            mouseClick(field, field.width / 2, field.height / 2);
            tryCompare(panel, "opened", true);
            tryVerify(function () {
                const bounds = field.mapToItem(shop, Qt.rect(0, 0, field.width, field.height));
                return bounds.y >= -1 && bounds.y + bounds.height <= shop.height + 1;
            }, 3000, "Active end editor must remain above the keyboard after viewport shrink");
            field.text = "Last item";
            tapKey(Qt.Key_Return);
            tryCompare(field, "text", "");
            compare(shop.count, 82);
            compare(shop.model.data(shop.model.index(80, 0), Qt.DisplayRole), "Last item");
            verify(Qt.inputMethod.visible);
        }

        function test_back_hides_keyboard_then_leaves_edit() {
            const hapticsSpy = Qt.createQmlObject('import QtTest; SignalSpy {}', app);
            hapticsSpy.target = Haptics;
            hapticsSpy.signalName = "requested";
            verify(hapticsSpy.valid);
            const field = editor();
            field.text = "unfinished";
            const shortcut = findChild(view, "androidBackShortcut");
            if (shortcut !== null) {
                shortcut.enabled = Qt.binding(function () {
                    return view.backNavigationActive;
                });
            }
            keyClick(Qt.Key_Back);
            tryCompare(Qt.inputMethod, "visible", false);
            tryCompare(field, "activeFocus", false);
            compare(shop.editMode, true);
            compare(field.text, "unfinished");
            compare(shop.count, 1);
            compare(hapticsSpy.count, 0);
            verify(app.visible);
            keyClick(Qt.Key_Back);
            tryCompare(shop, "editMode", false);
            compare(shop.count, 0);
            compare(hapticsSpy.count, 0);
            verify(app.visible);
        }

        name: "DevelopmentKeyboard"
        when: windowShown
    }
}
