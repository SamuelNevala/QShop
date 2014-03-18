import QtQuick 2.0
import QtGraphicalEffects 1.0

Item {
    id: root

    height: constants.maxHeight

    MouseArea {
        id: bottomMouseArea
        anchors.fill: parent
        enabled: !selected
        onClicked: itemModel.moveEditor(index)
    }

    LinearGradient {
        id: backgound

        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
        height: constants.maxHeight
        scale: dragSpot.pressed ? 1.15 : 1
        start: Qt.point(0, Math.round(height / 2))
        end: Qt.point(width, Math.round(height / 2))
        opacity: 0.8
        width: parent.width

        gradient: Gradient {
            GradientStop {
                color: bottomMouseArea.pressed ? "#33B5E5" : "black"
                position: 0.0
                Behavior on color { ColorAnimation { easing.type: Easing.InOutQuad } }
            }
            GradientStop {
                color: bottomMouseArea.pressed ? "#33B5E5" : "black"
                position: dragSpot.pressed ? 0.7 : 0.75
                Behavior on position { NumberAnimation { easing.type: Easing.InOutQuad } }
                Behavior on color { ColorAnimation { easing.type: Easing.InOutQuad } }
            }
            GradientStop {
                color: dragSpot.pressed || bottomMouseArea.pressed ? "#33B5E5" : "#0099CC"
                position: 1.0
                Behavior on color { ColorAnimation { easing.type: Easing.InOutQuad } }
            }
        }
        states: [
            State {
                name: "drag"; when: backgound.Drag.active
                ParentChange { target: backgound; parent: root.parent.parent.parent }
                PropertyChanges { target: backgound; z: 1}
                AnchorChanges {
                    target: backgound;
                    anchors.horizontalCenter: undefined;
                    anchors.verticalCenter: undefined
                    anchors.left: parent.left
                    anchors.right: parent.right
                }
            }
        ]

        transitions:  [ Transition { from: "drag"; ParentAnimation {} AnchorAnimation {} }]

        Drag.active: dragSpot.drag.active
        Drag.hotSpot.y: Math.round( height / 2 )
        Drag.hotSpot.x:  width - 50
        Drag.source: dragSpot

        MouseArea {
            id: dragSpot
            property int itemIndex: index
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            enabled: !selected
            drag { target: backgound }
            width: height
        }

        Text {
            id: text
            anchors {
                right: parent.right; left: parent.left; margins: 10
                verticalCenter: parent.verticalCenter
            }
            horizontalAlignment: Text.AlignHCenter
            font {
                bold: true
                pixelSize: parent.height - 20
                strikeout: selected
            }
            color: selected ? "darkgray" : "white"
            scale: parent.width / (paintedWidth + 20) < 1 ? parent.width / (paintedWidth + 20) : 1
            text: itemText
        }
        Behavior on scale { NumberAnimation { easing.type: Easing.InOutQuad } }
    }

    DropArea {
        anchors { fill: parent }
        enabled: !selected
        onEntered: itemModel.move(drag.source.itemIndex, index)
    }
}
