import QtQuick.Controls.Material
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QDynamics
import QShopper

pragma ComponentBehavior: Bound

Control {
    id: root

    property Dimensions dimensions

    background: Rectangle { color: Material.backgroundColor; opacity: 0.8 }
    contentItem: RowLayout {
        implicitHeight: root.dimensions.mm(9.27)

        Repeater {
            id: repeater
            model: WeekModel { }
            ColumnLayout {
                id: layout
                required property int index
                required property int number
                required property string name

                Text {
                    font { pixelSize: root.dimensions.mm(3); bold: true }
                    text: layout.name
                    color: layout.index == 0 ? Material.accentColor : Material.foreground
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    fontSizeMode: Text.Fit
                }

                Text {
                    font { pixelSize: root.dimensions.mm(3); bold: true }
                    text: layout.number
                    color: layout.index == 0 ? Material.accentColor : Material.foreground
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    fontSizeMode: Text.Fit
                }

                Layout.fillHeight: true
                Layout.preferredWidth: metrics.advanceWidth("00")
                Layout.alignment: Qt.AlignCenter
            }
        }
    }

    resources: [ FontMetrics { id: metrics; font { pixelSize: root.dimensions.mm(3); bold: true } } ]
}
