import QtQuick
import QtQuick.Controls.Material

Text {
    id: root

    property bool checked: false

    color: checked ? Material.backgroundColor : Material.primaryTextColor
    fontSizeMode: Text.Fit
    elide: Text.ElideRight
    horizontalAlignment: Text.AlignHCenter
    maximumLineCount: 3
    textFormat: Text.PlainText
    verticalAlignment: Text.AlignVCenter
    wrapMode: Text.Wrap

    font {
        bold: true
        pixelSize: Theme.pixels(7)
        strikeout: checked
    }
}
