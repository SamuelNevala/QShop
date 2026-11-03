pragma ComponentBehavior: Bound
import Qt.labs.qmlmodels
import QtQuick as Quick
import QtQuick.Controls.Material as Style
import QtQuick.Layouts

Style.Control {
    id: root

    readonly property bool backNavigationActive: !menu.visible && shopView.editMode

    function navigateBack() {
        if (menu.visible) {
            menu.close();
        } else if (shopView.editMode) {
            if (Quick.InputMethod.visible) {
                Quick.InputMethod.hide();
            } else {
                shopView.setEditMode(false);
            }
        }
    }

    // Keep interactive content clear of system bars and display cutouts.
    topPadding: Quick.SafeArea.margins.top
    bottomPadding: Quick.SafeArea.margins.bottom + keyboard.occupiedHeight
    leftPadding: Quick.SafeArea.margins.left
    rightPadding: Quick.SafeArea.margins.right
    font.pixelSize: Theme.pixels(3.5)

    background: Quick.Item {
        id: safeAreaBackground

        // Match the normal row surface, including its resting opacity.
        readonly property Quick.color borderColor: Style.Material.backgroundColor

        Background {
            anchors.fill: parent
        }

        Quick.Rectangle {
            height: root.topPadding
            color: safeAreaBackground.borderColor
            opacity: 0.8

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
        }

        Quick.Rectangle {
            height: root.bottomPadding
            color: safeAreaBackground.borderColor
            opacity: 0.8

            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
        }

        Quick.Rectangle {
            width: root.leftPadding
            color: safeAreaBackground.borderColor
            opacity: 0.8

            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                topMargin: root.topPadding
                bottomMargin: root.bottomPadding
            }
        }

        Quick.Rectangle {
            width: root.rightPadding
            color: safeAreaBackground.borderColor
            opacity: 0.8

            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
                topMargin: root.topPadding
                bottomMargin: root.bottomPadding
            }
        }
    }
    contentItem: ShopView {
        id: shopView

        enabled: !menu.visible
        fontFamily: awsome.name

        onOpenMenu: menu.open()

        Menu {
            id: menu

            // Drawers are reparented to the window overlay, outside this
            // control's padded content item.
            y: root.topPadding
            height: root.availableHeight
            width: root.availableWidth * 0.85

            contentItem: Quick.ListView {
                spacing: Theme.pixels(1)

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
                                    text: qsTr("Dark")

                                    onClicked: Theme.theme = Style.Material.Dark

                                    font {
                                        family: awsome.name
                                    }

                                    icon {
                                        name: "\uf186"
                                    }
                                }

                                IconButton {
                                    autoExclusive: true
                                    checked: Theme.theme === Style.Material.Light
                                    highlighted: checked
                                    text: qsTr("Light")

                                    onClicked: Theme.theme = Style.Material.Light

                                    font {
                                        family: awsome.name
                                    }

                                    icon {
                                        name: "\uf185"
                                    }
                                }

                                IconButton {
                                    autoExclusive: true
                                    checked: Theme.theme === Style.Material.System
                                    highlighted: checked
                                    text: qsTr("System")

                                    onClicked: Theme.theme = Style.Material.System

                                    font {
                                        family: awsome.name
                                    }

                                    icon {
                                        name: "\uf10a"
                                    }
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
                                Theme.activeList = currentValue;
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
                                    text: qsTr("Reset\nchecks")

                                    onClicked: {
                                        menu.close();
                                        shopView.reset();
                                    }

                                    font {
                                        family: awsome.name
                                    }

                                    icon {
                                        name: "\uf021"
                                    }
                                }

                                IconButton {
                                    implicitWidth: Theme.pixels(12)
                                    text: qsTr("Remove\nchecked")

                                    onClicked: {
                                        menu.close();
                                        shopView.removeChecked();
                                    }

                                    font {
                                        family: awsome.name
                                    }

                                    icon {
                                        name: "\uf1f8"
                                    }
                                }

                                IconButton {
                                    implicitWidth: Theme.pixels(12)
                                    text: qsTr("Clear\nlist")

                                    onClicked: {
                                        menu.close();
                                        shopView.removeAll();
                                    }

                                    font {
                                        family: awsome.name
                                    }

                                    icon {
                                        name: "\uf1f8"
                                    }
                                }
                            }
                        }
                    }

                    DelegateChoice {
                        roleValue: "controls"

                        GroupBox {
                            title: qsTr("Swipe sensitivity ") + Math.round(slider.value * 100) + "%"
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
                    Quick.ListElement {
                        type: "lists"
                    }

                    Quick.ListElement {
                        type: "operations"
                    }

                    Quick.ListElement {
                        type: "theme"
                    }

                    Quick.ListElement {
                        type: "accent"
                    }

                    Quick.ListElement {
                        type: "primary"
                    }

                    Quick.ListElement {
                        type: "controls"
                    }
                }

                Quick.Shortcut {
                    objectName: "drawerBackShortcut"
                    sequences: ["Back"]
                    enabled: Quick.Qt.platform.os === "android" && menu.visible
                    autoRepeat: false

                    onActivated: menu.close()
                }
            }

            onAboutToShow: listsModel.reload()
            onAboutToHide: menu.focus = false
        }
    }
    resources: [
        Quick.FontLoader {
            id: awsome

            source: Quick.Qt.resolvedUrl("fa-solid-900.ttf")
        }
    ]

    Quick.Shortcut {
        objectName: "androidBackShortcut"
        sequences: ["Back"]
        enabled: Quick.Qt.platform.os === "android" && root.backNavigationActive
        autoRepeat: false

        onActivated: root.navigateBack()
    }

    SortFilterProxyModel {
        id: sortedModel

        sourceModel: Model {
            id: listsModel

            readOnly: true
        }
    }

    DevelopmentKeyboard {
        id: keyboard

        z: 1

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
    }
}
