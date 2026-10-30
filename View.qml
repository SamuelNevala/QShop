import QtQuick.Controls.Material as Style
import QtQuick as Quick
import QtQuick.Layouts
import Qt.labs.qmlmodels
pragma ComponentBehavior: Bound

Style.Control {
    id: root
    readonly property bool backNavigationActive: !menu.visible && shopView.editMode

    function navigateBack() {
        if (menu.visible) {
            menu.close()
        } else if (shopView.editMode) {
            if (Quick.InputMethod.visible)
                Quick.InputMethod.hide()
            else
                shopView.setEditMode(false)
        }
    }

    Quick.Shortcut {
        objectName: "androidBackShortcut"
        sequences: ["Back"]
        enabled: Quick.Qt.platform.os === "android" && root.backNavigationActive
        autoRepeat: false
        onActivated: root.navigateBack()
    }

    // Keep interactive content clear of system bars and display cutouts.
    topPadding: Quick.SafeArea.margins.top
    bottomPadding: Quick.SafeArea.margins.bottom + keyboard.occupiedHeight
    leftPadding: Quick.SafeArea.margins.left
    rightPadding: Quick.SafeArea.margins.right
    font.pixelSize: Theme.pixels(3.5)

    SortFilterProxyModel {
        id: sortedModel
        sourceModel: Model {
            id: listsModel
            readOnly: true
        }
    }

    background: Quick.Item {
        id: safeAreaBackground
        // Darken the system-bar and cutout areas without dimming the list.
        readonly property string borderColor: "#A6000000"

        Background { anchors.fill: parent }

        Quick.Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: root.topPadding
            color: safeAreaBackground.borderColor
        }
        Quick.Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: root.bottomPadding
            color: safeAreaBackground.borderColor
        }
        Quick.Rectangle {
            anchors {
                top: parent.top; bottom: parent.bottom; left: parent.left
                topMargin: root.topPadding; bottomMargin: root.bottomPadding
            }
            width: root.leftPadding
            color: safeAreaBackground.borderColor
        }
        Quick.Rectangle {
            anchors {
                top: parent.top; bottom: parent.bottom; right: parent.right
                topMargin: root.topPadding; bottomMargin: root.bottomPadding
            }
            width: root.rightPadding
            color: safeAreaBackground.borderColor
        }
    }
    contentItem: ShopView {
        id: shopView
        enabled: !menu.visible
        fontFamily: awsome.name
        onOpenMenu: menu.open()

        Menu {
            id: menu

            onAboutToShow: listsModel.reload()
            onAboutToHide: menu.focus = false

            contentItem: Quick.ListView {
                Quick.Shortcut {
                    objectName: "drawerBackShortcut"
                    sequences: ["Back"]
                    enabled: Quick.Qt.platform.os === "android" && menu.visible
                    autoRepeat: false
                    onActivated: menu.close()
                }

                delegate: DelegateChooser {
                    role: "type"

                    DelegateChoice {
                        roleValue: "theme"

                        GroupBox {
                            title: qsTr("Theme")
                            width: menu.contentItem.width


                            FlexboxLayout {
                                direction: FlexboxLayout.Row
                                justifyContent: FlexboxLayout.JustifySpaceBetween
                                width: parent.width

                                IconButton {
                                    autoExclusive: true
                                    checked: Theme.theme === Style.Material.Dark
                                    highlighted: checked
                                    font { family: awsome.name }
                                    icon { name: "\uf186" }
                                    text: qsTr("Dark")
                                    onClicked: Theme.theme = Style.Material.Dark
                                }
                                IconButton {
                                    autoExclusive: true
                                    checked: Theme.theme === Style.Material.Light
                                    highlighted: checked
                                    font { family: awsome.name }
                                    icon { name: "\uf185" }
                                    text: qsTr("Light")
                                    onClicked: Theme.theme = Style.Material.Light
                                }
                                IconButton {
                                    autoExclusive: true
                                    checked: Theme.theme === Style.Material.System
                                    highlighted: checked
                                    font { family: awsome.name }
                                    icon { name: "\uf10a" }
                                    text: qsTr("System")
                                    onClicked: Theme.theme = Style.Material.System
                                }
                            }
                        }
                    }
                    DelegateChoice {
                        roleValue: "accent"

                        ColorComboBox {
                            width: menu.contentItem.width
                            colorFunction: Theme.colorAccent
                            label: qsTr("Accent")
                            onActivated: Theme.accent = currentValue
                            Quick.Component.onCompleted: currentIndex = indexOfValue(Theme.accent)
                        }
                    }
                    DelegateChoice {
                        roleValue: "primary"

                        ColorComboBox {
                            width: menu.contentItem.width
                            label: qsTr("Primary")
                            onActivated: Theme.primary = currentValue
                            Quick.Component.onCompleted: currentIndex = indexOfValue(Theme.primary)
                        }
                    }
                    DelegateChoice {
                        roleValue: "lists"

                        ComboBox {
                            model: sortedModel
                            textRole: "name"
                            valueRole: "id"
                            currentValue: Theme.activeList
                            label: qsTr("Lists")
                            width: menu.contentItem.width

                            onActivated: {
                                Theme.activeList = currentValue
                                menu.close();
                            }
                        }
                    }
                    DelegateChoice {
                        roleValue: "operations"

                        GroupBox {
                            title: qsTr("Actions")
                            width: menu.contentItem.width
                            horizontalPadding: Theme.pixels(2)

                            FlexboxLayout {
                                direction: FlexboxLayout.Row
                                justifyContent: FlexboxLayout.JustifySpaceBetween
                                width: parent.width

                                IconButton {
                                    implicitWidth: Theme.pixels(12)
                                    maximumLineCount: 2
                                    font { family: awsome.name }
                                    icon { name: "\uf021" }
                                    text: qsTr("Reset\nchecks")
                                    onClicked: {
                                        menu.close();
                                        shopView.reset();
                                    }
                                }
                                IconButton {
                                    implicitWidth: Theme.pixels(12)
                                    maximumLineCount: 2
                                    font { family: awsome.name }
                                    icon { name: "\uf1f8" }
                                    text: qsTr("Remove\nchecked")
                                    onClicked: {
                                        menu.close();
                                        shopView.removeChecked();
                                    }
                                }
                                IconButton {
                                    implicitWidth: Theme.pixels(12)
                                    maximumLineCount: 2
                                    font { family: awsome.name }
                                    icon { name: "\uf1f8" }
                                    text: qsTr("Clear\nlist")
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
                            title: qsTr("Swipe sensitivity ") + Math.round(slider.value*100) + "%"
                            width: menu.contentItem.width
                            horizontalPadding: Theme.pixels(2)
                            topPadding: topInset + Theme.pixels(1)
                            bottomPadding: Theme.pixels(1)

                            Slider {
                                id: slider
                                from: 0.2
                                stepSize: 0.1
                                snapMode: Slider.SnapAlways
                                to: 3
                                value: Theme.swipeSensitivity
                                width: parent.width
                                onValueChanged: Theme.swipeSensitivity = value
                            }
                        }
                    }
                }
                model: Quick.ListModel {
                    Quick.ListElement { type: "lists" }
                    Quick.ListElement { type: "operations" }
                    Quick.ListElement { type: "theme" }
                    Quick.ListElement { type: "accent" }
                    Quick.ListElement { type: "primary" }
                    Quick.ListElement { type: "controls" }
                }
                spacing: Theme.pixels(1)
            }
            // Drawers are reparented to the window overlay, outside this
            // control's padded content item.
            y: root.topPadding
            height: root.availableHeight; width: root.availableWidth * 0.85
        }
    }
    DevelopmentKeyboard {
        id: keyboard
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        z: 1
    }
    resources: [ Quick.FontLoader { id: awsome; source: Quick.Qt.resolvedUrl("fa-solid-900.ttf") } ]
}
