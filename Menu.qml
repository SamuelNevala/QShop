import QtQuick.Controls.Material
import QtQuick
import QtQuick.Controls
import QDynamics

Drawer {
    property Dimensions dimensions

    bottomInset: dimensions.mm(2); topInset: dimensions.mm(2)
    bottomPadding: bottomInset + dimensions.mm(1);  topPadding: topInset + dimensions.mm(1)
    padding: dimensions.mm(1)
}
