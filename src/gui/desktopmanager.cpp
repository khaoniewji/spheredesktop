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
    , m_isInitialized(false)
{
    m_registryTimer->setInterval(5000);

    connect(m_registryTimer, &QTimer::timeout,
            this, &DesktopManager::loadWallpaperFromRegistry);

    connect(m_watcher, &QFileSystemWatcher::fileChanged,
            this, [this](const QString &path) {
                if (path == m_wallpaperPath) {
                    updateWallpaperCache(path);
                    loadWallpaperFromRegistry();
                }
            });

    connect(m_watcher, &QFileSystemWatcher::directoryChanged,
            this, &DesktopManager::loadDesktopItems);

    initializeCache();
    loadWallpaperFromRegistry();
    loadDesktopItems();
    setupWallpaperWatcher();

    m_registryTimer->start();
    m_isInitialized = true;
}

DesktopManager::~DesktopManager()
{
    cleanupCache();
}

void DesktopManager::initializeCache()
{
    // Load saved icon positions
    QSettings settings;
    settings.beginGroup("DesktopIcons");
    const QStringList keys = settings.childKeys();
    for (const QString& key : keys) {
        m_iconPositionCache[key] = settings.value(key).toPointF();
    }
    settings.endGroup();

    // Initialize wallpaper cache
    m_wallpaperCache = WallpaperCache{
        QString(),
        QDateTime(),
        QSize(),
        false
    };
}

void DesktopManager::cleanupCache()
{
    // Save icon positions
    QSettings settings;
    settings.beginGroup("DesktopIcons");
    for (auto it = m_iconPositionCache.constBegin(); it != m_iconPositionCache.constEnd(); ++it) {
        settings.setValue(it.key(), it.value());
    }
    settings.endGroup();

    m_iconPositionCache.clear();
}

void DesktopManager::updateWallpaperCache(const QString& path)
{
    QFileInfo fileInfo(path);
    if (!fileInfo.exists()) {
        m_wallpaperCache.isValid = false;
        return;
    }

    if (m_wallpaperCache.path == path &&
        m_wallpaperCache.lastModified == fileInfo.lastModified()) {
        return;
    }

    m_wallpaperCache.path = path;
    m_wallpaperCache.lastModified = fileInfo.lastModified();
    m_wallpaperCache.isValid = true;
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
            updateWallpaperCache(newWallpaperPath);
            updateRecentWallpapers(newWallpaperPath);
            emit wallpaperChanged();
        } else {
            qWarning() << "Wallpaper file not found:" << newWallpaperPath;
            m_wallpaperPath = QString();
            m_wallpaperCache.isValid = false;
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
    if (!m_isInitialized) return;

    m_desktopItems.clear();
    m_desktopItems.reserve(100);  // Reserve space for typical number of items

    QString desktopPath = QStandardPaths::writableLocation(QStandardPaths::DesktopLocation);
    QDir desktopDir(desktopPath);

    QFileInfoList entries = desktopDir.entryInfoList(QDir::AllEntries | QDir::NoDotAndDotDot);

    for (const QFileInfo &entry : entries) {
        QVariantMap item;
        const QString& filePath = entry.filePath();

        // Use cached position if available
        auto cachedPos = m_iconPositionCache.find(filePath);
        if (cachedPos != m_iconPositionCache.end()) {
            item["x"] = cachedPos.value().x();
            item["y"] = cachedPos.value().y();
        }

        item["name"] = entry.fileName();
        item["path"] = filePath;
        item["size"] = entry.size();
        item["lastModified"] = entry.lastModified();
        item["type"] = entry.suffix().toUpper();

        // Optimized icon assignment
        if (entry.isDir()) {
            item["icon"] = QStringLiteral("\uE8B7");
        } else {
            const QString suffix = entry.suffix().toLower();
            if (suffix == QLatin1String("exe") || suffix == QLatin1String("lnk")) {
                item["icon"] = QStringLiteral("\uE756");
            } else if (suffix == QLatin1String("txt") || suffix == QLatin1String("doc") ||
                       suffix == QLatin1String("docx")) {
                item["icon"] = QStringLiteral("\uE8A5");
            } else if (suffix == QLatin1String("jpg") || suffix == QLatin1String("png") ||
                       suffix == QLatin1String("gif")) {
                item["icon"] = QStringLiteral("\uEB9F");
            } else {
                item["icon"] = QStringLiteral("\uE7C3");
            }
        }

        m_desktopItems.append(item);
    }

    // Use stable_sort for better performance on nearly sorted data
    std::stable_sort(m_desktopItems.begin(), m_desktopItems.end(),
                     [](const QVariant &a, const QVariant &b) {
                         return a.toMap()[QStringLiteral("name")].toString() <
                                b.toMap()[QStringLiteral("name")].toString();
                     });

    emit desktopItemsChanged();
}

void DesktopManager::setupWallpaperWatcher()
{
    if (!m_wallpaperPath.isEmpty() && QFile::exists(m_wallpaperPath)) {
        m_watcher->addPath(m_wallpaperPath);
    }

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
    if (!m_isInitialized) return;

    QSettings settings;
    settings.setValue("Desktop/SortBy", criterion);

    auto compareByName = [](const QVariant &a, const QVariant &b) {
        return a.toMap()[QStringLiteral("name")].toString() <
               b.toMap()[QStringLiteral("name")].toString();
    };

    auto compareBySize = [](const QVariant &a, const QVariant &b) {
        return a.toMap()[QStringLiteral("size")].toLongLong() <
               b.toMap()[QStringLiteral("size")].toLongLong();
    };

    auto compareByType = [](const QVariant &a, const QVariant &b) {
        return a.toMap()[QStringLiteral("type")].toString() <
               b.toMap()[QStringLiteral("type")].toString();
    };

    auto compareByDate = [](const QVariant &a, const QVariant &b) {
        return a.toMap()[QStringLiteral("lastModified")].toDateTime() <
               b.toMap()[QStringLiteral("lastModified")].toDateTime();
    };

    if (criterion == "name") {
        std::stable_sort(m_desktopItems.begin(), m_desktopItems.end(), compareByName);
    }
    else if (criterion == "size") {
        std::stable_sort(m_desktopItems.begin(), m_desktopItems.end(), compareBySize);
    }
    else if (criterion == "type") {
        std::stable_sort(m_desktopItems.begin(), m_desktopItems.end(), compareByType);
    }
    else if (criterion == "date") {
        std::stable_sort(m_desktopItems.begin(), m_desktopItems.end(), compareByDate);
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

#ifdef Q_OS_WIN
    SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, (void*)path.utf16(),
                         SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
#endif

    loadWallpaperFromRegistry();
}

void DesktopManager::saveIconPosition(int index, qreal x, qreal y)
{
    if (index >= 0 && index < m_desktopItems.size()) {
        // Create a new map from the existing item
        QVariantMap item = m_desktopItems[index].toMap();

        x = qMax(0.0, x);
        y = qMax(0.0, y);

        const QString path = item["path"].toString();
        m_iconPositionCache[path] = QPointF(x, y);

        item["x"] = x;
        item["y"] = y;

        // Replace the item in the list
        m_desktopItems[index] = item;
    }
}
void DesktopManager::resetIconPositions()
{
    m_iconPositionCache.clear();

    QSettings settings;
    settings.beginGroup("DesktopIcons");
    settings.remove("");
    settings.endGroup();

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
