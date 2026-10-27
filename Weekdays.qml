import QtQuick.Controls.Material
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QShopper

pragma ComponentBehavior: Bound

Control {
    id: root
    background: Rectangle { color: Material.backgroundColor; opacity: 0.8; }
    contentItem: FlexboxLayout {
        direction: FlexboxLayout.Row
        gap: Theme.pixels(1)
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
                        anchors { bottom: parent.bottom; bottomMargin: -Theme.pixels(0.45); horizontalCenter: parent.horizontalCenter }
                        color: day.index == 0 ? Material.primary : "transparent"
                        height: parent.height * 0.65 ; width:  parent.height * 0.65
                        radius: Material.FullScale
                    }
                }

                contentItem: FlexboxLayout {
                    alignItems: FlexboxLayout.AlignCenter
                    direction: FlexboxLayout.Column
                    gap: Theme.pixels(1)
                    justifyContent: FlexboxLayout.JustifyCenter

                    Text {
                        color: day.index == 0 ? Material.primary : Material.foreground
                        font { bold: true; capitalization: Font.AllUppercase; pixelSize: Theme.pixels(2.7) }
                        fontSizeMode: Text.Fit
                        horizontalAlignment: Text.AlignHCenter
                        text: day.name
                    }
                    Text {
                        color: day.index == 0 ? Material.primaryHighlightedTextColor : Material.foreground
                        font { bold: true; pixelSize: Theme.pixels(4.5) }
                        fontSizeMode: Text.Fit
                        horizontalAlignment: Text.AlignHCenter
                        text: day.number
                    }
                }

                Layout.fillHeight: true; Layout.fillWidth: true
            }
        }
    }
    implicitHeight: Theme.pixels(13)
    leftPadding: Theme.pixels(2.5); rightPadding: Theme.pixels(2.5)
    bottomPadding: Theme.pixels(1.5)
}
