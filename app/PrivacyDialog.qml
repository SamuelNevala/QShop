import QtQuick
import QtQuick.Controls.Material as Controls
import QtQuick.Layouts

Controls.Dialog {
    id: root

    objectName: "privacyDialog"
    title: qsTr("Privacy policy")
    modal: true
    focus: true
    closePolicy: Controls.Popup.CloseOnEscape
    padding: Theme.pixels(2)
    font.pixelSize: Theme.pixels(3.5)

    header: Controls.Label {
        text: root.title
        font: root.font
        padding: root.padding
        wrapMode: Text.WordWrap
    }
    contentItem: Flickable {
        id: policyScroll

        objectName: "privacyScroll"
        contentWidth: width
        clip: true
        acceptedButtons: Qt.LeftButton
        flickableDirection: Flickable.VerticalFlick

        Controls.TextArea.flickable: Controls.TextArea {
            objectName: "privacyText"
            readOnly: true
            selectByMouse: false
            selectByKeyboard: false
            activeFocusOnPress: false
            focusPolicy: Qt.NoFocus
            textFormat: TextEdit.PlainText
            textDocument.source: "privacy-policy.txt"
            wrapMode: TextEdit.Wrap
            font: root.font
            color: Controls.Material.primaryTextColor
            rightPadding: policyBar.width + Theme.pixels(1)
            background: null
            Accessible.role: Accessible.StaticText
            Accessible.name: text
        }
        Controls.ScrollBar.vertical: Controls.ScrollBar {
            id: policyBar

            objectName: "privacyScrollBar"
            policy: Controls.ScrollBar.AlwaysOn
            width: Theme.pixels(3)
            interactive: true
        }
    }
    footer: ColumnLayout {
        IconButton {
            objectName: "closePrivacyButton"
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Theme.pixels(9.27)
            Layout.preferredHeight: Theme.pixels(9.27)
            display: Controls.AbstractButton.IconOnly
            font.family: closeFont.name
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

        source: "fa-solid-900.otf"
    }

    Shortcut {
        sequence: "Back"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        autoRepeat: false

        onActivated: root.close()
    }
}
