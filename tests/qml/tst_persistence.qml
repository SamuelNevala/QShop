import QShopper
import QtQuick
import QtTest

Item {
    id: scene

    width: 480
    height: 720

    Binding {
        target: Theme
        property: "parent"
        value: scene
    }

    TestCase {
        function init() {
            Theme.scale = 1;
            failOnWarning(/.*Binding loop detected.*/);
        }

        function cleanup() {
            Theme.scale = 1;
        }

        function test_scale_restores_in_a_fresh_engine() {
            Theme.scale = 1.75;
            tryVerify(function () {
                return uiSetup.savedSetting("scale") === 1.75;
            });
            compare(uiSetup.restoredThemeScale(), 1.75);
            if (!previewExpected) {
                compare(Theme.effectiveScale, 1);
            }
        }

        function test_window_position_restores_in_a_new_window() {
            uiSetup.resetDatabase();
            const component = Qt.createComponent("qrc:/qt/qml/QShopper/main.qml");
            compare(component.status, Component.Ready, component.errorString());
            const first = createTemporaryObject(component, null, {
                                                    asynchronous: false
                                                });
            verify(first !== null);
            tryCompare(first, "visible", true);
            const display = Qt.application.screens[Qt.application.screens.length - 1];
            first.x = display.virtualX + 120;
            first.y = display.virtualY + 120;
            wait(200);
            const savedX = first.x;
            const savedY = first.y;
            first.close();
            first.destroy();
            tryVerify(function () {
                return uiSetup.savedSetting("Window/x") === savedX;
            });
            tryVerify(function () {
                return uiSetup.savedSetting("Window/y") === savedY;
            });

            const second = createTemporaryObject(component, null, {
                                                     asynchronous: false
                                                 });
            verify(second !== null);
            tryCompare(second, "visible", true);
            compare(second.x, savedX);
            compare(second.y, savedY);
            second.close();
        }

        name: "SettingsPersistence"
        when: windowShown
    }
}
