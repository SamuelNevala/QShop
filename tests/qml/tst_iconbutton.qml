import QShopper
import QtQuick
import QtQuick.Controls as Controls
import QtTest

Item {
    id: scene

    width: 900
    height: 700

    Binding {
        target: Theme
        property: "parent"
        value: scene
    }

    FontLoader {
        id: glyphFont

        source: "qrc:/qt/qml/QShopper/fa-solid-900.ttf"
    }

    Component {
        id: buttonComponent

        IconButton {
            x: 100
            y: 100
            text: "Clear list"
            icon.name: "\uf1f8"
            font.family: glyphFont.name
        }
    }

    Component {
        id: spyComponent

        SignalSpy {
            signalName: "clicked"
        }
    }

    TestCase {
        readonly property bool hasTextFonts: Qt.fontFamilies().some(family => !family.startsWith(
                                                                                  "Font Awesome"))

        function initTestCase() {
            tryCompare(glyphFont, "status", FontLoader.Ready);
        }

        function init() {
            Theme.scale = 1;
            failOnWarning(/.*Binding loop detected.*/);
        }

        function cleanup() {
            Theme.scale = 1;
        }

        function parts(button) {
            const children = button.contentItem.children;
            return {
                glyph: children.find(item => item instanceof TextIcon),
                caption: children.find(item => item instanceof Text && !(item instanceof TextIcon))
            };
        }

        function test_existing_drawer_geometry_data() {
            const rows = [];
            for (const scale of [1, 2]) {
                for (const entry of [
                         {
                             text: "Dark",
                             width: 8,
                             lines: 1
                         },
                         {
                             text: "Light",
                             width: 8,
                             lines: 1
                         },
                         {
                             text: "System",
                             width: 8,
                             lines: 1
                         },
                         {
                             text: "Reset\nchecks",
                             width: 12,
                             lines: 2
                         },
                         {
                             text: "Remove\nchecked",
                             width: 12,
                             lines: 2
                         },
                         {
                             text: "Clear\nlist",
                             width: 12,
                             lines: 2
                         }
                     ]) {
                    rows.push({
                                  tag: entry.text.replace("\n", "-") + "-" + scale,
                                  entry: entry,
                                  scale: scale
                              });
                }
            }
            return rows;
        }

        function test_existing_drawer_geometry(data) {
            Theme.scale = data.scale;
            const entry = data.entry;
            const button = createTemporaryObject(buttonComponent, scene, {
                                                     implicitWidth: Theme.pixels(entry.width),
                                                     text: entry.text
                                                 });
            verify(button !== null);
            verify(waitForRendering(button));
            const items = parts(button);
            verify(items.glyph !== undefined && items.caption !== undefined);
            compare(items.caption.text, entry.text);

            fuzzyCompare(button.background.width, Theme.pixels(8), 1);
            fuzzyCompare(button.background.height, Theme.pixels(8), 1);
            fuzzyCompare(button.background.x + button.background.width / 2, button.width / 2, 1);
            const glyphPoint = items.glyph.mapToItem(button, 0, 0);
            const captionPoint = items.caption.mapToItem(button, 0, 0);
            fuzzyCompare(glyphPoint.x + items.glyph.width / 2, button.width / 2, 1);
            fuzzyCompare(glyphPoint.y, Theme.pixels(1.25), 1);
            fuzzyCompare(items.glyph.width, Theme.pixels(5.5), 1);
            fuzzyCompare(items.glyph.height, Theme.pixels(5.5), 1);
            fuzzyCompare(captionPoint.x + items.caption.width / 2, button.width / 2, 1);
            fuzzyCompare(captionPoint.y, Theme.pixels(8), 1);
            verify(captionPoint.y + items.caption.height <= button.height + 1);
            verify(items.caption.height >= items.caption.implicitHeight - 1);
            if (hasTextFonts) {
                compare(items.caption.lineCount, entry.lines);
                if (entry.lines === 1) {
                    verify(items.caption.height < Theme.pixels(6));
                }
                verify(!items.caption.truncated);
                verify(items.caption.fontInfo.family !== glyphFont.name);
            }
            button.width = Theme.pixels(18);
            verify(waitForRendering(button));
            fuzzyCompare(button.background.width, Theme.pixels(8), 1);
            fuzzyCompare(button.background.x + button.background.width / 2, button.width / 2, 1);
        }

        function test_display_modes_data() {
            return [
                        {
                            tag: "icon",
                            mode: Controls.AbstractButton.IconOnly,
                            icon: true,
                            text: false
                        },
                        {
                            tag: "text",
                            mode: Controls.AbstractButton.TextOnly,
                            icon: false,
                            text: true
                        },
                        {
                            tag: "beside",
                            mode: Controls.AbstractButton.TextBesideIcon,
                            icon: true,
                            text: true
                        },
                        {
                            tag: "under",
                            mode: Controls.AbstractButton.TextUnderIcon,
                            icon: true,
                            text: true
                        }
                    ];
        }

        function checkMode(button, data) {
            const items = parts(button);
            compare(items.glyph.visible, data.icon);
            compare(items.caption.visible, data.text);
            if (data.mode === Controls.AbstractButton.IconOnly) {
                fuzzyCompare(button.height, Theme.pixels(8), 1);
                fuzzyCompare(button.background.height, Theme.pixels(8), 1);
            }
            if (data.mode === Controls.AbstractButton.TextOnly) {
                const point = items.caption.mapToItem(button, 0, 0);
                fuzzyCompare(point.x + items.caption.width / 2, button.width / 2, 1);
                fuzzyCompare(point.y + items.caption.height / 2, button.height / 2, 1);
            }
            if (data.icon && data.text) {
                const glyphPoint = items.glyph.mapToItem(button, 0, 0);
                const captionPoint = items.caption.mapToItem(button, 0, 0);
                if (data.mode === Controls.AbstractButton.TextBesideIcon) {
                    verify(glyphPoint.x + items.glyph.width <= captionPoint.x + 1);
                    fuzzyCompare(glyphPoint.y + items.glyph.height / 2, captionPoint.y
                                 + items.caption.height / 2, 1);
                } else {
                    verify(glyphPoint.y + items.glyph.height <= captionPoint.y + 1);
                    fuzzyCompare(glyphPoint.x + items.glyph.width / 2, captionPoint.x
                                 + items.caption.width / 2, 1);
                }
            }
        }

        function test_display_modes(data) {
            const button = createTemporaryObject(buttonComponent, scene, {
                                                     display: data.mode
                                                 });
            verify(button !== null);
            verify(waitForRendering(button));
            checkMode(button, data);
            const clicked = createTemporaryObject(spyComponent, scene, {
                                                      target: button
                                                  });
            mouseClick(button, button.width / 2, button.height / 2);
            compare(clicked.count, 1);
            button.enabled = false;
            mouseClick(button, button.width / 2, button.height / 2);
            compare(clicked.count, 1);
        }

        function test_default_and_live_mode_changes() {
            const button = createTemporaryObject(buttonComponent, scene);
            compare(button.display, Controls.AbstractButton.TextUnderIcon);
            for (const data of test_display_modes_data()) {
                button.display = data.mode;
                verify(waitForRendering(button));
                checkMode(button, data);
                verify(button.width > 0 && button.height > 0);
            }
        }

        function test_caption_grows_and_shrinks_with_text() {
            const button = createTemporaryObject(buttonComponent, scene, {
                                                     text: "Dark"
                                                 });
            verify(button !== null);
            verify(waitForRendering(button));
            const caption = parts(button).caption;
            const singleHeight = button.height;
            button.text = "Remove\nchecked";
            verify(waitForRendering(button));
            tryVerify(function () {
                return button.height > singleHeight;
            });
            compare(caption.lineCount, 2);
            button.text = "Dark";
            verify(waitForRendering(button));
            tryVerify(function () {
                return Math.abs(button.height - singleHeight) <= 1;
            });
            compare(caption.lineCount, 1);
        }

        function test_caption_has_two_line_limit() {
            const text = "One\nTwo\nThree";
            const button = createTemporaryObject(buttonComponent, scene, {
                                                     text: text
                                                 });
            verify(button !== null);
            verify(waitForRendering(button));
            const caption = parts(button).caption;
            compare(caption.lineCount, 2);
            verify(caption.truncated);
            compare(button.text, text);
        }

        name: "IconButtonLayout"
        when: windowShown
    }
}
