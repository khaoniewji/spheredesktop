// sphere/desktop/src/gui/desktopmanager.cpp
#include "desktopmanager.hpp"
#include <QSettings>
#include <QDir>
#include <QProcess>
#include <QFileSystemWatcher>
#include <QStandardPaths>
#include <QTimer>
#include <QDebug>
#include <QPointF>
#include <QFile>
#include <algorithm>
#ifdef Q_OS_WIN
#include <windows.h>
#endif
const QString DesktopManager::WALLPAPER_REG_KEY = "Control Panel\\Desktop";
const QString DesktopManager::WALLPAPER_REG_VALUE = "Wallpaper";
const QString DesktopManager::WALLPAPER_STYLE_VALUE = "WallpaperStyle";

DesktopManager::DesktopManager(QObject *parent)
    : QObject(parent)
    , m_watcher(new QFileSystemWatcher(this))
    , m_registryTimer(new QTimer(this))
{
    m_registryTimer->setInterval(5000);

    connect(m_registryTimer, &QTimer::timeout,
            this, &DesktopManager::loadWallpaperFromRegistry);

    connect(m_watcher, &QFileSystemWatcher::fileChanged,
            this, [this](const QString &path) {
                if (path == m_wallpaperPath) {
                    loadWallpaperFromRegistry();
                }
            });

    connect(m_watcher, &QFileSystemWatcher::directoryChanged,
            this, &DesktopManager::loadDesktopItems);

    loadWallpaperFromRegistry();
    loadDesktopItems();
    setupWallpaperWatcher();

    m_registryTimer->start();
}

DesktopManager::~DesktopManager()
{
}

QString DesktopManager::wallpaperPath() const
{
    return m_wallpaperPath;
}

QString DesktopManager::wallpaperStyle() const
{
    return m_wallpaperStyle;
}

QVariantList DesktopManager::desktopItems() const
{
    return m_desktopItems;
}

QStringList DesktopManager::recentWallpapers() const
{
    return m_recentWallpapers;
}

void DesktopManager::loadWallpaperFromRegistry()
{
    QSettings settings("HKEY_CURRENT_USER\\" + WALLPAPER_REG_KEY,
                       QSettings::NativeFormat);

    QString newWallpaperPath = settings.value(WALLPAPER_REG_VALUE).toString();
    QString newStyle = settings.value(WALLPAPER_STYLE_VALUE).toString();

    newWallpaperPath = QDir::fromNativeSeparators(newWallpaperPath);

    if (newWallpaperPath != m_wallpaperPath) {
        if (QFile::exists(newWallpaperPath)) {
            m_wallpaperPath = newWallpaperPath;
            updateRecentWallpapers(newWallpaperPath);
            emit wallpaperChanged();
        } else {
            qWarning() << "Wallpaper file not found:" << newWallpaperPath;
            m_wallpaperPath = QString();
            emit wallpaperChanged();
        }
    }

    if (newStyle != m_wallpaperStyle) {
        m_wallpaperStyle = newStyle;
        emit wallpaperStyleChanged();
    }
}

void DesktopManager::loadDesktopItems()
{
    m_desktopItems.clear();

    QString desktopPath = QStandardPaths::writableLocation(QStandardPaths::DesktopLocation);
    QDir desktopDir(desktopPath);

    QFileInfoList entries = desktopDir.entryInfoList(QDir::AllEntries | QDir::NoDotAndDotDot);

    // Load saved positions
    QSettings settings;
    settings.beginGroup("DesktopIcons");

    for (const QFileInfo &entry : entries) {
        QVariantMap item;
        item["name"] = entry.fileName();
        item["path"] = entry.filePath();
        item["size"] = entry.size();
        item["lastModified"] = entry.lastModified();
        item["type"] = entry.suffix().toUpper();

        // Load saved position
        QPointF savedPos = settings.value(entry.filePath(), QPointF()).toPointF();
        if (!savedPos.isNull()) {
            item["x"] = savedPos.x();
            item["y"] = savedPos.y();
        } else {
            // Default positions will be calculated in QML
            item["x"] = QVariant();
            item["y"] = QVariant();
        }

        // Assign appropriate icon based on file type
        if (entry.isDir()) {
            item["icon"] = "\uE8B7"; // Folder icon
        } else {
            QString suffix = entry.suffix().toLower();
            if (suffix == "exe" || suffix == "lnk") {
                item["icon"] = "\uE756"; // Application icon
            } else if (suffix == "txt" || suffix == "doc" || suffix == "docx") {
                item["icon"] = "\uE8A5"; // Document icon
            } else if (suffix == "jpg" || suffix == "png" || suffix == "gif") {
                item["icon"] = "\uEB9F"; // Image icon
            } else {
                item["icon"] = "\uE7C3"; // Generic file icon
            }
        }

        m_desktopItems.append(item);
    }

    settings.endGroup();

    // Optional: Sort items by name initially
    std::sort(m_desktopItems.begin(), m_desktopItems.end(),
              [](const QVariant &a, const QVariant &b) {
                  return a.toMap()["name"].toString() < b.toMap()["name"].toString();
              });

    emit desktopItemsChanged();
}
void DesktopManager::setupWallpaperWatcher()
{
    // Watch the current wallpaper file if it exists
    if (!m_wallpaperPath.isEmpty() && QFile::exists(m_wallpaperPath)) {
        m_watcher->addPath(m_wallpaperPath);
    }

    // Watch desktop folder
    QString desktopPath = QStandardPaths::writableLocation(QStandardPaths::DesktopLocation);
    m_watcher->addPath(desktopPath);
}

void DesktopManager::updateRecentWallpapers(const QString &path)
{
    if (path.isEmpty()) return;

    m_recentWallpapers.removeAll(path);
    m_recentWallpapers.prepend(path);

    while (m_recentWallpapers.size() > MAX_RECENT_WALLPAPERS) {
        m_recentWallpapers.removeLast();
    }

    emit recentWallpapersChanged();
}

void DesktopManager::refresh()
{
    loadWallpaperFromRegistry();
    loadDesktopItems();
}

void DesktopManager::openItem(const QString &path)
{
    QProcess::startDetached("explorer", {path});
}

void DesktopManager::setIconSize(const QString &size)
{
    QSettings settings;
    settings.setValue("Desktop/IconSize", size);
    emit desktopItemsChanged();
}

void DesktopManager::sortBy(const QString &criterion)
{
    QSettings settings;
    settings.setValue("Desktop/SortBy", criterion);

    if (criterion == "name") {
        std::sort(m_desktopItems.begin(), m_desktopItems.end(),
                  [](const QVariant &a, const QVariant &b) {
                      return a.toMap()["name"].toString() < b.toMap()["name"].toString();
                  });
    }
    else if (criterion == "size") {
        std::sort(m_desktopItems.begin(), m_desktopItems.end(),
                  [](const QVariant &a, const QVariant &b) {
                      return a.toMap()["size"].toLongLong() < b.toMap()["size"].toLongLong();
                  });
    }
    else if (criterion == "type") {
        std::sort(m_desktopItems.begin(), m_desktopItems.end(),
                  [](const QVariant &a, const QVariant &b) {
                      return a.toMap()["type"].toString() < b.toMap()["type"].toString();
                  });
    }
    else if (criterion == "date") {
        std::sort(m_desktopItems.begin(), m_desktopItems.end(),
                  [](const QVariant &a, const QVariant &b) {
                      return a.toMap()["lastModified"].toDateTime() <
                             b.toMap()["lastModified"].toDateTime();
                  });
    }

    emit desktopItemsChanged();
}

void DesktopManager::openPersonalization()
{
    QProcess::startDetached("explorer.exe", {"ms-settings:personalization"});
}

void DesktopManager::setWallpaper(const QString &path)
{
    if (!QFile::exists(path)) return;

    QSettings settings("HKEY_CURRENT_USER\\" + WALLPAPER_REG_KEY,
                       QSettings::NativeFormat);
    settings.setValue(WALLPAPER_REG_VALUE, QDir::toNativeSeparators(path));

    // Force Windows to update the wallpaper
    SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, (void*)path.utf16(),
                         SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);

    loadWallpaperFromRegistry();
}


void DesktopManager::saveIconPosition(int index, qreal x, qreal y)
{
    if (index >= 0 && index < m_desktopItems.size()) {
        QVariantMap item = m_desktopItems[index].toMap();

        // Ensure position is within bounds
        x = qMax(0.0, x);
        y = qMax(0.0, y);

        item["x"] = x;
        item["y"] = y;
        m_desktopItems[index] = item;

        // Save position to settings
        QSettings settings;
        settings.beginGroup("DesktopIcons");
        settings.setValue(item["path"].toString(), QPointF(x, y));
        settings.endGroup();
    }
}

void DesktopManager::resetIconPositions()
{
    QSettings settings;
    settings.beginGroup("DesktopIcons");
    settings.remove(""); // Clear all saved positions
    settings.endGroup();

    // Reload items to apply default positions
    loadDesktopItems();
}

QPointF DesktopManager::getDefaultPosition(int index) const
{
    int column = index % ICONS_PER_COLUMN;
    int row = index / ICONS_PER_COLUMN;

    return QPointF(
        column * GRID_SPACING_X + GRID_MARGIN,
        row * GRID_SPACING_Y + GRID_MARGIN
        );
}
