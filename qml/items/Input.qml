import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import "../styles"

Item {
    id: root

    property alias text: input.text

    property string placeholderText
    property string placeholderTextFocus

    property real leftMargin: 20

    signal accepted()
    signal dropAreaEntered(Item dragSource)

    height: constants.maxHeight

    BackgroundItem {
        id: background
        anchors.fill: parent
        color: "white"

        TextField {
            id: input

            anchors { left: parent.left; right: parent.right; margins: 20; verticalCenter: parent.verticalCenter; leftMargin: root.leftMargin }
            font.pixelSize: Math.round(background.height / 3)
            focus: true
            horizontalAlignment: Text.AlignHCenter
            height: parent.height * 0.66
            style: TextFieldStyleAndroid { focus: input.activeFocus }
            placeholderText: activeFocus ?  root.placeholderTextFocus : root.placeholderText
            z:1
            onAccepted: root.accepted()
        }
    }

    DropArea {
        anchors { fill: parent }
        onEntered: root.dropAreaEntered(drag.source)
        enabled: true
    }
}
