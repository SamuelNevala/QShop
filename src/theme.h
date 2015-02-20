#ifndef THEME_H
#define THEME_H

#include <QtCore/QObject>
#include <QtQml/QQmlPropertyMap>

#ifdef QT_DEBUG
#include <QtCore/QVector>
#include <QtCore/QHash>
#endif

class Theme : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QObject *heights READ heights CONSTANT)
    Q_PROPERTY(QObject *fonts READ fonts CONSTANT)
    Q_PROPERTY(QObject *margins READ margins CONSTANT)
    Q_PROPERTY(QObject *constants READ constants CONSTANT)
    Q_PROPERTY(qreal pixelDensity READ pixelDensity NOTIFY pixelDensityChanged)
    Q_PROPERTY(qreal factor READ factor NOTIFY factorChanged)

#ifdef QT_DEBUG
    Q_PROPERTY(QString title READ title NOTIFY indexChanged)
    Q_PROPERTY(int height READ height NOTIFY indexChanged)
    Q_PROPERTY(int width READ width NOTIFY indexChanged)
    Q_PROPERTY(int index READ index WRITE setIndex NOTIFY indexChanged)
#endif

public:
    explicit Theme(QObject *parent = 0);

    QQmlPropertyMap *heights() const { return m_height; }
    QQmlPropertyMap *fonts() const { return m_fonts; }
    QQmlPropertyMap *margins() const { return m_margins; }
    QQmlPropertyMap *constants() const { return m_constants; }
    qreal pixelDensity() const { return m_pixelDensity; }
    qreal factor() const { return m_factor; }

#ifdef QT_DEBUG
    QString title() const;
    int height() const;
    int width() const;
    int index() const { return m_index; }
    void setIndex(int index);
#endif

Q_SIGNALS:
    void pixelDensityChanged();
    void factorChanged();

#ifdef QT_DEBUG
    void indexChanged();
#endif

private:
    void calculate();
    QQmlPropertyMap *m_height;
    QQmlPropertyMap *m_fonts;
    QQmlPropertyMap *m_margins;
    QQmlPropertyMap *m_constants;
    qreal m_factor;
    qreal m_pixelDensity;

#ifdef QT_DEBUG
    void initDisplays();
    QVector<QHash<QString,QVariant> > m_displays;
    int m_index;
#endif
};

#endif // THEME_H
