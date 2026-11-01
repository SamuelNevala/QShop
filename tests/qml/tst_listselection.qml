import QShopper
import QtQuick
import QtTest

Item {
    width: 600
    height: 900

    Component {
        id: catalogComponent

        Model {}
    }

    Component {
        id: itemsComponent

        Model {}
    }

    TestCase {
        property var app
        property var shop
        property var drawer
        readonly property string defaultId: "11111111-1111-1111-1111-111111111111"

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
        }

        function init() {
            uiSetup.resetDatabase();
            Theme.activeList = "default";
            Theme.scale = 1;
            openApp();
        }

        function cleanup() {
            if (app) {
                app.close();
                app.destroy();
            }
            wait(0);
        }

        function openSelector() {
            shop.setEditMode(true);
            shop.forceLayout();
            shop.positionViewAtIndex(shop.model.editorIndex, ListView.Contain);
            tryVerify(function () {
                return shop.itemAtIndex(shop.model.editorIndex) !== null;
            });
            const chooser = shop.itemAtIndex(shop.model.editorIndex);
            tryCompare(chooser, "x", 0);
            const field = chooser.item.contentItem;
            mouseClick(field, field.height / 2, field.height / 2);
            tryCompare(drawer, "opened", true);
            drawer.contentItem.positionViewAtBeginning();
            drawer.contentItem.forceLayout();
            const combo = drawer.contentItem.itemAtIndex(0);
            verify(combo !== null);
            return combo;
        }

        function verifySelection(combo, name, id) {
            tryCompare(combo, "currentText", name);
            compare(combo.displayText, name);
            compare(combo.contentItem.text, name);
            compare(combo.currentValue, id);
            verify(combo.currentIndex >= 0);
        }

        function choose(combo, name) {
            const index = combo.find(name);
            verify(index >= 0);
            const id = combo.valueAt(index);
            mouseClick(combo, combo.width / 2, combo.height * 0.7);
            tryCompare(combo.popup, "opened", true);
            const options = combo.popup.contentItem;
            options.positionViewAtIndex(index, ListView.Contain);
            options.forceLayout();
            const row = options.itemAtIndex(index);
            verify(row !== null);
            mouseClick(row, row.width / 2, row.height / 2);
            tryCompare(drawer, "visible", false);
            tryCompare(Theme, "activeList", id);
            return id;
        }

        function verifyItems(expected) {
            shop.setEditMode(false);
            tryCompare(shop, "count", expected.length);
            shop.forceLayout();
            for (let i = 0; i < expected.length; ++i) {
                const row = shop.itemAtIndex(i);
                verify(row !== null);
                compare(row.name, expected[i]);
            }
        }

        function test_fresh_default_is_selected() {
            compare(shop.model.activeList, defaultId);
            verifySelection(openSelector(), "default", defaultId);
            tryVerify(function () {
                return uiSetup.savedSetting("activeList") === defaultId;
            });
            compare(uiSetup.restoredActiveList(), defaultId);
        }

        function test_switch_reopen_and_restore() {
            const catalog = createTemporaryObject(catalogComponent, parent);
            catalog.insert(1, "Weekly");
            shop.model.insert(0, "Milk");
            const combo = openSelector();
            const weeklyId = combo.valueAt(combo.find("Weekly"));
            const items = createTemporaryObject(itemsComponent, parent, {
                                                    activeList: weeklyId
                                                });
            items.insert(0, "Bread");
            choose(combo, "Weekly");
            verifyItems(["Bread"]);
            verifySelection(openSelector(), "Weekly", weeklyId);
            drawer.close();
            tryCompare(drawer, "visible", false);
            tryVerify(function () {
                return uiSetup.savedSetting("activeList") === weeklyId;
            });
            compare(uiSetup.restoredActiveList(), weeklyId);
            app.close();
            app.destroy();
            wait(0);
            openApp();
            verifyItems(["Bread"]);
            const reopened = openSelector();
            verifySelection(reopened, "Weekly", weeklyId);
            choose(reopened, "default");
            verifyItems(["Milk"]);
            verifySelection(openSelector(), "default", defaultId);
        }

        function test_catalog_entry_stays_selected() {
            const combo = openSelector();
            const id = choose(combo, "lists");
            compare(shop.model.activeList, "lists");
            verifySelection(openSelector(), "lists", id);
            choose(drawer.contentItem.itemAtIndex(0), "default");
            compare(shop.model.activeList, defaultId);
        }

        function test_selector_refresh_keeps_active_list() {
            const combo = openSelector();
            verifySelection(combo, "default", defaultId);
            drawer.close();
            tryCompare(drawer, "visible", false);
            const catalog = createTemporaryObject(catalogComponent, parent);
            catalog.insert(1, "Weekly");
            const reopened = openSelector();
            tryCompare(reopened, "count", 3);
            verifySelection(reopened, "default", defaultId);
        }

        name: "ListSelection"
        when: windowShown
    }
}
