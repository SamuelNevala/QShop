#include "applanguage.h"
#include "logging.h"

#include <QtCore/QCoreApplication>
#include <QtCore/QLocale>
#include <QtCore/QSettings>
#include <QtGui/QGuiApplication>

namespace {

QString validPreference(const QString &preference)
{
    return preference == QStringLiteral("en") || preference == QStringLiteral("fi")
            ? preference
            : QStringLiteral("system");
}

} // namespace

AppLanguage *AppLanguage::create(QQmlEngine *engine, QJSEngine *)
{
    return new AppLanguage(*engine);
}

AppLanguage::AppLanguage(QQmlEngine &engine)
    : m_engine(engine), m_preference(validPreference(QSettings().value("language").toString()))
{
    applyPreference();
    connect(qGuiApp, &QGuiApplication::applicationStateChanged, this,
            [this](Qt::ApplicationState state) {
                if (state == Qt::ApplicationActive && m_preference == QStringLiteral("system")) {
                    applyPreference();
                }
            });
}

AppLanguage::~AppLanguage()
{
    QCoreApplication::removeTranslator(&m_finnish);
}

QString AppLanguage::preference() const
{
    return m_preference;
}

void AppLanguage::setPreference(const QString &preference)
{
    const auto next = validPreference(preference);
    if (m_preference == next) {
        return;
    }
    m_preference = next;
    QSettings().setValue(QStringLiteral("language"), m_preference);
    applyPreference();
    Q_EMIT preferenceChanged();
}

QString AppLanguage::localeName() const
{
    return m_localeName;
}

QString AppLanguage::systemLocaleName(const QStringList &languages)
{
    for (const auto &language : languages) {
        switch (QLocale(language).language()) {
        case QLocale::Finnish:
            return QStringLiteral("fi_FI");
        case QLocale::English:
            return QStringLiteral("en_GB");
        default:
            break;
        }
    }
    return QStringLiteral("en_GB");
}

void AppLanguage::applyPreference()
{
    auto locale = m_preference == QStringLiteral("system")
            ? systemLocaleName(QLocale::system().uiLanguages())
            : m_preference == QStringLiteral("fi") ? QStringLiteral("fi_FI")
                                                   : QStringLiteral("en_GB");
    if (locale == m_localeName) {
        return;
    }
    if (locale == QStringLiteral("fi_FI")) {
        if (m_finnish.isEmpty() && !m_finnish.load(QStringLiteral(":/i18n/QShopper_fi.qm"))) {
            qCWarning(qshopperAppLog) << "Finnish translation unavailable";
            locale = QStringLiteral("en_GB");
        } else {
            QCoreApplication::installTranslator(&m_finnish);
        }
    } else {
        QCoreApplication::removeTranslator(&m_finnish);
    }
    m_localeName = locale;
    m_engine.retranslate();
    Q_EMIT localeNameChanged();
}
