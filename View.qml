import QtQuick.Controls.Material as Style
import QtQuick as Quick
import QtQuick.Layouts
import Qt.labs.qmlmodels
import QDynamics

pragma ComponentBehavior: Bound

Style.Control {
    id: root

    property Dimensions dimensions

    SortFilterProxyModel {
        id: sortedModel
        sourceModel: Model {
            id: listsModel
            readOnly: true
        }
    }

    background: Background {}
    contentItem: ShopView {
        id: shopView

        dimensions: root.dimensions
        enabled: !menu.visible
        fontFamily: awsome.name
        onOpenMenu: menu.open()

        Menu {
            id: menu

            onAboutToShow: listsModel.reload()

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
                                uniformCellSizes: false
                                width: parent.width
                                Layout.margins: root.dimensions.mm(1)

                                IconButton {
                                    autoExclusive: true
                                    checked: ThemeManager.theme === Style.Material.Dark
                                    highlighted: checked
                                    dimensions: root.dimensions
                                    font { family: awsome.name }
                                    icon { name: "\uf186" }
                                    text: qsTr("Dark")
                                    onClicked: ThemeManager.theme = Style.Material.Dark
                                }
                                Quick.Item { Layout.fillWidth: true }
                                IconButton {
                                    autoExclusive: true
                                    checked: ThemeManager.theme === Style.Material.Light
                                    highlighted: checked
                                    dimensions: root.dimensions
                                    font { family: awsome.name }
                                    icon { name: "\uf185" }
                                    text: qsTr("Light")
                                    onClicked: ThemeManager.theme = Style.Material.Light
                                }
                                Quick.Item { Layout.fillWidth: true }
                                IconButton {
                                    autoExclusive: true
                                    checked: ThemeManager.theme === Style.Material.System
                                    highlighted: checked
                                    dimensions: root.dimensions
                                    font { family: awsome.name }
                                    icon { name: "\uf10a" }
                                    text: qsTr("System")
                                    onClicked: ThemeManager.theme = Style.Material.System
                                }
                            }
                        }
                    }
                    DelegateChoice {
                        roleValue: "colors"

                        RowLayout {
                            spacing: root.dimensions.mm(1)
                            uniformCellSizes: true
                            width: parent.width
                            Layout.margins: root.dimensions.mm(1)

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
                    DelegateChoice {
                        roleValue: "lists"
                        ComboBox {
                            dimensions: root.dimensions
                            model: sortedModel
                            textRole: "name"
                            valueRole: "id"
                            label: qsTr("Lists")
                            width: menu.contentItem.width
                            onActivated: {
                                ThemeManager.activeList = currentValue
                                menu.close();
                            }
                            onCountChanged: {
                                currentIndex = indexOfValue(ThemeManager.activeList)
                            }
                            Quick.Component.onCompleted: {
                                currentIndex = indexOfValue(ThemeManager.activeList)
                            }
                        }
                    }
                    DelegateChoice {
                        roleValue: "operations"
                        GroupBox {
                            dimensions: root.dimensions
                            width: menu.contentItem.width

                            RowLayout {
                                width: parent.width
                                Layout.margins: root.dimensions.mm(1)

                                IconButton {
                                    dimensions: root.dimensions
                                    font { family: awsome.name }
                                    icon { name: "\uf021" }
                                    text: qsTr("Checked")
                                    onClicked: {
                                        menu.close();
                                        shopView.reset();
                                    }
                                }
                                Quick.Item { Layout.fillWidth: true }
                                IconButton {
                                    dimensions: root.dimensions
                                    font { family: awsome.name }
                                    icon { name: "\uf1f8" }
                                    text: qsTr("Checked")
                                    onClicked: {
                                        menu.close();
                                        shopView.removeChecked();
                                    }
                                }
                                Quick.Item { Layout.fillWidth: true }
                                IconButton {
                                    dimensions: root.dimensions
                                    font { family: awsome.name }
                                    icon { name: "\uf1f8" }
                                    text: qsTr("List")
                                    onClicked: {
                                        menu.close();
                                        shopView.removeAll();
                                    }
                                }
                            }
                        }
                    }
                }
                model: Quick.ListModel {
                    Quick.ListElement { type: "lists" }
                    Quick.ListElement { type: "operations" }
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
