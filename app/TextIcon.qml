import QtQuick
import QtQuick.Controls.Material

Text {
    color: Material.backgroundColor
    fontSizeMode: Text.Fit
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    Behavior on opacity {
        DefaultAnimation {}
    }

    font {
        bold: true
        pixelSize: Math.round(height * 0.75)
    }
}
