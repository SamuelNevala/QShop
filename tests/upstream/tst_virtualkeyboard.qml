// DEV-001: optional Qt-only probe for the validated Windows 6.12.0 SDK.
// Run with Qt's qmltestrunner, not the QShopper test executable.
import QtQuick
import QtQuick.VirtualKeyboard
import QtQuick.VirtualKeyboard.Settings
import QtTest

Item {
    width: 640
    height: 700

    TextInput {
        id: field

        width: parent.width
        height: 60
        inputMethodHints: Qt.ImhNoAutoUppercase
    }

    InputPanel {
        id: panel

        width: parent.width
        anchors.bottom: parent.bottom
    }

    TestCase {
        function findKey(item, code) {
            if (item.visible && item.enabled && item.key === code) {
                return item;
            }
            for (const child of item.children) {
                const key = findKey(child, code);
                if (key) {
                    return key;
                }
            }
            return null;
        }

        function test_original_popup_source() {
            // Explicit source loading bypasses the module's preferred compiled resource.
            const component = Qt.createComponent(
                      "file:///C:/Qt/6.12.0/msvc2022_64/qml/QtQuick/VirtualKeyboard/Components/PopupList.qml");
            compare(component.status, Component.Ready, component.errorString());
            const popup = createTemporaryObject(component, null, {
                                                    delegate: null,
                                                    highlight: null,
                                                    add: null,
                                                    remove: null
                                                });
            verify(popup !== null);
            compare(popup.contentWidth, popup.contentItem.childrenRect.width);
        }

        function test_standalone_input_panel() {
            VirtualKeyboardSettings.locale = "en_GB";
            VirtualKeyboardSettings.closeOnReturn = false;
            verify(panel.height > 0);
            field.forceActiveFocus();
            InputMethod.show();
            tryCompare(panel, "active", true);
            wait(250);
            for (const code of [Qt.Key_M, Qt.Key_I, Qt.Key_L, Qt.Key_K]) {
                tryVerify(() => findKey(panel, code) !== null);
                const key = findKey(panel, code);
                mouseClick(key, key.width / 2, key.height / 2);
            }
            compare(field.text, "milk");
            InputMethod.hide();
            tryCompare(panel, "active", false);
        }

        name: "QtKeyboardDiagnostic"
        when: windowShown
    }
}
