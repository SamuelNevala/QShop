import QtQuick 2.6
import QtQuick.Layouts 1.3
import Shop.models 1.0

Item {
    id: root

    height: theme.heights.large

    Rectangle {
        anchors { fill: parent }
        color: "black"
        opacity: 0.8
    }

    FontMetrics {
        id: metrics
        font { pixelSize: theme.fonts.medium; bold: true }
    }

    RowLayout {
        anchors { fill: parent; margins: theme.margins.small }

        Repeater {
            id: repeater
            model: WeekModel { }

            ColumnLayout {
                id: layout
                Text {
                    font { pixelSize: theme.fonts.medium; bold: true }
                    text: name
                    color: index == 0 ? "#33B5E5" : "white"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }
                Text {
                    font { pixelSize: theme.fonts.medium; bold: true }
                    text: number
                    color: index == 0 ? "#33B5E5" : "white"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }
                Layout.fillHeight: true
                Layout.preferredWidth:  metrics.advanceWidth("00") + theme.margins.small * 2
                Layout.alignment: Qt.AlignCenter
            }
        }
    }
}
