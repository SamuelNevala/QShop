import QtQuick 2.4
import QtQuick.Controls 1.3

FocusScope {
    id: root

    property alias text: input.text

    property string placeholderText
    property string placeholderTextFocus

    property real leftMargin: 20
    property real rightMargin: 20

    signal accepted()
    signal dropAreaEntered(Item dragSource)

    height: theme.heights.large

    BackgroundItem {
        id: background
        anchors.fill: parent
        color: "white"
        TextField {
            id: input
            focus: true
            anchors { left: parent.left; right: parent.right; margins: 20; verticalCenter: parent.verticalCenter; leftMargin: root.leftMargin; rightMargin: root.rightMargin }
            horizontalAlignment: Text.AlignHCenter
            placeholderText: activeFocus && displayText == "" ? root.placeholderTextFocus : root.placeholderText
            z: 1

            onAccepted: root.accepted()
            Keys.onReturnPressed: {
                Qt.inputMethod.commit()
                root.accepted()
            }
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
