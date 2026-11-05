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

public:
    explicit LicenseNotices(QObject *parent = nullptr);
    [[nodiscard]] const QStringList &qt() const { return m_qt; }
    [[nodiscard]] const QStringList &fontAwesome() const { return m_fontAwesome; }

private:
    QStringList m_qt;
    QStringList m_fontAwesome;
};

#endif // LICENSENOTICES_H
