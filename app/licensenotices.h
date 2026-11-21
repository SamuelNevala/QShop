#ifndef LICENSENOTICES_H
#define LICENSENOTICES_H

#include <QtCore/QObject>
#include <QtCore/QStringList>
#include <QtQml/QQmlEngine>
#include <QtQmlIntegration/qqmlintegration.h>

class LicenseNotices : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QStringList qt READ qt CONSTANT)
    Q_PROPERTY(QStringList fontAwesome READ fontAwesome CONSTANT)
    Q_PROPERTY(QStringList application READ application CONSTANT)
    Q_PROPERTY(QStringList applicationFinnish READ applicationFinnish CONSTANT)

public:
    explicit LicenseNotices(QObject *parent = nullptr);
    [[nodiscard]] const QStringList &qt() const { return m_qt; }
    [[nodiscard]] const QStringList &fontAwesome() const { return m_fontAwesome; }
    [[nodiscard]] const QStringList &application() const { return m_application; }
    [[nodiscard]] const QStringList &applicationFinnish() const { return m_applicationFinnish; }

private:
    QStringList m_qt;
    QStringList m_fontAwesome;
    QStringList m_application;
    QStringList m_applicationFinnish;
};

#endif // LICENSENOTICES_H
