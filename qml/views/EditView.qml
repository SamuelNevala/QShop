import QtQuick 2.0
import Shop.models 1.0
import "../items"

ListView {
    id: root

    cacheBuffer: root.height * 3
    delegate: Component {
        Loader {
            anchors { right: parent.right; left: parent.left }
            source: Qt.resolvedUrl("../items/InputDelegate.qml")
        }
    }

    add: Transition {
        NumberAnimation { properties: "x, y"; easing.type: Easing.InOutQuad; duration: 500 }
        NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: 400 }
        NumberAnimation { property: "scale"; from: 0.5; to: 1.0; duration: 400 }
    }
    displaced: Transition {
        PropertyAction { property: "z"; value: 1 }
        NumberAnimation { properties: "y"; easing.type: Easing.InOutQuad; duration: 400 }
        NumberAnimation { property: "opacity"; to: 1.0; duration: 400 }
        NumberAnimation { property: "scale"; to: 1.0; duration: 400 }
    }
    move: Transition {
        PropertyAction { property: "z"; value: -1 }
        NumberAnimation { properties: "x, y"; easing.type: Easing.InOutQuad; duration: root.skipMoveTransition ? 0 : 1000 }
        ScriptAction { script: { root.skipMoveTransition = false } }
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

    remove: Transition {
        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 400 }
        NumberAnimation { property: "scale"; from: 1.0; to: 0.0; duration: 400 } }

   // Component.onCompleted: if (root.count == 0) pageSwitcher.state = "edit"

    /*transitions: [
        Transition { to: "edit"; ScriptAction { script: { itemModel.addEditor() } } },
        Transition { from: "edit"; ScriptAction { script: { itemModel.removeEditor() } } }
    ]*//*
}
*/
