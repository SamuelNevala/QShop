#ifndef APPLANGUAGE_H
#define APPLANGUAGE_H

#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QStringList>
#include <QtCore/QTranslator>
#include <QtQml/QQmlEngine>
#include <QtQmlIntegration/qqmlintegration.h>

class AppLanguage : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QString preference READ preference WRITE setPreference NOTIFY preferenceChanged)
    Q_PROPERTY(QString localeName READ localeName NOTIFY localeNameChanged)

public:
    static AppLanguage *create(QQmlEngine *engine, QJSEngine *);
    ~AppLanguage() override;

    [[nodiscard]] QString preference() const;
    void setPreference(const QString &preference);
    [[nodiscard]] QString localeName() const;
    [[nodiscard]] static QString systemLocaleName(const QStringList &languages);

Q_SIGNALS:
    void preferenceChanged();
    void localeNameChanged();

private:
    explicit AppLanguage(QQmlEngine &engine);
    void applyPreference();

    QQmlEngine &m_engine;
    QTranslator m_finnish;
    QString m_preference;
    QString m_localeName;
};

#endif // APPLANGUAGE_H
