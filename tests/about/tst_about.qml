pragma ComponentBehavior: Bound

import QShopper
import QtQuick
import QtQuick.Controls.Material
import QtQuick.VectorImage
import QtTest

Item {
    width: 600
    height: 900

    Component {
        id: geometryLogo

        VectorImage {
            fillMode: VectorImage.PreserveAspectFit
            preferredRendererType: VectorImage.GeometryRenderer
        }
    }

    TestCase {
        property var app
        property var view
        property var shop
        property var field
        property var drawer
        property var about

        function init() {
            failOnWarning(/.*Binding loop detected.*/);
            uiSetup.resetDatabase();
            Theme.activeList = "default";
            Theme.scale = 1;
            Theme.theme = Material.Dark;
            const component = Qt.createComponent("qrc:/qt/qml/QShopper/main.qml");
            compare(component.status, Component.Ready, component.errorString());
            app = createTemporaryObject(component, null, {
                                            asynchronous: false
                                        });
            verify(app !== null);
            tryCompare(app, "visible", true);
            app.requestActivate();
            tryCompare(app, "active", true);
            view = app.contentItem.children[0].item;
            shop = view.contentItem;
            shop.model.insert(1, "milk");
            shop.model.insert(2, "bread");
            shop.model.setChecked(2, true);
            shop.forceLayout();
            verify(waitForRendering(shop));
            tryVerify(function () {
                for (let row = 0; row < shop.count; ++row) {
                    const item = shop.itemAtIndex(row);
                    if (!item || !item.item || item.x !== 0 || item.item.x !== 0 || Math.abs(item.y
                                                                                             - row * item.height)
                            > 0.01) {
                        return false;
                    }
                }
                return !shop.moving;
            });
            field = shop.itemAtIndex(shop.model.editorIndex).item.contentItem;
            field.insert(0, "unfinished shopping draft");
            tryCompare(app.contentItem.children[0], "opacity", 1);
            drawer = shop.data.find(item => item instanceof Drawer);
            verify(drawer !== undefined);
            about = findChild(view, "aboutDialog");
        }

        function cleanup() {
            Qt.inputMethod.hide();
            if (app) {
                app.close();
                app.destroy();
            }
            wait(0);
        }

        function snapshot() {
            const rows = [];
            for (let row = 0; row < shop.count; ++row) {
                const index = shop.model.index(row, 0);
                rows.push([shop.model.data(index, Qt.DisplayRole), shop.model.data(index, Qt.CheckStateRole),
                           shop.model.data(index, Qt.UserRole + 1)]);
            }
            return JSON.stringify([rows, shop.model.editorIndex, field.text, Theme.activeList]);
        }

        function openAbout() {
            verify(waitForRendering(field));
            mouseClick(field, field.height / 2, field.height / 2);
            tryCompare(drawer, "opened", true);
            compare(drawer.contentItem.clip, true, "Drawer list must clip offscreen controls");
            drawer.contentItem.positionViewAtEnd();
            const last = drawer.contentItem.count - 1;
            tryVerify(function () {
                return drawer.contentItem.itemAtIndex(last);
            });
            const section = drawer.contentItem.itemAtIndex(last);
            verify(section instanceof GroupBox, "About must use the existing drawer group style");
            compare(section.title, "About");
            const button = findChild(section, "aboutButton");
            verify(button !== null, "About must offer Licenses");
            compare(button.text, "Licenses");
            verify(button instanceof IconButton, "About must use the existing drawer button style");
            compare(drawer.contentItem.model.get(last).type, "about");
            verify(about !== null, "About dialog must be available");
            wait(100);
            const started = Date.now();
            mouseClick(button, button.width / 2, button.height / 2);
            tryCompare(about, "opened", true);
            verify(Date.now() - started < 1000, "Opening About must finish within one second: " + (
                       Date.now() - started) + " ms");
            console.info("About opened in " + (Date.now() - started) + " ms");
            return findChild(about, "licenseText");
        }

        function test_notices_and_back_data() {
            return [
                        {
                            tag: "light",
                            theme: Material.Light
                        },
                        {
                            tag: "dark",
                            theme: Material.Dark
                        }
                    ];
        }

        function test_notices_and_back(data) {
            Theme.theme = data.theme;
            const before = snapshot();
            const text = openAbout();
            verify(text !== null);
            tryVerify(() => text.count > 0);
            verify(text.model.join("\n\n").includes("GNU LESSER GENERAL PUBLIC LICENSE"));
            verify(text.model.join("\n\n").includes("GNU GENERAL PUBLIC LICENSE"));
            verify(text.model.join("\n\n").includes("BUNDLED THIRD-PARTY NOTICES"));
            verify(text.model.length > 1000);
            const fontTab = findChild(about, "fontAwesomeLicenseTab");
            mouseClick(fontTab, fontTab.width / 2, fontTab.height / 2);
            tryVerify(function () {
                return text.model.join("\n\n").includes("SIL OPEN FONT LICENSE");
            });
            verify(text.model.join("\n\n").includes("Font Awesome 7 Free Solid, version 7.3.1"));
            verify(text.model.join("\n\n").length > 5000);
            compare(snapshot(), before);
            keyClick(Qt.Key_Back);
            tryCompare(about, "visible", false);
            compare(drawer.opened, true);
            tryCompare(drawer, "activeFocus", true);
            compare(shop.editMode, true);
            compare(snapshot(), before);
        }

        function test_scroll_and_resize_with_safe_areas() {
            const margins = app.contentItem.SafeArea.additionalMargins;
            margins.top = 18;
            margins.bottom = 22;
            margins.left = 12;
            margins.right = 16;
            const before = snapshot();
            const text = openAbout();
            scrollToEnd(text);
            const fontTab = findChild(about, "fontAwesomeLicenseTab");
            mouseClick(fontTab, fontTab.width / 2, fontTab.height / 2);
            tryVerify(function () {
                return text.model.join("\n\n").includes("SIL OPEN FONT LICENSE");
            });
            scrollToEnd(text);
            for (const size of [[360, 650], [500, 800]]) {
                app.width = size[0];
                app.height = size[1];
                wait(80);
                const point = about.parent.mapToItem(app.contentItem, about.x, about.y);
                verify(point.x >= margins.left);
                verify(point.y >= margins.top);
                verify(point.x + about.width <= app.width - margins.right);
                verify(point.y + about.height <= app.height - margins.bottom);
                compare(snapshot(), before);
            }
            const button = findChild(about, "closeAboutButton");
            verify(button !== null);
            mouseClick(button, button.width / 2, button.height / 2);
            tryCompare(about, "visible", false);
            compare(drawer.opened, true);
            compare(snapshot(), before);
        }

        function test_text_not_selectable() {
            const text = openAbout();
            mouseDrag(text, 20, 20, 120, 35, Qt.LeftButton, Qt.NoModifier, 20);
            compare(text.selectedText || "", "",
                    "Reading or dragging must not select license text");
        }

        function test_drawer_clips_scrolled_controls() {
            app.height = 300;
            mouseClick(field, field.height / 2, field.height / 2);
            tryCompare(drawer, "opened", true);
            const list = drawer.contentItem;
            list.positionViewAtIndex(1, ListView.Beginning);
            list.forceLayout();
            list.contentY += Theme.pixels(10);
            const surface = list.parent;
            app.update();
            verify(waitForRendering(surface));
            const shown = grabImage(surface);
            list.opacity = 0;
            app.update();
            verify(waitForRendering(surface));
            const hidden = grabImage(surface);
            list.opacity = 1;
            const origin = list.mapToItem(surface, 0, 0);
            const scaleX = shown.width / surface.width;
            const scaleY = shown.height / surface.height;
            let leaked = 0;
            for (let y = 0; y < shown.height; ++y) {
                if (y < origin.y * scaleY || y >= (origin.y + list.height) * scaleY) {
                    for (let x = Math.ceil((origin.x + Theme.pixels(5)) * scaleX); x < (origin.x
                                                                                        + list.width
                                                                                        - Theme.pixels(
                                                                                            5)) * scaleX; ++x) {
                        const actual = shown.pixel(x, y);
                        const expected = hidden.pixel(x, y);
                        if (Math.max(Math.abs(actual.r - expected.r), Math.abs(actual.g
                                                                               - expected.g),
                                     Math.abs(actual.b - expected.b)) > 0.02) {
                            ++leaked;
                        }
                    }
                }
            }
            compare(leaked, 0, "Scrolled drawer controls must not paint outside the list viewport");
        }

        function test_body_swipes_scroll() {
            const text = openAbout();
            const start = text.contentY;
            const touch = touchEvent(text);
            touch.press(0, text, text.width / 2, text.height * 0.8).commit();
            wait(30);
            touch.move(0, text, text.width / 2, text.height * 0.5).commit();
            wait(30);
            touch.move(0, text, text.width / 2, text.height * 0.25).commit();
            touch.release(0, text, text.width / 2, text.height * 0.2).commit();
            tryVerify(() => text.contentY > start + Theme.pixels(2), 1000);
            tryCompare(text, "moving", false, 5000);
            const scrolled = text.contentY;
            mouseDrag(text, text.width / 2, text.height * 0.25, 0, text.height * 0.5, Qt.LeftButton,
                      Qt.NoModifier, 30);
            tryVerify(() => text.contentY < scrolled - Theme.pixels(2), 1000);
        }

        function test_header_and_footer() {
            const text = openAbout();
            compare(about.title, "Open-source licenses");
            const close = findChild(about, "closeAboutButton");
            const origin = close.mapToItem(about.contentItem.parent, 0, 0);
            const list = text.mapToItem(about.contentItem.parent, 0, text.height);
            fuzzyCompare(origin.x + close.width / 2, about.width / 2, 1);
            verify(origin.y >= list.y);
            for (const entry of [["qtLicenseTab", "qtLogo", "qtTabCaption"],
                                 ["fontAwesomeLicenseTab", "fontAwesomeLogo",
                                  "fontAwesomeTabCaption"]]) {
                const tab = findChild(about, entry[0]);
                const logo = findChild(about, entry[1]);
                const caption = findChild(about, entry[2]);
                for (const mode of [AbstractButton.IconOnly, AbstractButton.TextOnly,
                                    AbstractButton.TextUnderIcon, AbstractButton.TextBesideIcon]) {
                    tab.display = mode;
                    app.update();
                    verify(waitForRendering(tab));
                    compare(logo.visible, mode !== AbstractButton.TextOnly);
                    compare(caption.visible, mode !== AbstractButton.IconOnly);
                    if (mode === AbstractButton.TextUnderIcon) {
                        verify(caption.y >= logo.y + logo.height);
                    } else if (mode === AbstractButton.TextBesideIcon) {
                        verify(caption.x >= logo.x + logo.width);
                    }
                }
            }
        }

        function test_logo_edges() {
            openAbout();
            const surface = about.contentItem.parent;
            function edgePixels(image, logo, name) {
                const origin = logo.mapToItem(surface, 0, 0);
                const scaleX = image.width / surface.width;
                const scaleY = image.height / surface.height;
                const left = Math.round(origin.x * scaleX);
                const top = Math.round(origin.y * scaleY);
                const palette = name === "qtLogo" ? [image.pixel(left, top), Qt.color("#41cd52"),
                                                     Qt.color("white")] : [image.pixel(left, top),
                                                                           Qt.color("#528dd7")];
                let smooth = 0;
                for (let y = top; y < top + Math.floor(logo.height * scaleY); ++y) {
                    for (let x = left; x < left + Math.floor(logo.width * scaleX); ++x) {
                        const pixel = image.pixel(x, y);
                        const solid = palette.some(color => Math.max(Math.abs(pixel.r - color.r),
                                                                     Math.abs(pixel.g - color.g),
                                                                     Math.abs(pixel.b - color.b))
                                                            < 0.015);
                        if (!solid) {
                            ++smooth;
                        }
                    }
                }
                return smooth;
            }
            for (const name of ["qtLogo", "fontAwesomeLogo"]) {
                const logo = findChild(about, name);
                if (GraphicsInfo.api === GraphicsInfo.Software) {
                    compare(logo.preferredRendererType, VectorImage.CurveRenderer);
                } else {
                    app.update();
                    verify(waitForRendering(logo));
                    const smooth = edgePixels(grabImage(surface), logo, name);
                    const origin = logo.mapToItem(surface, 0, 0);
                    logo.opacity = 0;
                    const reference = createTemporaryObject(geometryLogo, surface, {
                                                                x: origin.x,
                                                                y: origin.y,
                                                                width: logo.width,
                                                                height: logo.height,
                                                                source: "qrc:/qt/qml/QShopper/logos/"
                                                                        + (name === "qtLogo"
                                                                           ? "qt.svg" :
                                                                             "font-awesome.svg"),
                                                                z: 100
                                                            });
                    tryCompare(reference, "status", VectorImage.Ready);
                    app.update();
                    verify(waitForRendering(reference));
                    const aliased = edgePixels(grabImage(surface), logo, name);
                    reference.destroy();
                    logo.opacity = 1;
                    console.info(name + " smooth edge pixels=" + smooth + ", geometry=" + aliased);
                    verify(smooth > aliased + 2, name
                           + " must smooth the geometry renderer's jagged edges");
                }
            }
        }

        function test_tab_switch_is_responsive() {
            const text = openAbout();
            for (const name of ["fontAwesomeLicenseTab", "qtLicenseTab", "fontAwesomeLicenseTab",
                                "qtLicenseTab"]) {
                const started = Date.now();
                const tab = findChild(about, name);
                mouseClick(tab, tab.width / 2, tab.height / 2);
                verify(waitForRendering(text));
                const elapsed = Date.now() - started;
                verify(elapsed < 500, "Switching license tab took " + elapsed + " ms");
                verify(text.atYBeginning);
                console.info(name + " rendered in " + elapsed + " ms");
            }
            const qtLogo = findChild(about, "qtLogo");
            const fontLogo = findChild(about, "fontAwesomeLogo");
            tryCompare(qtLogo, "status", VectorImage.Ready);
            tryCompare(fontLogo, "status", VectorImage.Ready);
            verify(qtLogo.width > 0 && qtLogo.height > 0);
            verify(fontLogo.width > 0 && fontLogo.height > 0);
            // Offscreen's dummy font cannot establish fitted text geometry.
            if (Qt.fontFamilies().some(family => !family.startsWith("Font Awesome"))) {
                for (const name of ["qtTabCaption", "fontAwesomeTabCaption"]) {
                    const caption = findChild(about, name);
                    verify(caption.contentWidth <= caption.width + 1,
                           "Tab caption must fit beside its logo");
                }
            }
            const close = findChild(about, "closeAboutButton");
            verify(close instanceof IconButton, "Close must use the existing IconButton style");
            compare(close.display, AbstractButton.IconOnly);
            compare(close.icon.name, "\uf00d");
            compare(close.text, "Close");
            fuzzyCompare(close.background.width, close.background.height, 1);
            verify(close.width >= Theme.pixels(9.27));
            close.forceActiveFocus();
            keyClick(Qt.Key_Return);
            tryCompare(about, "visible", false);
            compare(drawer.opened, true);
        }

        function scrollToEnd(text) {
            app.update();
            verify(waitForRendering(text));
            const flickable = text;
            flickable.forceLayout();
            verify(flickable.contentHeight > flickable.height);
            const bar = text.ScrollBar.vertical;
            const end = bar.height - bar.bottomPadding;
            // Newly exposed paragraphs can change ListView's estimated extent.
            // Continue from the actual thumb position, without bypassing input.
            for (let drag = 0; drag < 3 && !flickable.atYEnd; ++drag) {
                const thumbCenter = bar.topPadding + bar.availableHeight * (bar.visualPosition
                                                                            + bar.visualSize / 2);
                mousePress(bar, bar.width / 2, thumbCenter);
                for (let step = 1; step <= 20; ++step) {
                    mouseMove(bar, bar.width / 2, thumbCenter + (end - thumbCenter) * step / 20,
                              20);
                    app.update();
                    verify(waitForRendering(text));
                }
                mouseRelease(bar, bar.width / 2, end);
                app.update();
                verify(waitForRendering(text));
            }
            tryVerify(function () {
                return flickable.atYEnd;
            });
        }

        name: "AboutLicenses"
        when: windowShown
    }
}
