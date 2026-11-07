#include <QtTest/QTest>
#include <QtTest/qtestcase.h>
#include <QtCore/QFile>
#include <QtCore/QChar>
#include <QtCore/QIODevice>
#include <QtCore/QString>
#include <QtCore/QObject>
#include <QtCore/qtmetamacros.h>
#include <QtGui/QRawFont>
#include <QtGui/QPainterPath>

namespace {

class IconFontTest : public QObject
{
    Q_OBJECT

public:
    explicit IconFontTest(QObject *parent = nullptr) : QObject(parent) { }

private Q_SLOTS:
    static void bundled_glyph_data()
    {
        QTest::addColumn<QString>("glyph");
        QTest::newRow("close") << QStringLiteral("\uf00d");
        QTest::newRow("reset") << QStringLiteral("\uf021");
        QTest::newRow("edit") << QStringLiteral("\uf044");
        QTest::newRow("clear-input") << QStringLiteral("\uf057");
        QTest::newRow("about") << QStringLiteral("\uf05a");
        QTest::newRow("arrow-up") << QStringLiteral("\uf062");
        QTest::newRow("arrow-down") << QStringLiteral("\uf063");
        QTest::newRow("cart") << QStringLiteral("\uf07a");
        QTest::newRow("menu") << QStringLiteral("\uf0c9");
        QTest::newRow("undo") << QStringLiteral("\uf0e2");
        QTest::newRow("system-theme") << QStringLiteral("\uf10a");
        QTest::newRow("light-theme") << QStringLiteral("\uf185");
        QTest::newRow("dark-theme") << QStringLiteral("\uf186");
        QTest::newRow("delete") << QStringLiteral("\uf1f8");
    }

    static void bundled_glyph()
    {
        QFETCH(const QString, glyph);
        QFile file(QStringLiteral(":/qt/qml/QShopper/fa-solid-900.otf"));
        QVERIFY(file.open(QIODevice::ReadOnly));
        const QRawFont font(file.readAll(), 64);
        QVERIFY(font.isValid());
        QCOMPARE(font.familyName(), QStringLiteral("Font Awesome 7 Free"));
        QCOMPARE(font.styleName(), QStringLiteral("Solid"));
        QVERIFY(font.supportsCharacter(glyph.front()));
        const auto glyphs = font.glyphIndexesForString(glyph);
        QCOMPARE(glyphs.size(), 1);
        QVERIFY(glyphs.front() != 0);
        QVERIFY(!font.pathForGlyph(glyphs.front()).isEmpty());
    }

    static void old_font_not_bundled()
    {
        QVERIFY(!QFile::exists(QStringLiteral(":/qt/qml/QShopper/fa-solid-900.ttf")));
    }
};

} // namespace

QTEST_MAIN(IconFontTest)
#include "test_iconfont.moc"
