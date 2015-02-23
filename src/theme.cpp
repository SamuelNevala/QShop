#include "theme.h"
#include <QtCore/qmath.h>
#include <QtGui/QGuiApplication>
#include <QtGui/QScreen>
#include <QtQml/QQmlPropertyMap>
#include <QDebug>

Theme::Theme(QObject *parent)
    : QObject(parent)
    , m_height( new QQmlPropertyMap(this))
    , m_fonts( new QQmlPropertyMap(this))
    , m_margins( new QQmlPropertyMap(this))
    , m_constants( new QQmlPropertyMap(this))
    , m_factor(0.0)
    , m_pixelDensity(0.0)
{
#ifdef QT_DEBUG
    initDisplays();
    setIndex(0);
#endif

    calculate();
}

#ifdef QT_DEBUG
void Theme::calculate()
{
    qreal referenceHeight = 102;
    m_pixelDensity = m_displays.at(m_index).value("density").toReal();
    qreal currentHeight =  m_displays.at(m_index).value("height").toInt() / m_pixelDensity;
    qreal m_ratio = qSqrt(0.76 + (currentHeight - referenceHeight) / referenceHeight) * 1.1;
    Q_EMIT pixelDensityChanged();
    Q_EMIT factorChanged();

    m_height->insert(QLatin1String("medium"), QVariant(6 * m_ratio * m_pixelDensity));
    m_height->insert(QLatin1String("large"), QVariant(9.5 * m_ratio * m_pixelDensity));

    m_margins->insert(QLatin1String("large"), QVariant(3 * m_ratio * m_pixelDensity));
    m_margins->insert(QLatin1String("medium"), QVariant(1 * m_ratio * m_pixelDensity));

    m_fonts->insert(QLatin1String("large"), QVariant(7 * m_ratio * m_pixelDensity));
    m_fonts->insert(QLatin1String("medium"), QVariant(3.5 * m_ratio * m_pixelDensity));
    m_fonts->insert(QLatin1String("small"), QVariant(2 * m_ratio * m_pixelDensity));

    m_constants->insert(QLatin1String("actionThreshold"), QVariant(m_displays.at(m_index).value("height").toInt() / 6));
}

QString Theme::title() const
{
    QHash<QString, QVariant> cell = m_displays.at(m_index);
    return QString("%1 %2x%3, %4").arg(cell.value("name").toString()).arg(cell.value("height").toString()).arg(cell.value("width").toString()).arg(cell.value("density").toString());
}

int Theme::height() const
{
    return m_displays.at(m_index).value("height").toInt();
}

int Theme::width() const
{
    return m_displays.at(m_index).value("width").toInt();
}

void Theme::setIndex(int index)
{
    if (index == m_index) {
        return;
    }
    int boundIndex = qBound(0, index, m_displays.size() - 1);
    m_index = boundIndex;
    calculate();
    Q_EMIT indexChanged();
}

void Theme::initDisplays()
{
    m_displays<<QHash<QString, QVariant>( {{"name", "iPhone 4 (4, 4S)"}, {"height", 960}, {"width", 640}, {"density", 12.83464566929}});
    m_displays<<QHash<QString, QVariant>( {{"name", "Galaxy SIII"}, {"height", 1280}, {"width", 720}, {"density", 12.04724409449}});
    m_displays<<QHash<QString, QVariant>( {{"name", "iPhone 5 (5c, 5s)"}, {"height", 1136}, {"width", 640}, {"density", 12.83464566929}});
    m_displays<<QHash<QString, QVariant>( {{"name", "Galaxy SII"}, {"height", 800}, {"width", 480}, {"density", 8.622047244094}});
    m_displays<<QHash<QString, QVariant>( {{"name", "Google Nexus 4 by LG"}, {"height", 1280}, {"width", 768}, {"density", 12.59842519685}});
    m_displays<<QHash<QString, QVariant>( {{"name", "Google Nexus 5 by LG"}, {"height", 1920}, {"width", 1080}, {"density", 17.36220472441}});
    m_displays<<QHash<QString, QVariant>( {{"name", "Galaxy Nexus"}, {"height", 1280}, {"width", 720}, {"density", 12.44094488189}});
    m_displays<<QHash<QString, QVariant>( {{"name", "Galaxy SIV"}, {"height", 1920}, {"width", 1080}, {"density", 17.36220472441}});
    m_displays<<QHash<QString, QVariant>( {{"name", "Galaxy S Plus"}, {"height", 800}, {"width", 480}, {"density", 9.173228346457}});
    m_displays<<QHash<QString, QVariant>( {{"name", "Galaxy Note II"}, {"height", 1280}, {"width", 720}, {"density", 10.51181102362}});
    m_displays<<QHash<QString, QVariant>( {{"name", "Galaxy S Plus"}, {"height", 800}, {"width", 480}, {"density", 9.173228346457}});
    m_displays<<QHash<QString, QVariant>( {{"name", "Galaxy Note"}, {"height", 1280}, {"width", 800}, {"density", 11.22047244094}});
    m_displays<<QHash<QString, QVariant>( {{"name", "Nokia Lumia 925"}, {"height", 1280}, {"width", 768}, {"density", 13.07086614173}});
    m_displays<<QHash<QString, QVariant>( {{"name", "iPhone (Original - 3GS)"}, {"height", 480}, {"width", 320}, {"density", 12.59842519685}});
    m_displays<<QHash<QString, QVariant>( {{"name", "Nokia Lumia 920"}, {"height", 1280}, {"width", 768}, {"density", 13.07086614173}});
    m_displays<<QHash<QString, QVariant>( {{"name", "Nokia Lumia (710, 800)"}, {"height", 800}, {"width", 480}, {"density", 9.92125984252}});
    m_displays<<QHash<QString, QVariant>( {{"name", "Nokia Lumia 900"}, {"height", 800}, {"width", 480}, {"density", 8.543307086614}});
    m_displays<<QHash<QString, QVariant>( {{"name", "Nokia Lumia 620"}, {"height", 800}, {"width", 480}, {"density", 9.685039370079}});
    m_displays<<QHash<QString, QVariant>( {{"name", "Nokia Lumia 720"}, {"height", 800}, {"width", 480}, {"density", 8.543307086614}});
    m_displays<<QHash<QString, QVariant>( {{"name", "HTC One"}, {"height", 1920}, {"width", 1080}, {"density", 18.42519685039}});
    m_displays<<QHash<QString, QVariant>( {{"name", "Droid Razr"}, {"height", 960}, {"width", 540}, {"density", 10.07874015748}});
    m_displays<<QHash<QString, QVariant>( {{"name", "Droid 3 & 4"}, {"height", 960}, {"width", 540}, {"density", 11.02362204724}});
    m_displays<<QHash<QString, QVariant>( {{"name", "Droid"}, {"height", 854}, {"width", 480}, {"density", 10.43307086614}});
    m_displays<<QHash<QString, QVariant>( {{"name", "Sony Xperia Z"}, {"height", 1920}, {"width", 1080}, {"density", 17.36220472441}});
    m_displays<<QHash<QString, QVariant>( {{"name", "BlackBerry Q10"}, {"height", 720}, {"width", 720}, {"density", 12.99212598425}});
    m_displays<<QHash<QString, QVariant>( {{"name", "BlackBerry Z10"}, {"height", 1280}, {"width", 768}, {"density", 14.0157480315}});
    m_displays<<QHash<QString, QVariant>( {{"name", "Alcatel One Touch Idol Ultra"}, {"height", 1280}, {"width", 720}, {"density", 12.44094488189}});
    m_displays<<QHash<QString, QVariant>( {{"name", "Samsung Nexus S"}, {"height", 800}, {"width", 480}, {"density", 9.251968503937}});
    m_displays<<QHash<QString, QVariant>( {{"name", "iPhone 6+"}, {"height", 1920}, {"width", 1080}, {"density", 15.7874015748}});
    m_displays<<QHash<QString, QVariant>( {{"name", "iPhone 6"}, {"height", 1334}, {"width", 750}, {"density", 12.83464566929}});
}
#else
void Theme::calculate()
{
    qreal referenceHeight = 102;
    QScreen *screen = qApp->primaryScreen();
    m_pixelDensity = screen->physicalDotsPerInch() * 0.03937007874016;
    qreal currentHeight =  screen->size().height() / m_pixelDensity;
    qreal m_ratio = qSqrt(0.7 + (currentHeight - referenceHeight) / referenceHeight) * 1.2;

    Q_EMIT factorChanged();
    Q_EMIT pixelDensityChanged();

    m_height->insert(QLatin1String("medium"), QVariant(6 * m_ratio * m_pixelDensity));
    m_height->insert(QLatin1String("large"), QVariant(9.5 * m_ratio * m_pixelDensity));
    m_margins->insert(QLatin1String("large"), QVariant(3 * m_ratio * m_pixelDensity));
    m_margins->insert(QLatin1String("medium"), QVariant(1 * m_ratio * m_pixelDensity));
    m_fonts->insert(QLatin1String("large"), QVariant(7 * m_ratio * m_pixelDensity));
    m_fonts->insert(QLatin1String("medium"), QVariant(3.5 * m_ratio * m_pixelDensity));
    m_fonts->insert(QLatin1String("small"), QVariant(2 * m_ratio * m_pixelDensity));
    m_constants->insert(QLatin1String("actionThreshold"), QVariant(screen->size().height() / 6));
}
#endif
