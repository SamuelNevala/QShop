import QtQuick.Controls.Material as Style
import QtQuick as Quick
import QtQuick.Layouts
import Qt.labs.qmlmodels
import QDynamics

pragma ComponentBehavior: Bound

Style.Control {
    id: root

    property Dimensions dimensions

    background: Background {}
    contentItem: ShopView {
        dimensions: root.dimensions
        fontFamily: awsome.name
        onOpenMenu: menu.open()

        Menu {
            id: menu

            contentItem: Quick.ListView {
                delegate: DelegateChooser {
                    role: "type"

                    DelegateChoice {
                        roleValue: "theme"

                        GroupBox {
                            dimensions: root.dimensions
                            title: qsTr("Theme")
                            width: menu.contentItem.width

                            RowLayout {
                                spacing: root.dimensions.mm(0.5)
                                uniformCellSizes: true
                                width: parent.width

                                IconButton {
                                    autoExclusive: true
                                    checked: ThemeManager.theme === Style.Material.Dark
                                    dimensions: root.dimensions
                                    font { family: awsome.name }
                                    icon { name: "\uf186" }
                                    text: qsTr("Dark")
                                    onClicked: ThemeManager.theme = Style.Material.Dark
                                    Layout.fillHeight: true; Layout.fillWidth: true
                                }
                                IconButton {
                                    autoExclusive: true
                                    checked: ThemeManager.theme === Style.Material.Light
                                    dimensions: root.dimensions
                                    font { family: awsome.name }
                                    icon { name: "\uf185" }
                                    text: qsTr("Light")
                                    onClicked: ThemeManager.theme = Style.Material.Light
                                    Layout.fillHeight: true; Layout.fillWidth: true
                                }
                                IconButton {
                                    autoExclusive: true
                                    checked: ThemeManager.theme === Style.Material.System
                                    dimensions: root.dimensions
                                    font { family: awsome.name }
                                    icon { name: "\uf10a" }
                                    text: qsTr("System")
                                    onClicked: ThemeManager.theme = Style.Material.System
                                    Layout.fillHeight: true; Layout.fillWidth: true
                                }
                            }
                        }
                    }
                    DelegateChoice {
                        roleValue: "colors"

                        RowLayout {
                            spacing: root.dimensions.mm(0.5)
                            uniformCellSizes: true
                            width: parent.width

                            ColorComboBox {
                                dimensions: root.dimensions
                                label: qsTr("Accent")
                                onActivated: ThemeManager.accent = currentValue
                                Quick.Component.onCompleted: currentIndex = indexOfValue(ThemeManager.accent)
                                Layout.fillHeight: true; Layout.fillWidth: true
                            }
                            ColorComboBox {
                                dimensions: root.dimensions
                                label: qsTr("Primary")
                                onActivated: ThemeManager.primary = currentValue
                                Quick.Component.onCompleted: currentIndex = indexOfValue(ThemeManager.primary)
                                Layout.fillHeight: true; Layout.fillWidth: true
                            }
                         }
                    }
                }
                model: Quick.ListModel {
                    Quick.ListElement { type: "theme" }
                    Quick.ListElement { type: "colors" }
                }
                spacing: root.dimensions.mm(1)
            }

            dimensions: root.dimensions
            height: root.height; width: root.width * 0.66
        }
    }
    resources: [ Quick.FontLoader { id: awsome; source: Quick.Qt.resolvedUrl("fa-solid-900.ttf") } ]
}
