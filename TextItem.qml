import QtQuick.Controls.Material
import QtQuick
Text {
    id: root

    property bool checked: false
    color: checked ? Material.backgroundColor : Material.primaryTextColor
    font {
        bold: true
        pixelSize: Theme.pixels(7)
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
