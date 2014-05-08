import QtQuick 2.3
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.1
import Shop.extra 1.0
import "../styles"

FocusScope {
    id: root

    property alias text: input.text

    property string placeholderText
    property string placeholderTextFocus

    property real leftMargin: 20
    property real rightMargin: 20

    signal accepted()
    signal dropAreaEntered(Item dragSource)

    height: constants.maxHeight

    BackgroundItem {
        id: background
        anchors.fill: parent
        color: "white"
        TextField {
            id: input
            focus: true
            anchors { left: parent.left; right: parent.right; margins: 20; verticalCenter: parent.verticalCenter; leftMargin: root.leftMargin; rightMargin: root.rightMargin }
            font.pixelSize: Math.round(background.height / 3)
            horizontalAlignment: Text.AlignHCenter
            height: parent.height * 0.66
            inputMethodHints: Qt.ImhMultiLine
            style: TextFieldStyleAndroid { focus: input.activeFocus }
            placeholderText: activeFocus && displayText == ""  ? root.placeholderTextFocus : root.placeholderText
            z:1

            onAccepted: root.accepted()

            onDisplayTextChanged: console.log(displayText, displayText == "")
        }

        Connections {
            target: Qt.inputMethod
            onVisibleChanged: if (!Qt.inputMethod.visible && input.activeFocus) focusHolder.forceActiveFocus()
        }
    }

    DropArea {
        anchors { fill: parent }
        onEntered: root.dropAreaEntered(drag.source)
        enabled: true
    }
}
