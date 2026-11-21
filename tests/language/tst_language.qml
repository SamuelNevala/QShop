import QShopper
import QtQuick
import QtTest

TestCase {
    id: testCase

    function menuSection(drawer, index) {
        const list = drawer.contentItem;
        list.positionViewAtIndex(index, ListView.Contain);
        list.forceLayout();
        tryVerify(() => list.itemAtIndex(index) !== null);
        const section = list.itemAtIndex(index);
        waitForRendering(section);
        return section;
    }

    function choose(selector, code) {
        const index = selector.indexOfValue(code);
        verify(index >= 0);
        mouseClick(selector, selector.width / 2, selector.height * 0.75);
        tryCompare(selector.popup, "opened", true);
        const options = selector.popup.contentItem;
        options.positionViewAtIndex(index, ListView.Contain);
        options.forceLayout();
        const row = options.itemAtIndex(index);
        verify(row !== null);
        mouseClick(row, row.width / 2, row.height / 2);
        tryCompare(selector.popup, "visible", false);
        tryCompare(selector, "currentValue", code);
        tryCompare(AppLanguage, "preference", code);
    }

    function verifyPrivacyPolicy(app, drawer, title, heading, backupHeading) {
        const about = menuSection(drawer, drawer.contentItem.count - 1);
        const button = findChild(about, "privacyButton");
        verify(button !== null);
        compare(button.text, title);
        mouseClick(button, button.width / 2, button.height / 2);
        const dialog = findChild(app, "privacyDialog");
        tryCompare(dialog, "opened", true);
        compare(dialog.title, title);

        const policy = findChild(dialog, "privacyText");
        tryVerify(() => policy.text.startsWith(heading), 3000,
        "The bundled privacy policy should match the selected app language");
        verify(policy.text.includes(backupHeading));
        verify(policy.text.trim().endsWith("samuel.nevala@gmail.com."));
        compare(policy.Accessible.name, policy.text);
        verify(policy.readOnly);

        const close = findChild(dialog, "closePrivacyButton");
        mouseClick(close, close.width / 2, close.height / 2);
        tryCompare(dialog, "visible", false);
        verify(drawer.opened);
    }

    function verifyApplicationLicense(app, drawer, finnish) {
        const about = menuSection(drawer, drawer.contentItem.count - 1);
        const button = findChild(about, "aboutButton");
        verify(button !== null);
        mouseClick(button, button.width / 2, button.height / 2);
        const dialog = findChild(app, "aboutDialog");
        tryCompare(dialog, "opened", true);

        const tab = findChild(dialog, "applicationLicenseTab");
        compare(tab.text, finnish ? "Sovellus" : "App");
        mouseClick(tab, tab.width / 2, tab.height / 2);
        const reader = findChild(dialog, "licenseText");
        const original = LicenseNotices.application.join("\n\n");
        if (finnish) {
            tryVerify(() => reader.model[0] === "QShopperin lisenssi ja lähdekoodi", 3000,
            "The App tab should begin with the Finnish explanation");
            verify(reader.model.join("\n\n").endsWith("\n\n" + original));
        } else {
            tryVerify(() => reader.model.join("\n\n") === original);
        }

        const close = findChild(dialog, "closeAboutButton");
        mouseClick(close, close.width / 2, close.height / 2);
        tryCompare(dialog, "visible", false);
        verify(drawer.opened);
    }

    function test_switch_translates_open_drawer_and_preserves_editor() {
        failOnWarning(/.*Binding loop detected.*/);
        AppLanguage.preference = "system";
        uiSetup.resetDatabase();
        Theme.scale = 1;
        Theme.activeList = "default";
        const component = Qt.createComponent("qrc:/qt/qml/QShopper/main.qml");
        compare(component.status, Component.Ready, component.errorString());
        const app = createTemporaryObject(component, null, {
                                              asynchronous: false
                                          });
        verify(app !== null);
        tryVerify(() => app.contentItem.children[0].item !== null);
        const view = app.contentItem.children[0].item;
        const shop = view.contentItem;
        tryCompare(shop, "editMode", true);
        app.width = Theme.pixels(63);
        const drawer = shop.data.find(child => typeof child.open === "function"
                                               && child.contentItem);
        verify(drawer !== undefined);

        shop.model.insert(0, "Oat milk");
        shop.model.insert(1, "Bread");
        shop.model.insert(3, "Apples");
        shop.model.remove(1);
        tryCompare(shop.model, "editorIndex", 1);
        shop.forceLayout();
        tryVerify(() => shop.itemAtIndex(1) && shop.itemAtIndex(1).item);
        const editor = shop.itemAtIndex(1).item;
        const field = editor.contentItem;
        field.text = "Unfinished draft";
        const selectedList = Theme.activeList;

        shop.openMenu();
        tryCompare(drawer, "opened", true);
        const selector = menuSection(drawer, 6);
        compare(selector.objectName, "languageSelector");
        tryCompare(selector, "currentValue", "system");
        choose(selector, "en");
        compare(selector.label, "Language");
        compare(selector.textAt(0), "System");
        compare(field.placeholderText, "Tap to add items");
        compare(shop.model.undoMessage, "Bread removed");
        compare(findChild(app, "undoBar").message, "Bread removed");

        choose(selector, "fi");
        compare(selector.label, "Kieli");
        compare(selector.Accessible.name, "Kieli");
        tryCompare(selector, "currentText", "Suomi");
        compare(selector.textAt(0), "Järjestelmä");
        compare(selector.textAt(1), "English");
        compare(field.placeholderText, "Lisää tuote napauttamalla");
        tryCompare(findChild(app, "undoBar"), "message", "Bread poistettu");
        compare(uiSetup.restoredLanguage(), "fi");

        const lists = menuSection(drawer, 0);
        compare(lists.label, "Listat");
        verify(lists.find("Hallitse listoja") >= 0);
        compare(lists.currentValue, selectedList);
        compare(lists.currentText, "Oletus");
        const actions = menuSection(drawer, 1);
        compare(actions.title, "Toiminnot");
        const buttons = actions.contentChildren[0].children.filter(item
                                                                   => item instanceof IconButton);
        compare(buttons.map(button => button.text), ["Nollaa\nmerkinnät", "Poista\nmerkityt",
                                                     "Tyhjennä\nlista"]);
        for (const button of buttons) {
            const caption = button.contentItem.children.find(child => child.text === button.text);
            verify(caption !== undefined);
            verify(!caption.truncated, button.text);
        }
        const accent = menuSection(drawer, 3);
        compare(accent.label, "Korostusväri");
        verify(accent.find("Vihreä") >= 0);
        verifyPrivacyPolicy(app, drawer, "Tietosuojakäytäntö", "QShopperin tietosuojakäytäntö",
                            "Androidin varmuuskopiointi");
        verifyApplicationLicense(app, drawer, true);

        drawer.close();
        tryCompare(drawer, "visible", false);
        compare(shop.itemAtIndex(1).item, editor);
        compare(shop.model.editorIndex, 1);
        compare(shop.model.data(shop.model.index(0, 0), Qt.DisplayRole), "Oat milk");
        compare(shop.model.data(shop.model.index(2, 0), Qt.DisplayRole), "Apples");
        compare(Theme.activeList, selectedList);
        compare(field.text, "Unfinished draft");

        shop.model.removeAll();
        tryCompare(findChild(app, "undoBar"), "message", "2 kohdetta poistettu");
        shop.openMenu();
        tryCompare(drawer, "opened", true);
        const reopened = menuSection(drawer, 6);
        choose(reopened, "en");
        tryCompare(findChild(app, "undoBar"), "message", "2 items removed");
        const englishLists = menuSection(drawer, 0);
        compare(englishLists.currentText, "Default");
        verify(englishLists.find("Manage lists") >= 0);
        compare(englishLists.currentValue, selectedList);
        verifyPrivacyPolicy(app, drawer, "Privacy policy", "QShopper privacy policy",
                            "Android backup");
        verifyApplicationLicense(app, drawer, false);
        choose(menuSection(drawer, 6), "system");
        compare(uiSetup.restoredLanguage(), "system");
        app.close();
    }

    name: "AppLanguageSelector"
    when: windowShown
}
