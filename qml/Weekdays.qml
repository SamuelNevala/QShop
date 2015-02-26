import QtQuick 2.4
import QtQuick.Layouts 1.1
import Shop.models 1.0

Item {
    id: root

    height: theme.heights.large

    Rectangle {
        anchors { fill: parent }
        color: "black"
        opacity: 0.8
    }

    RowLayout {
        anchors { fill: parent }

        Repeater {
            id: repeater
            model: WeekModel { id: model }

            ColumnLayout {
                Text {
                    font { pixelSize: theme.fonts.medium; bold: true }
                    text: dayName
                    color: index == 0 ? "#33B5E5" : "white"
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    font { pixelSize: theme.fonts.medium; bold: true }
                    text: dayNumber
                    color: index == 0 ? "#33B5E5" : "white"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignCenter
                }
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignCenter
            }
        }
    }
}
