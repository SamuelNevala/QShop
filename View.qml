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
            onAboutToHide: menu.focus = false

            contentItem: Quick.ListView {
                delegate: DelegateChooser {
                    role: "type"

                    DelegateChoice {
                        roleValue: "theme"

                        GroupBox {
                            dimensions: root.dimensions
                            title: qsTr("Theme")
                            padding:root.dimensions.mm(4)
                            width: menu.contentItem.width


                            FlexboxLayout {
                                direction: FlexboxLayout.Row
                                justifyContent: FlexboxLayout.JustifySpaceBetween
                                width: parent.width

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

                        FlexboxLayout {
                            direction: FlexboxLayout.Row
                            gap: root.dimensions.mm(1)
                            justifyContent: FlexboxLayout.JustifySpaceBetween
                            width: parent.width

                            ColorComboBox {
                                colorFunction: ThemeManager.colorAccent
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
                                console.log("lists", height)
                            }
                        }
                    }
                    DelegateChoice {
                        roleValue: "operations"

                        GroupBox {
                            dimensions: root.dimensions
                            title: qsTr("Actions")
                            width: menu.contentItem.width
                            padding: 24//dimensions.mm(5)

                            FlexboxLayout {
                                direction: FlexboxLayout.Row
                                // gap: root.dimensions.mm(5)
                                justifyContent: FlexboxLayout.JustifySpaceBetween
                                width: parent.width

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
                    DelegateChoice {
                        roleValue: "controls"
                        GroupBox {
                            dimensions: root.dimensions
                            title: qsTr("Swipe sensitivity ") + Math.round(slider.value*100) + "%"
                            width: menu.contentItem.width
                            //padding: dimensions.mm(5)

                            Style.Slider {
                                id: slider
                                from: 0.2
                                stepSize: 0.1
                                snapMode : Style.Slider.SnapAlways
                                to: 3
                                value: ThemeManager.swipeSensitivity
                                width: parent.width
                                onValueChanged: ThemeManager.swipeSensitivity = value
                            }
                        }
                    }
                }
                model: Quick.ListModel {
                    Quick.ListElement { type: "lists" }
                    Quick.ListElement { type: "operations" }
                    Quick.ListElement { type: "theme" }
                    Quick.ListElement { type: "colors" }
                    Quick.ListElement { type: "controls" }
                }
                spacing: root.dimensions.mm(1)
            }

            dimensions: root.dimensions
            height: root.height; width: root.width * 0.66
        }
    }
    resources: [ Quick.FontLoader { id: awsome; source: Quick.Qt.resolvedUrl("fa-solid-900.ttf") } ]
}
