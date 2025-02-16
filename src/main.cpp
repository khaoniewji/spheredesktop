// sphere/desktop/src/main.cpp
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QSurfaceFormat>
#include <QQuickStyle>
#include <QDebug>
#include "gui/mainscreen.hpp"
#include "gui/desktopmanager.hpp"
#ifdef Q_OS_WIN
#include <windows.h>
#endif

void setupHighDPI() {
    QGuiApplication::setHighDpiScaleFactorRoundingPolicy(
        Qt::HighDpiScaleFactorRoundingPolicy::PassThrough);
    QGuiApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);
}

void setupGraphics() {
    QSurfaceFormat format;

    // Basic 2D optimized settings
    format.setRenderableType(QSurfaceFormat::OpenGL);
    format.setSamples(0);  // Disable MSAA for better performance
    format.setSwapInterval(0);  // Disable VSync for unlimited FPS
    format.setSwapBehavior(QSurfaceFormat::DoubleBuffer);

#ifdef QT_DEBUG
    format.setOption(QSurfaceFormat::DebugContext);
#endif

    QSurfaceFormat::setDefaultFormat(format);
}

void setupRenderingBackend() {
    // Enable basic rendering
    QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);

// High performance render loop
#if defined(Q_OS_WIN)
    qputenv("QSG_RENDER_LOOP", "windows");
#else
    qputenv("QSG_RENDER_LOOP", "threaded");
#endif

    // Performance optimizations
    qputenv("QSG_RENDERER", "threaded");
    qputenv("QT_QUICK_BACKEND", "desktop");
    qputenv("QT_QUICK_DIRTY_REGIONS", "1");
    qputenv("QML_DISABLE_ANIMATIONS", "0");
    qputenv("QT_QUICK_NORMAL_RENDERING", "1");
}

void setupDebugOptions() {
#ifdef QT_DEBUG
    qputenv("QSG_RENDERER_DEBUG", "1");
    qputenv("QT_LOGGING_RULES", "qt.quick.dirty=true");
#endif
}

void setupQmlEngine(QQmlApplicationEngine& engine) {
    engine.addImportPath("qrc:/");
    qmlRegisterType<DesktopManager>("Sphere.Desktop", 1, 0, "DesktopManager");
}

int main(int argc, char *argv[])
{
    // Optimize application startup
    qputenv("QT_ENABLE_GLYPH_CACHE_WORKAROUND", "1");
    qputenv("QT_QPA_DISABLE_MODERN_PROCESS", "1");

    // Set application attributes
    QGuiApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);
    QGuiApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
    QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    // Setup high DPI support
    setupHighDPI();

    // Setup graphics configuration
    setupGraphics();

    // Create application instance
    QGuiApplication app(argc, argv);

    // Set application metadata
    app.setApplicationName("Sphere Desktop");
    app.setApplicationVersion("1.0.0");
    app.setOrganizationName("Sphere");
    app.setOrganizationDomain("sphere.desktop");

    // Setup rendering backend
    setupRenderingBackend();

    // Setup debug options in debug builds
    setupDebugOptions();

    // Set the style
    QQuickStyle::setStyle("Basic");

    try {
        MainScreen mainScreen;
        setupQmlEngine(mainScreen.engine());

        if (!mainScreen.initialize()) {
            qCritical() << "Failed to initialize main screen";
            return -1;
        }

// Enable high performance power profile on Windows
#ifdef Q_OS_WIN
        SetThreadExecutionState(ES_CONTINUOUS | ES_DISPLAY_REQUIRED);
#endif

        return app.exec();

    } catch (const std::exception& e) {
        qCritical() << "Fatal error:" << e.what();
        return -1;
    } catch (...) {
        qCritical() << "Unknown fatal error occurred";
        return -1;
    }
}
