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
            width: 600
            height: 900
        }
    }

    TestCase {
        function test_touch_scroll_reaches_about() {
            uiSetup.resetDatabase();
            Theme.scale = 2;
            Theme.activeList = "default";
            const view = createTemporaryObject(viewComponent, scene);
            verify(view !== null);
            const shop = view.contentItem;
            const drawer = shop.data.find(item => typeof item.open === "function"
                                                  && item.contentItem);
            drawer.open();
            tryCompare(drawer, "opened", true);
            const list = drawer.contentItem;
            verify(list.contentHeight > list.height, "Fixture requires an overflowing drawer");
            const before = list.contentY;
            const touch = touchEvent(list);
            touch.press(0, list, list.width / 2, list.height * .8).commit();
            for (let step = 1; step <= 10; ++step) {
                touch.move(0, list, list.width / 2, list.height * (.8 - step * .06)).commit();
                wait(20);
            }
            touch.release(0, list, list.width / 2, list.height * .2).commit();
            tryVerify(() => list.contentY > before, 2000, "A real touch must scroll the drawer");
            drawer.close();
        }

        name: "DrawerFlick"
        when: windowShown
    }
}
