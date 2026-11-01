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
        id: keyboardComponent

        DevelopmentKeyboard {}
    }

    TestCase {
        function init() {
            Theme.scale = 1;
        }

        function test_keyboard_build_gate() {
            const keyboard = createTemporaryObject(keyboardComponent, scene);
            verify(keyboard !== null);
            compare(keyboard.available, keyboardExpected);
            compare(keyboard.occupiedHeight, 0);
            compare(keyboard.visible, false);
        }

        function test_screen_density_conversion() {
            verify(scene.Screen.pixelDensity > 0);
            compare(Theme.pixelsPerMillimeter, scene.Screen.pixelDensity);
            compare(Theme.pixels(10), 10 * scene.Screen.pixelDensity);
            compare(Theme.millimeters(10 * scene.Screen.pixelDensity), 10);
            compare(Theme.pixels(0), 0);
        }

        function test_components_without_dimensions_reference() {
            const icon = createTemporaryObject(iconComponent, scene);
            const combo = createTemporaryObject(comboComponent, scene);
            verify(icon !== null);
            verify(combo !== null);
            compare(icon.implicitHeight, 9.27 * scene.Screen.pixelDensity);
            compare(icon.padding, 0.2 * scene.Screen.pixelDensity);
            verify(combo.topInset > 0);
        }

        name: "ThemeSizing"
        when: windowShown
    }
}
