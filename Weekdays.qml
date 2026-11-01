pragma ComponentBehavior: Bound
import QShopper
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Controls.Control {
    id: root

    implicitHeight: Theme.pixels(13)
    leftPadding: Theme.pixels(2.5)
    rightPadding: Theme.pixels(2.5)
    bottomPadding: Theme.pixels(1.5)

    background: Rectangle {
        color: Material.backgroundColor
        opacity: 0.8
    }
    contentItem: FlexboxLayout {
        direction: FlexboxLayout.Row
        gap: Theme.pixels(1)
        justifyContent: FlexboxLayout.JustifySpaceEvenly

        Repeater {
            model: WeekModel {}

            Controls.Control {
                id: day

                required property int index
                required property int number
                required property string name

                Layout.fillHeight: true
                Layout.fillWidth: true

                background: Item {
                    Rectangle {
                        color: day.index == 0 ? Material.primary : "transparent"
                        height: parent.height * 0.65
                        width: parent.height * 0.65
                        radius: Material.FullScale

                        anchors {
                            bottom: parent.bottom
                            bottomMargin: -Theme.pixels(0.45)
                            horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
                contentItem: FlexboxLayout {
                    alignItems: FlexboxLayout.AlignCenter
                    direction: FlexboxLayout.Column
                    gap: Theme.pixels(1)
                    justifyContent: FlexboxLayout.JustifyCenter

                    Text {
                        color: day.index == 0 ? Material.primary : Material.foreground
                        fontSizeMode: Text.Fit
                        horizontalAlignment: Text.AlignHCenter
                        text: day.name

                        font {
                            bold: true
                            capitalization: Font.AllUppercase
                            pixelSize: Theme.pixels(2.7)
                        }
                    }

                    Text {
                        color: day.index == 0 ? Material.primaryHighlightedTextColor :
                                                Material.foreground
                        fontSizeMode: Text.Fit
                        horizontalAlignment: Text.AlignHCenter
                        text: day.number

                        font {
                            bold: true
                            pixelSize: Theme.pixels(4.5)
                        }
                    }
                }
            }
        }
    }
}
