import QtQuick 2.3
import QtQuick.Controls 1.2
import Shop.models 1.0

Item {
    id: root

    height: constants.maxHeight

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
                width: Math.round(root.width / repeater.count)

                Text {
                    anchors { left: parent.left; right: parent.right }
                    font.pixelSize: Math.round(parent.height / 2.4)
                    font.bold: true
                    text: dayName
                    color: index == 0 ? "#33B5E5" : "white"
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    anchors { left: parent.left; right: parent.right }
                    font.pixelSize: Math.round(parent.height / 2.4)
                    font.bold: true
                    text: dayNumber
                    color: index == 0 ? "#33B5E5" : "white"
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
