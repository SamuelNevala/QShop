import QShopper
import QtQuick
import QtTest

Item {
    width: 800
    height: 900

    Component {
        id: listsComponent

        Model {}
    }

    Component {
        id: spyComponent

        SignalSpy {
            signalName: "activated"
        }
    }

    TestCase {
        property var app

        function cleanup() {
            if (app) {
                app.close();
                app.destroy();
            }
            Theme.scale = 1;
            wait(0);
        }

        function test_endpoints_data() {
            const cases = [];
            for (const selector of [
                     {
                         name: "lists",
                         index: 0
                     },
                     {
                         name: "accent",
                         index: 3
                     },
                     {
                         name: "primary",
                         index: 4
                     }
                 ]) {
                for (const last of [false, true]) {
                    cases.push({
                                   tag: selector.name + (last ? "_last" : "_first"),
                                   index: selector.index,
                                   last: last
                               });
                }
            }
            return cases;
        }

        function test_endpoints(data) {
            failOnWarning(/.*Binding loop detected.*/);
            uiSetup.resetDatabase();
            Theme.activeList = "default";
            Theme.scale = 2;
            const lists = createTemporaryObject(listsComponent, parent);
            for (let i = 1; i < 30; ++i) {
                lists.insert(i, "list " + i);
            }
            const component = Qt.createComponent("qrc:/qt/qml/QShopper/main.qml");
            compare(component.status, Component.Ready, component.errorString());
            app = createTemporaryObject(component, null, {
                                            asynchronous: false
                                        });
            verify(app !== null);
            tryCompare(app, "visible", true);
            app.requestActivate();
            tryCompare(app, "active", true);
            const shop = app.contentItem.children[0].item.contentItem;
            let drawer = null;
            for (const child of shop.data) {
                if (typeof child.open === "function" && child.contentItem) {
                    drawer = child;
                }
            }
            verify(drawer !== null);
            // Simulate system bars/cutouts with Qt's actual SafeArea propagation.
            app.contentItem.SafeArea.additionalMargins.top = 70;
            app.contentItem.SafeArea.additionalMargins.bottom = 50;
            app.contentItem.SafeArea.additionalMargins.left = 25;
            app.contentItem.SafeArea.additionalMargins.right = 15;
            wait(50);
            app.width = 640;
            app.height = 520;
            shop.openMenu();
            tryCompare(drawer, "opened", true);
            const menu = drawer.contentItem;
            menu.positionViewAtIndex(data.index, ListView.Contain);
            menu.forceLayout();
            const combo = menu.itemAtIndex(data.index);
            verify(combo !== null);
            verify(combo.count >= 19);
            mouseClick(combo, combo.width / 2, combo.height * 0.7);
            tryCompare(combo.popup, "opened", true);
            // Keep the popup open through a viewport and safe-area change.
            app.height = 460;
            app.contentItem.SafeArea.additionalMargins.top = 90;
            app.contentItem.SafeArea.additionalMargins.bottom = 60;
            wait(50);
            const options = combo.popup.contentItem;
            const index = data.last ? combo.count - 1 : 0;
            options.positionViewAtIndex(index, data.last ? ListView.End : ListView.Beginning);
            options.forceLayout();
            const row = options.itemAtIndex(index);
            verify(row !== null);
            const safe = app.contentItem.SafeArea.margins;
            const viewport = options.mapToItem(app.contentItem, 0, 0);
            verify(viewport.y >= safe.top - 1, "Popup content overlaps the top safe area");
            verify(viewport.y + options.height <= app.height - safe.bottom + 1,
                   "Popup content overlaps the bottom safe area");
            verify(viewport.x >= safe.left - 1);
            verify(viewport.x + options.width <= app.width - safe.right + 1);
            const position = row.mapToItem(app.contentItem, 0, 0);
            verify(position.y >= safe.top - 1, "First/last row starts outside the safe area");
            verify(position.y + row.height <= app.height - safe.bottom + 1,
                   "First/last row ends outside the safe area");
            fuzzyCompare(row.height, combo.rowHeight, 1);
            const activated = createTemporaryObject(spyComponent, parent, {
                                                        target: combo
                                                    });
            const value = combo.valueAt(index);
            mouseClick(row, row.width / 2, row.height / 2);
            tryCompare(activated, "count", 1);
            compare(combo.currentIndex, index);
            if (data.index === 3) {
                compare(Theme.accent, value);
            } else if (data.index === 4) {
                compare(Theme.primary, value);
            } else {
                compare(Theme.activeList, value);
            }
            tryCompare(combo.popup, "visible", false);
        }

        name: "ComboBoxSafeArea"
        when: windowShown
    }
}
