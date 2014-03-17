import QtQuick 2.0
import Shop.models 1.0
import QtQuick.Controls 1.1
import "../items"

ListView {
    id: root

    cacheBuffer: root.height * 3
    delegate:Component {
        Loader {
            anchors { right: parent.right; left: parent.left }
            source: editor ? Qt.resolvedUrl("../items/InputItem.qml") : Qt.resolvedUrl("../items/BackgroundItem.qml")
        }
    }

    add: Transition {
        NumberAnimation { properties: "x, y"; easing.type: Easing.InOutQuad; duration: constants.mediumTime }
        NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: constants.mediumTime }
        NumberAnimation { property: "scale"; from: 0.5; to: 1.0; duration: constants.mediumTime }
    }

    displaced: Transition {
        PropertyAction { property: "z"; value: 1 }
        NumberAnimation { properties: "y"; easing.type: Easing.InOutQuad; duration: constants.mediumTime }
        NumberAnimation { property: "opacity"; to: 1.0; duration: constants.mediumTime }
        NumberAnimation { property: "scale"; to: 1.0; duration: constants.mediumTime }
    }

    move: Transition {
        PropertyAction { property: "z"; value: -1 }
        PropertyAction { property: "z"; value: -1 }
        SequentialAnimation {
            NumberAnimation { property: "scale"; to: 0.90 }
            NumberAnimation { properties: "y"; easing.type: Easing.InOutQuad; duration: constants.longTime }
            NumberAnimation { property: "scale"; to: 1.0 }
        }
        //ScriptAction { script: { root.skipMoveTransition = false } }
    }

    remove: Transition {
        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: constants.mediumTime }
        NumberAnimation { property: "scale"; from: 1.0; to: 0.0; duration: constants.mediumTime }
    }

    Stack.onStatusChanged: {
        if (Stack.status == Stack.Activating) {
            applicationWindow.stopAnimation = true
            itemModel.addEditor()
            applicationWindow.stopAnimation = false
        } else if (Stack.status == Stack.Inactive) {
            applicationWindow.stopAnimation = true
            itemModel.removeEditor()
            applicationWindow.stopAnimation = false
        }
    }

    /*populate: Transition {
        id: transition
        SequentialAnimation {
             NumberAnimation { properties: "opacity"; easing.type: Easing.InOutQuad; to: 0.0; duration:0 }
            PauseAnimation { duration: (transition.ViewTransition.index - transition.ViewTransition.targetIndexes[0]) * 200 }
            ParallelAnimation{
                NumberAnimation { properties: "opacity"; easing.type: Easing.InOutQuad; from: 0.0; to: 1.0 }
                NumberAnimation { properties: "y"; easing.type: Easing.InOutQuad; duration: 500 }
            }
        }
    }*//*



   // Component.onCompleted: if (root.count == 0) pageSwitcher.state = "edit"

    /*transitions: [
        Transition { to: "edit"; ScriptAction { script: { itemModel.addEditor() } } },
        Transition { from: "edit"; ScriptAction { script: { itemModel.removeEditor() } } }
    ]*/
}

