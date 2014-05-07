import QtQuick 2.2
import QtQuick.Controls.Styles 1.1

TextFieldStyle {
    id: root

    property bool focus

    textColor: "black"
    background: Item {

        property int borderWidth: 4
        property string borerColor: root.focus ? "#33B5E5" : "#0099CC"

        Item {
            anchors { fill: parent }
            clip: true

            Rectangle {
                anchors {
                    fill: parent; leftMargin: -borderWidth
                    rightMargin: -borderWidth; topMargin: -borderWidth
                }
                color: "transparent"
                border.color: borerColor
                border.width: borderWidth
                Behavior on border.color { ColorAnimation { easing.type: Easing.InOutQuad } }
            }
        }

        Item {
            anchors{ bottom: parent.bottom }
            clip: true
            height: borderWidth * 3
            width: parent.width

            Rectangle {
                anchors {
                    fill: parent
                    bottomMargin: -borderWidth; topMargin: -borderWidth
                }
                color: "transparent"
                border.color: borerColor
                border.width: borderWidth
                Behavior on border.color { ColorAnimation { easing.type: Easing.InOutQuad } }
            }
        }
    }
}
