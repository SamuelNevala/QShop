import QtQuick
import QDynamics
Text {
    fontSizeMode: Text.Fit
    font { pixelSize: Math.round(height * 0.75) }
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    Behavior on opacity { DefaultAnimation { } }
}
