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
    contentItem:  RowLayout {
        spacing: root.dimensions.mm(0.5)
        uniformCellSizes: true

        Repeater {
            model: WeekModel { }

            Control {
                id: day

                required property int index
                required property int number
                required property string name

                background: Item {
                    Rectangle {
                        anchors { bottom: parent.bottom; bottomMargin: root.dimensions.mm(0.5); horizontalCenter: parent.horizontalCenter }
                        color: day.index == 0 ? Material.primary : "transparent"
                        height: parent.height * 0.65 ; width:  parent.height * 0.65
                        radius: Material.FullScale
                    }
                }

                contentItem: Item {
                    Text {
                        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
                        color: day.index == 0 ? Material.primary : Material.foreground
                        font { bold: true; capitalization: Font.AllUppercase; pixelSize: root.dimensions.mm(2.7) }
                        fontSizeMode: Text.Fit
                        horizontalAlignment: Text.AlignHCenter
                        text: day.name
                    }

                    Text {
                        anchors { centerIn: parent; verticalCenterOffset: root.dimensions.mm(1.5) }
                        color: day.index == 0 ? Material.primaryHighlightedTextColor : Material.foreground
                        font { bold: true; pixelSize: root.dimensions.mm(4.5) }
                        fontSizeMode: Text.Fit
                        horizontalAlignment: Text.AlignHCenter
                        text: day.number
                    }
                }

                Layout.fillHeight: true; Layout.fillWidth: true
            }
        }
    }
    implicitHeight: root.dimensions.mm(13)
    leftPadding: root.dimensions.mm(0.5); rightPadding: root.dimensions.mm(0.5)
}
