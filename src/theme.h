#ifndef THEME_H
#define THEME_H

#include <QtCore/QObject>
#include <QtQml/QQmlPropertyMap>
#include <QtCore/QVector>

struct Display {
    Display(QString name, int height, int width, qreal density)
        : name(name), height(height), width(width), density(density)
    {}
    QString name;
    int height;
    int width;
    qreal density;
};

class Theme : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QObject *heights READ heights CONSTANT)
    Q_PROPERTY(QObject *fonts READ fonts CONSTANT)
    Q_PROPERTY(QObject *margins READ margins CONSTANT)
    Q_PROPERTY(QObject *constants READ constants CONSTANT)
    Q_PROPERTY(QObject *time READ time CONSTANT)
    Q_PROPERTY(QString title READ title NOTIFY indexChanged)
    Q_PROPERTY(int height READ height NOTIFY indexChanged)
    Q_PROPERTY(int width READ width NOTIFY indexChanged)
    Q_PROPERTY(int index MEMBER m_index WRITE setIndex NOTIFY indexChanged)
    Q_PROPERTY(qreal pixelDensity READ pixelDensity NOTIFY pixelDensityChanged)

public:
    explicit Theme(QObject *parent = 0) Q_DECL_NOTHROW;

    QQmlPropertyMap *heights() const { return m_height; }
    QQmlPropertyMap *fonts() const { return m_fonts; }
    QQmlPropertyMap *margins() const { return m_margins; }
    QQmlPropertyMap *constants() const { return m_constants; }
    QQmlPropertyMap *time() const { return m_time; }

    QString title() const;
    int height() const;
    int width() const;
    void setIndex(int index);
    qreal pixelDensity() const { return m_pixelDensity; }

Q_SIGNALS:
    void pixelDensityChanged();
    void indexChanged();

private:
    void calculate();
    void initDisplays();

    QQmlPropertyMap *m_height;
    QQmlPropertyMap *m_fonts;
    QQmlPropertyMap *m_margins;
    QQmlPropertyMap *m_constants;
    QQmlPropertyMap *m_time;
    qreal m_factor;
    qreal m_pixelDensity;
    int m_index;
    QVector<Display> m_displays;
};

#endif // THEME_H
