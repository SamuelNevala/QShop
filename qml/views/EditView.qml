import QtQuick 2.0
import Shop.models 1.0
import QtQuick.Controls 1.1
import "../items"

ListView {
    id: editList

    delegate: Component {
        Loader {
            anchors { right: parent.right; left: parent.left }
            source: editor ? Qt.resolvedUrl("../items/InputItem.qml") : Qt.resolvedUrl("../items/DragableItem.qml")
        }
    }

    add: Transition {
        enabled: applicationWindow.animate
        NumberAnimation { properties: "x, y"; easing.type: Easing.InOutQuad; duration: constants.mediumTime }
        NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: constants.mediumTime }
        NumberAnimation { property: "scale"; from: 0.5; to: 1.0; duration: constants.mediumTime }
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
        NumberAnimation { properties: "y"; easing.type: Easing.InOutQuad; duration: constants.mediumTime }
    }

    remove: Transition {
        enabled: applicationWindow.animate
        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: constants.mediumTime }
        NumberAnimation { property: "scale"; from: 1.0; to: 0.0; duration: constants.mediumTime }
    }

    Stack.onStatusChanged: {
        if (Stack.status == Stack.Activating) {
            applicationWindow.animate = false
            itemModel.addEditor()
            applicationWindow.animate = true
        } else if (Stack.status == Stack.Inactive) {
            applicationWindow.animate = false
            itemModel.removeEditor()
            applicationWindow.animate = true
        }
    }
}

