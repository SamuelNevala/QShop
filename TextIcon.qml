import QtQuick.Controls.Material
import QtQuick
import QDynamics
Text {
    color: Material.backgroundColor
    fontSizeMode: Text.Fit
    font { bold: true; pixelSize: Math.round(height * 0.75) }
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    Behavior on opacity { DefaultAnimation { } }
}
