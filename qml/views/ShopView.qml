import QtQuick 2.0
import Shop.models 1.0
import "../items"

ListView {
    id: root

    Pulley {
        actionText: qsTr("Release to edit")
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: -parent.contentY + parent.originY - weekdays.height
        pullHint: qsTr("Pull to edit")
        onAction: pageSwitcher.push({"item": Qt.resolvedUrl("EditView.qml"), properties: {model: itemModel}})
    }

    Weekdays {
        id: weekdays
        anchors { right: parent.right; left: parent.left }
        y: -parent.contentY - height + parent.originY
    }

    Rectangle {
        height: root.height
        color: "black"
        opacity: visible ? 0.8 : 0.0
        y: -root.contentY
        visible: emptyState.visible
        width:  root.width
    }

    Text {
        id: emptyState
        anchors { fill: parent; margins: 30 }
        font { pixelSize: Math.round(parent.height * 0.1 / 3); bold: true }
        color: "#33B5E5"
        text: qsTr("Pull to add items to shop list.")
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        opacity: visible ? 1.0 : 0.0
        visible: root.count <= 0 || pageSwitcher.depth === 2 && root.count <= 1
    }

    delegate: Component {
        Loader {
            anchors { right: parent.right; left: parent.left }
            source: editor ? "" : Qt.resolvedUrl("../items/SelectableItem.qml")
        }
    }

    displaced: Transition {
        enabled: applicationWindow.animate
        PropertyAction { property: "z"; value: 1 }
        NumberAnimation { properties: "y"; easing.type: Easing.InOutQuad; duration: constants.mediumTime }
        NumberAnimation { property: "opacity"; to: 1.0; duration: constants.mediumTime }
        NumberAnimation { property: "scale"; to: 1.0; duration: constants.mediumTime }
    }

    move: Transition {
        enabled: applicationWindow.animate
        PropertyAction { property: "z"; value: -1 }
        SequentialAnimation {
            NumberAnimation { property: "scale"; to: 0.90 }
            NumberAnimation { properties: "y"; easing.type: Easing.InOutQuad; duration: constants.longTime }
            NumberAnimation { property: "scale"; to: 1.0 }
        }
        ScriptAction {script: root.returnToBounds()}
    }
}
