import QtQuick
import QDynamics

Text {
    id: root

    property bool checked
    property Dimensions dimensions

    color: "white"
    font {
        bold: true
        pixelSize: dimensions.mm(7)
        strikeout: checked
    }
    fontSizeMode: Text.Fit
    elide: Text.ElideRight
    horizontalAlignment: Text.AlignHCenter
    maximumLineCount: 8
    textFormat: Text.PlainText
    verticalAlignment: Text.AlignVCenter
    wrapMode: Text.Wrap
}
