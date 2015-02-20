import QtQuick 2.4

Item {
    id: root

    property string pullHint
    property string actionText
    property bool active: height > 0.0

    signal action()

    z: -1

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.8
    }

    Flipable {
        id: textSwitcher

        anchors {
            left: parent.left; right: parent.right
            bottom: parent.bottom
            bottomMargin: theme.fonts.medium - Math.round(height / 2)
        }
        height: theme.fonts.medium

        front: Text {
            anchors.fill: parent
            font { pixelSize: theme.fonts.medium; bold: true }
            color: "white"
            text: pullHint
            horizontalAlignment: Text.AlignHCenter
        }

        back: Text {
            anchors.fill: parent
            font { pixelSize: theme.fonts.medium; bold: true }
            color: "#33B5E5"
            text: actionText
            horizontalAlignment: Text.AlignHCenter
        }

        transform: Rotation {
            id: rotation
            origin.x: Math.round(textSwitcher.width / 2)
            origin.y: Math.round(textSwitcher.height / 2)
            axis.x: 1; axis.y: 0; axis.z: 0
            angle: 0
        }

        states: State {
            name: "back"
            PropertyChanges { target: rotation; angle: -180 }
            when: root.height > theme.constants.actionThreshold
        }

        transitions: Transition {
            NumberAnimation { target: rotation; property: "angle"; easing.type: Easing.InOutQuad }
        }
    }

    Connections {
        target: root.visible ? root.parent : null
        onDragEnded: if (root.height > theme.constants.actionThreshold) dealayAction.restart()
    }

    Timer {
        id: dealayAction
        interval: 260
        onTriggered: root.action()
    }
}
