import QtQuick 2.4

BackgroundItem {
    id: root

    color: selected ? "white" : "black"

    Text {
        id: text

        property bool needMargin: mainView.editMode && !(!truncated && root.width > implicitWidth && lineCount <= 1)

        anchors {
            fill: parent
            rightMargin: needMargin ? theme.margins.large : 0
        }
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: selected ? "black" : "white"
        font {
            bold: true
            pixelSize: theme.fonts.large
            strikeout: selected
        }
        fontSizeMode: Text.Fit
        maximumLineCount: 2
        text: itemText
        wrapMode: Text.Wrap
    }
}
