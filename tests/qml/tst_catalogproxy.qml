import QShopper
import QtQuick
import QtTest

Item {
    id: scene

    width: 600
    height: 900

    Binding {
        target: Theme
        property: "parent"
        value: scene
    }

    Component {
        id: viewComponent

        View {
            width: scene.width
            height: scene.height
        }
    }

    Component {
        id: catalogComponent

        Model {}
    }

    TestCase {
        property var view
        property var shop
        property var catalog
        property string originalLocale

        function init() {
            // DEV-001 identifies the separate PopupList override warning as
            // upstream Qt; keep binding-loop failures distinct from it.
            failOnWarning(/.*Binding loop detected.*/);
            originalLocale = uiSetup.exchangeLocale("C");
            uiSetup.resetDatabase();
            Theme.scale = 1;
            Theme.activeList = "default";
            catalog = createTemporaryObject(catalogComponent, scene);
            verify(catalog !== null);
            view = createTemporaryObject(viewComponent, scene);
            verify(view !== null);
            shop = view.contentItem;
            shop.model.insert(0, "Milk");
            shop.model.insert(1, "Bread");
            shop.setEditMode(false);
        }

        function cleanup() {
            uiSetup.exchangeLocale(originalLocale);
        }

        function insert(name) {
            const row = catalog.rowCount();
            catalog.insert(row, name);
            return catalog.data(catalog.index(row, 0), Qt.UserRole + 1);
        }

        function sourceRow(id) {
            for (let row = 0; row < catalog.rowCount(); ++row) {
                if (catalog.data(catalog.index(row, 0), Qt.UserRole + 1) === id) {
                    return row;
                }
            }
            fail("Missing source ID " + id);
        }

        function selector() {
            shop.openMenu();
            let drawer = null;
            for (const child of shop.data) {
                if (typeof child.open === "function" && child.contentItem) {
                    drawer = child;
                }
            }
            verify(drawer !== null);
            tryCompare(drawer, "opened", true);
            const menu = drawer.contentItem;
            menu.positionViewAtBeginning();
            menu.forceLayout();
            tryVerify(function () {
                return menu.itemAtIndex(0) !== null;
            });
            return menu.itemAtIndex(0);
        }

        function names(combo) {
            const result = [];
            for (let row = 0; row < combo.count; ++row) {
                result.push(combo.textAt(row));
            }
            return result;
        }

        function test_order_and_filter_data() {
            return [
                        {
                            tag: "C",
                            locale: "C"
                        },
                        {
                            tag: "Finnish",
                            locale: "fi_FI"
                        },
                        {
                            tag: "Swedish",
                            locale: "sv_SE"
                        }
                    ];
        }

        function test_order_and_filter(data) {
            uiSetup.exchangeLocale(data.locale);
            const ids = [];
            for (const name of ["zeta", "alpha", "Beta", "Alpha", "alpha", "Åland", "Äpple",
                                "Örebro", "10", "2", "äther", "éclair", "Zulu"]) {
                ids.push(insert(name));
            }
            const hidden = insert("Hidden");
            catalog.setChecked(sourceRow(hidden), true);
            const combo = selector();
            tryCompare(combo, "count", 15);
            compare(names(combo), ["10", "2", "Alpha", "Beta", "Zulu", "alpha", "alpha", "default", "lists",
                                   "zeta", "Äpple", "Åland", "Örebro", "äther", "éclair"]);
            compare(combo.valueAt(5), ids[1]);
            compare(combo.valueAt(6), ids[4]);
            compare(combo.find("Hidden"), -1);
            compare(combo.currentText, "default");
            compare(combo.currentValue, shop.model.activeList);
            compare(shop.model.data(shop.model.index(0, 0)), "Milk");
            compare(shop.model.data(shop.model.index(1, 0)), "Bread");
        }

        function test_dynamic_changes_keep_uuid_selection() {
            const first = insert("First");
            const second = insert("Second");
            const combo = selector();
            const selected = combo.currentValue;
            // Use the same production roles/configuration with a writable source
            // to exercise live insert/remove/data notifications without a reload.
            combo.model.sourceModel = catalog;
            tryCompare(combo, "count", 3);
            catalog.setChecked(sourceRow(second), true);
            tryCompare(combo, "count", 2);
            compare(combo.find("Second"), -1);
            compare(combo.currentValue, selected);
            catalog.setChecked(sourceRow(second), false);
            tryCompare(combo, "count", 3);
            compare(combo.valueAt(combo.find("Second")), second);
            catalog.addEditor();
            compare(catalog.editItem(sourceRow(second)), "Second");
            catalog.insert(catalog.editorIndex, "0 renamed");
            catalog.removeEditor();
            tryCompare(combo, "count", 3);
            compare(names(combo), ["0 renamed", "First", "default"]);
            compare(combo.valueAt(0), second);
            compare(combo.currentValue, selected);
            catalog.remove(sourceRow(first));
            tryCompare(combo, "count", 2);
            compare(combo.find("First"), -1);
            catalog.undo();
            tryCompare(combo, "count", 3);
            compare(combo.valueAt(combo.find("First")), first);
            compare(combo.currentValue, selected);
            compare(Theme.activeList, selected);
            compare(shop.model.data(shop.model.index(0, 0)), "Milk");
            compare(shop.model.data(shop.model.index(1, 0)), "Bread");
        }

        name: "CatalogProxy"
        when: windowShown
    }
}
