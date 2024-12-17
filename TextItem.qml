import QtQuick.Controls.Material
import QtQuick
import QDynamics

Text {
    id: root

    property bool checked: false
    property Dimensions dimensions

    color: checked ? Material.backgroundColor : Material.primaryTextColor
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
