import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import "../styles"

Item {
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
            anchors { left: parent.left; right: parent.right; margins: 20; verticalCenter: parent.verticalCenter; leftMargin: root.leftMargin; rightMargin: root.rightMargin }
            font.pixelSize: Math.round(background.height / 3)
            horizontalAlignment: Text.AlignHCenter
            height: parent.height * 0.66
            style: TextFieldStyleAndroid { focus: input.activeFocus }
            placeholderText: activeFocus ?  root.placeholderTextFocus : root.placeholderText
            z:1

            onAccepted: root.accepted()
            onActiveFocusChanged: recoverActiveFocus.start()

            Timer {
                id: recoverActiveFocus; interval: 1
                onTriggered: if(!input.activeFocus && (Qt.platform.os === "android"  ? Qt.inputMethod.visible : true)) input.forceActiveFocus()
            }
        }
    }


    DropArea {
        anchors { fill: parent }
        onEntered: root.dropAreaEntered(drag.source)
        enabled: true
    }
}
