pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material as Controls
import QtQuick.Layouts
import QtQuick.VectorImage

Controls.Dialog {
    id: root

    objectName: "aboutDialog"
    title: qsTr("Open-source licenses")
    modal: true
    focus: true
    closePolicy: Controls.Popup.CloseOnEscape
    padding: Theme.pixels(2)
    font.pixelSize: Theme.pixels(3.5)

    contentItem: ColumnLayout {
        spacing: Theme.pixels(1)

        Controls.TabBar {
            id: tabs

            Layout.fillWidth: true

            Controls.TabButton {
                id: qtTab

                objectName: "qtLicenseTab"
                text: qsTr("Qt")
                display: Controls.AbstractButton.TextBesideIcon
                implicitHeight: Math.max(Theme.pixels(9.27), implicitContentHeight + topPadding
                                         + bottomPadding)

                contentItem: FlexboxLayout {
                    direction: qtTab.display === Controls.AbstractButton.TextUnderIcon
                               ? FlexboxLayout.Column : FlexboxLayout.Row
                    alignItems: FlexboxLayout.AlignCenter
                    justifyContent: FlexboxLayout.JustifyCenter
                    gap: Theme.pixels(1)

                    VectorImage {
                        objectName: "qtLogo"
                        visible: qtTab.display !== Controls.AbstractButton.TextOnly
                        source: "logos/qt.svg"
                        fillMode: VectorImage.PreserveAspectFit
                        preferredRendererType: VectorImage.CurveRenderer
                        Layout.preferredWidth: Theme.pixels(6)
                        Layout.preferredHeight: Theme.pixels(5)
                    }

                    Controls.Label {
                        objectName: "qtTabCaption"
                        visible: qtTab.display !== Controls.AbstractButton.IconOnly
                        Layout.fillWidth: qtTab.display !== Controls.AbstractButton.TextUnderIcon
                        Layout.maximumWidth: qtTab.availableWidth
                        text: qtTab.text
                        fontSizeMode: Text.Fit
                        minimumPixelSize: Theme.pixels(2.5)
                        horizontalAlignment: Text.AlignHCenter
                        color: qtTab.checked ? Controls.Material.accentColor :
                                               Controls.Material.primaryTextColor
                    }
                }
            }

            Controls.TabButton {
                id: fontTab

                objectName: "fontAwesomeLicenseTab"
                text: qsTr("Font Awesome")
                display: Controls.AbstractButton.TextBesideIcon
                implicitHeight: Math.max(Theme.pixels(9.27), implicitContentHeight + topPadding
                                         + bottomPadding)

                contentItem: FlexboxLayout {
                    direction: fontTab.display === Controls.AbstractButton.TextUnderIcon
                               ? FlexboxLayout.Column : FlexboxLayout.Row
                    alignItems: FlexboxLayout.AlignCenter
                    justifyContent: FlexboxLayout.JustifyCenter
                    gap: Theme.pixels(1)

                    VectorImage {
                        objectName: "fontAwesomeLogo"
                        visible: fontTab.display !== Controls.AbstractButton.TextOnly
                        source: "logos/font-awesome.svg"
                        fillMode: VectorImage.PreserveAspectFit
                        preferredRendererType: VectorImage.CurveRenderer
                        Layout.preferredWidth: Theme.pixels(5)
                        Layout.preferredHeight: Theme.pixels(5)
                    }

                    Controls.Label {
                        objectName: "fontAwesomeTabCaption"
                        visible: fontTab.display !== Controls.AbstractButton.IconOnly
                        Layout.fillWidth: fontTab.display !== Controls.AbstractButton.TextUnderIcon
                        Layout.maximumWidth: fontTab.availableWidth
                        text: fontTab.text
                        fontSizeMode: Text.Fit
                        minimumPixelSize: Theme.pixels(2.5)
                        horizontalAlignment: Text.AlignHCenter
                        color: fontTab.checked ? Controls.Material.accentColor :
                                                 Controls.Material.primaryTextColor
                    }
                }
            }
        }

        ListView {
            id: licenseText

            objectName: "licenseText"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Accessible.role: Accessible.List
            Accessible.name: qsTr("License text")
            clip: true
            currentIndex: -1
            contentWidth: width
            flickableDirection: Flickable.VerticalFlick
            spacing: root.font.pixelSize
            model: !root.visible ? null : tabs.currentIndex === 0 ? LicenseNotices.qt :
                                                                    LicenseNotices.fontAwesome

            delegate: Text {
                required property string modelData

                width: licenseText.width - licenseBar.width - Theme.pixels(1)
                text: modelData
                Accessible.role: Accessible.ListItem
                Accessible.name: text
                font: root.font
                color: Controls.Material.primaryTextColor
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
            }
            Controls.ScrollBar.vertical: Controls.ScrollBar {
                id: licenseBar

                objectName: "licenseScrollBar"
                policy: Controls.ScrollBar.AlwaysOn
                interactive: true
                width: Theme.pixels(3)
                minimumSize: Math.min(1, Theme.pixels(9.27) / Math.max(1, availableHeight))
            }

            onModelChanged: positionViewAtBeginning()
        }
    }
    header: Controls.Label {
        text: root.title
        font: root.font
        padding: root.padding
        wrapMode: Text.WordWrap
    }
    footer: ColumnLayout {
        IconButton {
            objectName: "closeAboutButton"
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Theme.pixels(9.27)
            Layout.preferredHeight: Theme.pixels(9.27)
            font.family: closeFont.name
            display: Controls.AbstractButton.IconOnly
            icon.name: "\uf00d"
            text: qsTr("Close")
            topInset: Math.max(0, (height - iconDiameter) / 2)
            bottomInset: topInset

            onClicked: root.close()
            Keys.onReturnPressed: root.close()
        }
    }

    FontLoader {
        id: closeFont

        source: "fa-solid-900.ttf"
    }

    Shortcut {
        sequence: "Back"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        autoRepeat: false

        onActivated: root.close()
    }
}
