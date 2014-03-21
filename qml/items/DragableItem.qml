import QtQuick 2.0
import QtGraphicalEffects 1.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1

Item {
    id: root

    height: constants.maxHeight

    Menu {
        id: itemMenu
        title: itemText

        MenuItem {
            text: qsTr("Remove")
            onTriggered: remorse.state = "remorse"
        }
    }

    MouseArea {
        id: bottomMouseArea
        anchors.fill: parent
        enabled: !selected && !remorse.visible
        onClicked: itemModel.moveEditor(index)
        onPressAndHold: itemMenu.popup()
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
            opacity: remorse.state == "remorse" ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { easing.type: Easing.InOutQuad } }
        }
        Behavior on scale { NumberAnimation { easing.type: Easing.InOutQuad } }

    }

    DropArea {
        anchors { fill: parent }
        enabled: !selected

        onEntered: itemModel.move(drag.source.itemIndex, index)
    }

    RemorseItem {
        id: remorse
        height: parent.height
        opacity: 0.0
        title: qsTr("Removing %1").arg(itemText)
        label: qsTr("Tap to cancel")
        maximumValue: 4
        visible: opacity > 0.0
        width: parent.width
        x: parent.width

        states: State {
            name: "remorse"
            PropertyChanges { target: remorse; opacity: 0.8; x: 0 }
        }

        transitions: [
            Transition {
                to: "remorse"
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; easing.type: Easing.InOutQuad; duration: 500 }
                        NumberAnimation { property: "x"; easing.type: Easing.InOutQuad; duration: 500 }
                    }
                    ScriptAction { script: remorse.value = 0 }
                }
            },
            Transition {
                from: "remorse"
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; easing.type: Easing.InOutQuad; duration: 500 }
                        NumberAnimation { property: "x"; easing.type: Easing.InOutQuad; duration: 500 }
                    }
                    ScriptAction { script: remorse.reset() }
                }
            }
        ]
        onCancelled: remorse.state = ""
        onDone: itemModel.remove(index)
    }
}
