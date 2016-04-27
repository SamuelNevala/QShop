#include "theme.h"
#include <QtCore/qmath.h>
#include <QtGui/QGuiApplication>
#include <QtGui/QScreen>
#include <QtGui/QStyleHints>
#include <QtQml/QQmlPropertyMap>
#include <QDebug>

#define REFERENCE_HIGHT 102.0

Theme::Theme(QObject *parent) Q_DECL_NOTHROW
    : QObject(parent)
    , m_height(new QQmlPropertyMap(this))
    , m_fonts(new QQmlPropertyMap(this))
    , m_margins(new QQmlPropertyMap(this))
    , m_constants(new QQmlPropertyMap(this))
    , m_time(new QQmlPropertyMap(this))
    , m_factor(0.0)
    , m_pixelDensity(0.0)
{
    initDisplays();
    setIndex(0);
    calculate();
}

void Theme::calculate()
{
    m_pixelDensity = m_displays.at(m_index).density;
    Q_EMIT pixelDensityChanged();

    const qreal currentHeight =  m_displays.at(m_index).height / m_pixelDensity;
    const qreal ratio = (1.0 + (currentHeight - REFERENCE_HIGHT) / REFERENCE_HIGHT) * m_pixelDensity;

    m_height->insert(QLatin1String("medium"), QVariant(6 * ratio));
    m_height->insert(QLatin1String("large"), QVariant(9.27 * ratio));

    m_margins->insert(QLatin1String("large"), QVariant(3 * ratio));
    m_margins->insert(QLatin1String("medium"), QVariant(1 * ratio));
    m_margins->insert(QLatin1String("small"), QVariant(0.5 * ratio));

    m_fonts->insert(QLatin1String("large"), QVariant(7 * ratio));
    m_fonts->insert(QLatin1String("medium"), QVariant(3.5 * ratio));
    m_fonts->insert(QLatin1String("small"), QVariant(2 * ratio));

    m_constants->insert(QLatin1String("actionThreshold"), QVariant(m_displays.at(m_index).height / 6));
    m_constants->insert(QLatin1String("menuWidth"), QVariant(m_displays.at(m_index).width * 0.833));

    m_time->insert(QLatin1String("long"), QVariant(500));
    m_time->insert(QLatin1String("medium"), QVariant(250));

    QGuiApplication::styleHints()->setStartDragDistance(3 * ratio);
}

QString Theme::title() const
{
    const Display display = m_displays.at(m_index);
    return QString("%1 %2x%3, %4").arg(display.name).arg(display.height).arg(display.width).arg(display.density);
}

int Theme::height() const
{
    return m_displays.at(m_index).height;
}

int Theme::width() const
{
    return m_displays.at(m_index).width;
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
#ifdef QT_DEBUG
    m_displays = {
        { "iPhone 4 (4, 4S)", 960, 640, 12.83464566929 },
        { "Galaxy SIII", 1280, 720, 12.04724409449 },
        { "iPhone 5 (5c, 5s)", 1136, 640, 12.83464566929 },
        { "Galaxy SII", 800, 480, 8.622047244094 },
        { "Google Nexus 4 by LG", 1280, 768, 12.59842519685 },
        { "Google Nexus 5 by LG", 1920, 1080, 17.36220472441 },
        { "Galaxy Nexus", 1280, 720, 12.44094488189 },
        { "Galaxy SIV", 1920, 1080, 17.36220472441 },
        { "Galaxy S Plus", 800, 480, 9.173228346457 },
        { "Galaxy Note II", 1280, 720, 10.51181102362 },
        { "Galaxy S Plus", 800, 480, 9.173228346457 },
        { "Galaxy Note", 1280, 800, 11.22047244094 },
        { "Nokia Lumia 925", 1280, 768, 13.07086614173 },
        { "iPhone (Original - 3GS)", 480, 320, 12.59842519685 },
        { "Nokia Lumia 920", 1280, 768, 13.07086614173 },
        { "Nokia Lumia (710, 800)", 800, 480, 9.92125984252 },
        { "Test", 800, 480, 15.7874015748 },
        { "Nokia Lumia 900", 800, 480, 8.543307086614 },
        { "Nokia Lumia 620", 800, 480, 9.685039370079 },
        { "Nokia Lumia 720", 800, 480, 8.543307086614 },
        { "HTC One", 1920, 1080, 18.42519685039 },
        { "Droid Razr", 960, 540, 10.07874015748 },
        { "Droid 3 & 4", 960, 540, 11.02362204724 },
        { "Droid", 854, 480, 10.43307086614 },
        { "Sony Xperia Z", 1920, 1080, 17.36220472441 },
        { "BlackBerry Q10", 720, 720, 12.99212598425 },
        { "BlackBerry Z10", 1280, 768, 14.0157480315 },
        { "Alcatel One Touch Idol Ultra", 1280, 720, 12.44094488189 },
        { "Samsung Nexus S", 800, 480, 9.251968503937 },
        { "iPhone 6+", 1920, 1080, 15.7874015748 },
        { "iPhone 6", 1334, 750, 12.83464566929 }
    };
#else
    QScreen *screen = qApp->primaryScreen();
    Q_ASSERT(screen);
    m_displays = {{ "", screen->size().height(), screen->size().width(), screen->physicalDotsPerInch() * 0.03937007874016 }};
#endif
}
