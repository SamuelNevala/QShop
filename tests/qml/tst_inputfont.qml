pragma ComponentBehavior: Bound
import QShopper
import QtQuick
import QtTest

Item {
    id: scene

    width: 760
    height: 140

    Binding {
        target: Theme
        property: "parent"
        value: scene
    }

    FontLoader {
        id: icons

        source: "qrc:/qt/qml/QShopper/fa-solid-900.otf"
    }

    Component {
        id: inputComponent

        InputDelegate {
            width: 740
            height: Theme.pixels(9.27)
            font.family: icons.name
        }
    }

    TextInput {
        id: plainText

        visible: false
        text: test.input ? test.input.contentItem.text : ""
        renderType: test.input ? test.input.contentItem.renderType : TextInput.QtRendering
        font.family: Qt.application.font.family
        font.pixelSize: test.input ? test.input.contentItem.font.pixelSize : 14
        font.weight: test.input ? test.input.contentItem.font.weight : Font.Normal
    }

    SignalSpy {
        id: submitted

        target: test.input
        signalName: "addItem"
    }

    TestCase {
        id: test

        property var input: null

        function init() {
            compare(icons.status, FontLoader.Ready);
            Theme.scale = 2;
            input = createTemporaryObject(inputComponent, scene);
            verify(input !== null);
            submitted.clear();
        }

        function cleanup() {
            Qt.inputMethod.hide();
            input = null;
        }

        function test_literal_text_data() {
            return [
                        {
                            tag: "icon-ligatures",
                            text: "house bread-slice"
                        },
                        {
                            tag: "common-items",
                            text: "water coffee Milk"
                        },
                        {
                            tag: "quantities",
                            text: "1234567890"
                        }
                    ];
        }

        function test_literal_text(data) {
            const field = input.contentItem;
            field.text = data.text;
            field.forceActiveFocus();
            verify(waitForRendering(field));
            const expected = plainText.contentWidth;
            verify(expected > 0);
            fuzzyCompare(field.contentWidth, expected, 2,
                         "Editor words and quantities must use normal text shaping, not icon ligatures");
            compare(input.font.family, icons.name, "Action icons retain the loaded icon font");
            keyClick(Qt.Key_Return);
            compare(submitted.count, 1);
            compare(submitted.signalArguments[0][0], data.text);
            compare(field.text, "");
        }

        name: "InputFont"
        when: windowShown
    }
}
