import QShopper
import QtQuick
import QtTest

Item {
    width: 800
    height: 900

    TestCase {
        function cleanup() {
            Theme.scale = 1;
        }

        function test_repeated_open_resize_and_zoom() {
            failOnWarning(/.*Binding loop detected.*/);
            uiSetup.resetDatabase();
            Theme.scale = 1;
            const component = Qt.createComponent("qrc:/qt/qml/QShopper/main.qml");
            compare(component.status, Component.Ready, component.errorString());
            const app = createTemporaryObject(component, null, {
                                                  asynchronous: false
                                              });
            verify(app !== null);
            tryCompare(app, "visible", true);
            const shop = app.contentItem.children[0].item.contentItem;
            shop.openMenu();
            wait(300);
            let drawer = null;
            for (let child of shop.data) {
                if (typeof child.open === "function" && child.contentItem) {
                    drawer = child;
                }
            }
            verify(drawer !== null);
            const list = drawer.contentItem;
            for (let scale of [0.5, 1.7, 3, 4]) {
                Theme.scale = scale;
                wait(30);
                app.height = 500;
                wait(30);
                for (let index of [0, 3, 4]) {
                    list.positionViewAtIndex(index, ListView.Contain);
                    list.forceLayout();
                    const combo = list.itemAtIndex(index);
                    verify(combo !== null);
                    combo.popup.open();
                    tryCompare(combo.popup, "opened", true);
                    const options = combo.popup.contentItem;
                    options.positionViewAtEnd();
                    options.forceLayout();
                    app.height = 700;
                    wait(30);
                    options.positionViewAtBeginning();
                    options.forceLayout();
                    app.height = 500;
                    wait(30);
                    verify(combo.popup.height > 0);
                    verify(combo.popup.height <= app.height);
                    combo.popup.close();
                    tryCompare(combo.popup, "visible", false);
                }
            }
            drawer.close();
            app.close();
        }

        name: "ComboBoxPopupSizing"
        when: windowShown
    }
}
