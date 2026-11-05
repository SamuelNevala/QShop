#include "licensenotices.h"

#include <QtCore/QFile>
#include <QtCore/QString>
#include <QtCore/QDebug>
#include <QtCore/QStringList>
#include <QtCore/QObject>
#include <QtCore/QtLogging>

namespace {

// NOLINTNEXTLINE(misc-include-cleaner): QStringList's public header is included directly above.
QStringList readNotice(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning().noquote() << "Cannot read bundled license notice:" << path << file.errorString();
        return { LicenseNotices::tr("License information unavailable.") };
    }
    return QString::fromUtf8(file.readAll()).split(QStringLiteral("\n\n"));
}

} // namespace

LicenseNotices::LicenseNotices(QObject *parent)
    : QObject(parent), m_qt(readNotice(QStringLiteral(":/qt/qml/QShopper/licenses/Qt.txt"))),
      m_fontAwesome(readNotice(QStringLiteral(":/qt/qml/QShopper/licenses/FontAwesome.txt")))
{
}
