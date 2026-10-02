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

    background: Rectangle { color: Material.backgroundColor; opacity: 0.8; }
    contentItem: FlexboxLayout {
        direction: FlexboxLayout.Row
        gap: root.dimensions.mm(1)
        justifyContent: FlexboxLayout.JustifySpaceEvenly

        Repeater {
            model: WeekModel { }

            Control {
                id: day

                required property int index
                required property int number
                required property string name

                background: Item {
                    Rectangle {
                        anchors { bottom: parent.bottom; bottomMargin: -root.dimensions.mm(0.45); horizontalCenter: parent.horizontalCenter }
                        color: day.index == 0 ? Material.primary : "transparent"
                        height: parent.height * 0.65 ; width:  parent.height * 0.65
                        radius: Material.FullScale
                    }
                }

                contentItem: FlexboxLayout {
                    alignItems: FlexboxLayout.AlignCenter
                    direction: FlexboxLayout.Column
                    gap: root.dimensions.mm(1)
                    justifyContent: FlexboxLayout.JustifyCenter

                    Text {
                        color: day.index == 0 ? Material.primary : Material.foreground
                        font { bold: true; capitalization: Font.AllUppercase; pixelSize: root.dimensions.mm(2.7) }
                        fontSizeMode: Text.Fit
                        horizontalAlignment: Text.AlignHCenter
                        text: day.name
                    }
                    Text {
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
    leftPadding: root.dimensions.mm(2.5); rightPadding: root.dimensions.mm(2.5)
    bottomPadding: root.dimensions.mm(1.5)
}
