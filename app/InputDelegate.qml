import QShopper
import QtQuick
import QtQuick.Controls.Fusion as Fusion
import QtQuick.Controls.Material

Delegate {
    id: root

    signal addItem(string text)
    signal barsTapped

    function insert(text) {
        if (text === "") {
            return;
        }
        input.clear();
        input.insert(0, text);
        input.forceActiveFocus();
    }

    Material.theme: Theme.inverseTheme

    contentItem: Fusion.TextField {
        id: input

        function addItem() {
            Qt.inputMethod.commit();
            if (text === "") {
                return;
            }
            root.addItem(input.text);
            clear();
        }

        color: Material.primaryTextColor
        placeholderTextColor: Material.secondaryTextColor
        focus: true
        EnterKey.type: Qt.EnterKeyReturn
        horizontalAlignment: Text.AlignHCenter
        leftPadding: height
        rightPadding: height
        placeholderText: qsTr("Tap to add items")

        background: Rectangle {
            color: Material.backgroundColor
            opacity: 0.8
        }

        onAccepted: addItem()
        onPressed: {
            forceActiveFocus();
            Qt.inputMethod.show();
        }

        font {
            pixelSize: Theme.pixels(3.5)
        }

        Icon {
            height: parent.height
            width: height
            text: "\uf0c9"
            Material.theme: Theme.theme
            font.family: root.font.family

            onClicked: root.barsTapped()

            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
            }
        }

        Icon {
            enabled: input.text || input.preeditText
            height: parent.height
            width: height
            text: "\uf057"
            Material.theme: Theme.theme

            onClicked: {
                // Qt.inputMethod.commit()
                input.clear();
            }

            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
            }

            font {
                family: root.font.family
            }
        }
    }

    Keys.onReturnPressed: {
        // Qt.inputMethod.commit()
        input.addItem();
    }
    Keys.onEscapePressed: input.focus = false
}
