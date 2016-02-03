import QtQuick 2.4

BackgroundItem {
    id: root

    property alias textWidth: text.implicitWidth
    property int padding: theme.margins.small

    color: checked ? "white" : "black"

    Text {
        id: text
        anchors { fill: parent; leftMargin: root.padding; rightMargin: root.padding; margins: theme.margins.small }
        color: checked ? "black" : "white"
        font {
            bold: true
            pixelSize: theme.fonts.large
            strikeout: checked
        }
        fontSizeMode: Text.Fit
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        maximumLineCount: 2
        text: name
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
    }
}
