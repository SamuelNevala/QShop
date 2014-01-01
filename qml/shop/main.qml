import QtQuick 2.0
import QtGraphicalEffects 1.0
import Shop.models 1.0

Image {
    id: root

    property int dragDistance
    property bool skipMoveTransition

    height: 960; width: 540
    source: "qrc:/pic/bg"

    ListView {
        id: list

        anchors.fill: parent
        cacheBuffer: root.height * 3

        Pulley {
            id: pulley
            actionText: root.state == "" ? "Edit" : "Shop"
            pullHint: root.state == "" ? "Pull to edit" : "Pull to shop"
            onAction: root.state = root.state == "" ? "edit" : ""
        }

        header: Header {
            id: header
            anchors { right: parent.right; left: parent.left }
            hide: root.state == "edit"
        }

        model: ItemModel { id: itemModel }

        delegate: Component {
            Loader {
                anchors { right: parent.right; left: parent.left }
                source: editor ? "InputDelegate.qml" : "SelectableItem.qml"
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
        }*/

        remove: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 400 }
            NumberAnimation { property: "scale"; from: 1.0; to: 0.0; duration: 400 } }

        Component.onCompleted: if (list.count == 0) root.state = "edit"
    }

    states: State { name: "edit" }

    transitions: [
        Transition { to: "edit"; ScriptAction { script: { itemModel.addEditor() } } },
        Transition { from: "edit"; ScriptAction { script: { itemModel.removeEditor() } } }
    ]
}
