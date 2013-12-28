import QtQuick 2.0
import QtQuick.Controls 1.0
import Shop.models 1.0

Rectangle {
    id: root
    color: "black"
    opacity: 0.8

   /* Row {
        anchors.fill: parent
        Button {
            text: "Clear all"
            onClicked: itemModel.removeAll();
        }
        Button {
            text: "Reset"
            onClicked: itemModel.reset();
        }

    }*/
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
}
