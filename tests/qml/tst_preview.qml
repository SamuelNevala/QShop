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

    Component {
        id: iconComponent

        Icon {}
    }

    Component {
        id: comboComponent

        ComboBox {}
    }

    Component {
        id: buttonComponent

        IconButton {
            width: Theme.pixels(18)
            text: "Remove checked"
        }
    }

    TestCase {
        function init() {
            Theme.scale = 1;
            failOnWarning(/.*Binding loop detected.*/);
        }

        function cleanup() {
            Theme.scale = 1;
        }

        function test_build_and_platform_gate() {
            compare(Theme.scaleable, previewExpected);
            compare(Theme.visible, false);
            if (Qt.platform.os === "android") {
                verify(!Theme.scaleable);
                compare(Theme.densityCorrection, 1);
            }
        }

        function test_existing_components_recalculate_without_recreation() {
            const icon = createTemporaryObject(iconComponent, scene);
            const combo = createTemporaryObject(comboComponent, scene);
            const button = createTemporaryObject(buttonComponent, scene);
            verify(icon !== null);
            verify(combo !== null);
            verify(button !== null);
            fuzzyCompare(button.background.x + button.background.width / 2, button.width / 2,
                         0.000001);
            const rowHeight = icon.implicitHeight;
            const padding = icon.padding;
            const arrowSize = combo.indicator.width;
            Theme.scale = 2;
            const factor = previewExpected ? 2 : 1;
            fuzzyCompare(icon.implicitHeight, rowHeight * factor, 0.000001);
            fuzzyCompare(icon.padding, padding * factor, 0.000001);
            fuzzyCompare(combo.indicator.width, arrowSize * factor, 0.000001);
            fuzzyCompare(button.background.width, Theme.pixels(8), 0.000001);
            fuzzyCompare(button.background.x + button.background.width / 2, button.width / 2,
                         0.000001);
            fuzzyCompare(Theme.millimeters(Theme.pixels(12.3)), 12.3, 0.000001);
        }

        function test_scale_limits_and_invalid_values() {
            Theme.scale = 100;
            compare(Theme.effectiveScale, previewExpected ? 4 : 1);
            Theme.scale = 0;
            compare(Theme.effectiveScale, previewExpected ? 0.25 : 1);
            Theme.scale = NaN;
            compare(Theme.effectiveScale, 1);
            Theme.scale = 1;
            Theme.scaleUp();
            compare(Theme.scale, previewExpected ? 1.1 : 1);
            compare(Theme.effectiveScale, previewExpected ? 1.1 : 1);
            Theme.scaleDown();
            compare(Theme.scale, 1);
            compare(Theme.effectiveScale, 1);
        }

        function test_window_shortcuts_resize_without_losing_items() {
            uiSetup.resetDatabase();
            const component = Qt.createComponent("qrc:/qt/qml/QShopper/main.qml");
            compare(component.status, Component.Ready, component.errorString());
            const app = createTemporaryObject(component, null);
            verify(app !== null);
            tryCompare(app, "visible", true);
            app.requestActivate();
            tryCompare(app, "active", true);
            tryCompare(app, "width", Math.round(Theme.pixels(76.6)));
            tryVerify(function () {
                return app.contentItem.children[0].item !== null;
            });
            const view = app.contentItem.children[0].item;
            const shop = view.contentItem;
            const model = shop.model;
            model.insert(0, "Milk");
            const count = model.count;
            keyClick(Qt.Key_PageUp);
            tryCompare(Theme, "effectiveScale", previewExpected ? 1.1 : 1);
            tryCompare(app, "width", Math.round(Theme.pixels(76.6)));
            tryCompare(app, "height", Math.round(Theme.pixels(162.8)));
            compare(shop.model, model);
            compare(model.count, count);
            keyClick(Qt.Key_PageDown);
            tryCompare(Theme, "effectiveScale", 1);
            Theme.scale = 2;
            tryCompare(app, "width", Math.round(Theme.pixels(76.6)));
            keyClick(Qt.Key_0, Qt.ControlModifier);
            if (previewExpected) {
                tryCompare(Theme, "effectiveScale", 1);
            } else {
                compare(Theme.effectiveScale, 1);
            }
            app.close();
        }

        name: "PreviewScaling"
        when: windowShown
    }
}
