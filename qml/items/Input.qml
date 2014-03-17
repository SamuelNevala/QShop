import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import "../styles"

Item {
    id: root

    property alias text: input.text
    property real leftMargin: 20

    signal accepted()
    signal dropAreaEntered(Item dragSource)

    height: constants.maxHeight

    BackgroundItem {
        id: background
        anchors.fill: parent
        //anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
        //height: dragSpot.pressed ? constants.maxHeight * 1.3 : constants.maxHeight
        //width: parent.width
        color: "white"

        //Drag.active: dragSpot.dragArea.drag.active
        //Drag.source: dragSpot
        //Drag.hotSpot.y: Math.round(height / 2)
        //Drag.hotSpot.x:  width - 50

        TextField {
            id: input

            anchors { left: parent.left; right: parent.right; margins: 20; verticalCenter: parent.verticalCenter; leftMargin: root.leftMargin }
            font.pixelSize: Math.round(background.height / 3)
            focus: true
            horizontalAlignment: Text.AlignHCenter
            height: parent.height * 0.66
            style: TextFieldStyleAndroid { focus: input.activeFocus }
            z:1

            onAccepted: root.accepted()
        }

        /*DragSpot {
            id: dragSpot

            property int itemIndex: index

            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            width: height; target: parent
            dragEnabled: true
        }*/
    }

    DropArea {
        anchors { fill: parent }
        onEntered: root.dropAreaEntered(drag.source)
        enabled: true
    }

    /*states: [
        State {
            name: "drag"; when: background.Drag.active
            ParentChange { target: background; parent: root.parent.parent.parent }
            PropertyChanges { target: background; z: 1}
            AnchorChanges {
                target: background;
                anchors.horizontalCenter: undefined;
                anchors.verticalCenter: undefined
                anchors.left: parent.left
                anchors.right: parent.right
            }
        }
    ]

    transitions:  [
        Transition {
            from: "drag"
            ParentAnimation { }
            AnchorAnimation { }
        }
    ]*/
}
