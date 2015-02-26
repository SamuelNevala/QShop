import QtQuick 2.4

BackgroundItem {
    id: root

    property alias textWidth: text.implicitWidth
    property int padding: theme.margins.small

    color: selected ? "white" : "black"

    Text {
        id: text
        anchors { fill: parent; leftMargin: root.padding; rightMargin: root.padding; margins: theme.margins.small }
        color: selected ? "black" : "white"
        font {
            bold: true
            pixelSize: theme.fonts.large
            strikeout: selected
        }
        fontSizeMode: Text.Fit
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        maximumLineCount: 2
        text: itemText
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
    }
}
