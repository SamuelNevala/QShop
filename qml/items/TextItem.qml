import QtQuick 2.3

BackgroundItem {
    id: root

    color: selected ? "white" : "black"

    Text {
        id: text

        property bool needMargin: mainView.editMode && !(!truncated && root.width > implicitWidth && lineCount <= 1)

        anchors {
            fill: parent
            rightMargin: needMargin ? constants.largeMargin : 0
        }
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: selected ? "black" : "white"
        font {
            bold: true
            pixelSize: parent.height * 0.8
            strikeout: selected
        }
        fontSizeMode: Text.Fit
        maximumLineCount: 2
        text: itemText
        wrapMode: Text.Wrap
    }
}
