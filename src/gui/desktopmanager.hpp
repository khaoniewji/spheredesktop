// sphere/desktop/src/gui/desktopmanager.hpp
#pragma once

#include <QObject>
#include <QVariant>
#include <QStringList>
#include <QFileSystemWatcher>
#include <QTimer>
#include <QPointF>

class DesktopManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString wallpaperPath READ wallpaperPath NOTIFY wallpaperChanged)
    Q_PROPERTY(QVariantList desktopItems READ desktopItems NOTIFY desktopItemsChanged)
    Q_PROPERTY(QString wallpaperStyle READ wallpaperStyle NOTIFY wallpaperStyleChanged)
    Q_PROPERTY(QStringList recentWallpapers READ recentWallpapers NOTIFY recentWallpapersChanged)

public:
    explicit DesktopManager(QObject *parent = nullptr);
    ~DesktopManager();

    QString wallpaperPath() const;
    QVariantList desktopItems() const;
    QString wallpaperStyle() const;
    QStringList recentWallpapers() const;

public slots:
    void refresh();
    void openItem(const QString &path);
    void setIconSize(const QString &size);
    void sortBy(const QString &criterion);
    void openPersonalization();
    void setWallpaper(const QString &path);
    void saveIconPosition(int index, qreal x, qreal y);
    void resetIconPositions();
    Q_INVOKABLE QPointF getDefaultPosition(int index) const;  // Add Q_INVOKABLE

signals:
    void wallpaperChanged();
    void desktopItemsChanged();
    void wallpaperStyleChanged();
    void recentWallpapersChanged();

private:
    void loadWallpaperFromRegistry();
    void loadDesktopItems();
    void setupWallpaperWatcher();
    void updateRecentWallpapers(const QString &path);


    static const QString WALLPAPER_REG_KEY;
    static const QString WALLPAPER_REG_VALUE;
    static const QString WALLPAPER_STYLE_VALUE;
    static const int MAX_RECENT_WALLPAPERS = 10;
    static const int GRID_SPACING_X = 120;
    static const int GRID_SPACING_Y = 120;
    static const int GRID_MARGIN = 20;
    static const int ICONS_PER_COLUMN = 6;

    QString m_wallpaperPath;
    QString m_wallpaperStyle;
    QVariantList m_desktopItems;
    QStringList m_recentWallpapers;
    QFileSystemWatcher* m_watcher;
    QTimer* m_registryTimer;
};
