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

        function test_hide_button_and_reopen_preserve_window_and_input() {
            const field = editor();
            const windowHeight = app.height;
            const reducedHeight = shop.height;
            const closeKey = findKey(panel, function (item) {
                return item.keyType === keyboardApi.hideKeyType;
            });
            verify(closeKey !== null);
            mouseClick(closeKey, closeKey.width / 2, closeKey.height / 2);
            tryCompare(Qt.inputMethod, "visible", false);
            tryCompare(panel, "visible", false);
            compare(panel.occupiedHeight, 0);
            compare(app.height, windowHeight);
            verify(shop.height > reducedHeight);
            wait(200);
            verify(!Qt.inputMethod.visible);
            mouseClick(field, field.width / 2, field.height / 2);
            tryCompare(panel, "opened", true);
            compare(app.height, windowHeight);
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
            compare(shop.editMode, true);
            compare(field.text, "unfinished");
            compare(shop.count, 1);
            verify(app.visible);
            keyClick(Qt.Key_Back);
            tryCompare(shop, "editMode", false);
            compare(shop.count, 0);
            verify(app.visible);
        }

        name: "DevelopmentKeyboard"
        when: windowShown
    }
}
