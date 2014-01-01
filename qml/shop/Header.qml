import QtQuick 2.0
import QtQuick.Controls 1.0
import Shop.models 1.0

Item {
    id: root

    property bool hide

    height: 70

    Rectangle {
        anchors.fill: parent;
        color: "black"
        opacity: 0.8
    }

    Row {
        anchors.fill: parent

        Repeater {
            id: repeater
            model: WeekModel { id: model }

            Column {
                height: root.height
                width: root.width / repeater.count

                Text {
                    anchors { left: parent.left; right: parent.right }
                    font.pixelSize: parent.height/2.4
                    font.bold: true
                    text: dayName
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    anchors { left: parent.left; right: parent.right }
                    font.pixelSize: parent.height/2.4
                    font.bold: true
                    text: dayNumber
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    states: State {
        name: "hidden"; when: hide
        PropertyChanges { target: root; height: 0; opacity: 0.0 }
    }

    transitions:  [
        Transition {
            to: "hidden"
            SequentialAnimation {
                NumberAnimation { property: "opacity" }
                NumberAnimation { property: "height" }
           }
        },
        Transition {
            from: "hidden"
            SequentialAnimation {
                NumberAnimation { property: "height" }
                NumberAnimation { property: "opacity" }
           }
        }
    ]
}
