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
#include <GL/gl.h>
#endif

void setupHighDPI() {
    QGuiApplication::setHighDpiScaleFactorRoundingPolicy(
        Qt::HighDpiScaleFactorRoundingPolicy::PassThrough);
}

void setupGraphics() {
    QSurfaceFormat format;
    format.setRenderableType(QSurfaceFormat::OpenGL);
    format.setVersion(4, 3);
    format.setProfile(QSurfaceFormat::CoreProfile);
    format.setSwapInterval(0);  // Disable VSync
    format.setSwapBehavior(QSurfaceFormat::TripleBuffer);

    // Optimize buffer configuration
    format.setSamples(0);
    format.setDepthBufferSize(0);
    format.setStencilBufferSize(0);
    format.setAlphaBufferSize(8);

    QSurfaceFormat::setDefaultFormat(format);
}

void setupRenderingBackend() {
    qputenv("QSG_RENDER_LOOP", "threaded");
    qputenv("QSG_RENDERER", "threaded");
    qputenv("QT_QUICK_BACKEND", "desktop");
    qputenv("QSG_RHI_BACKEND", "opengl");
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");
    qputenv("QSG_NO_VSYNC", "1");
    qputenv("QSG_RENDERER_TIMING", "1");
    qputenv("QT_QUICK_DIRTY_REGIONS", "1");
}

void setupDebugOptions() {
#ifdef QT_DEBUG
    qputenv("QSG_RENDERER_DEBUG", "1");
    qputenv("QT_LOGGING_RULES", "qt.quick.dirty=true");
    qputenv("QSG_INFO", "1");
#endif
}

void setupQmlEngine(QQmlApplicationEngine& engine) {
    engine.addImportPath("qrc:/");
    qmlRegisterType<DesktopManager>("Sphere.Desktop", 1, 0, "DesktopManager");
}

void setupSystemOptimizations() {
#ifdef Q_OS_WIN
    SetPriorityClass(GetCurrentProcess(), HIGH_PRIORITY_CLASS);

    DWORD_PTR processAffinityMask = 0;
    DWORD_PTR systemAffinityMask = 0;
    if (GetProcessAffinityMask(GetCurrentProcess(), &processAffinityMask, &systemAffinityMask)) {
        SetProcessAffinityMask(GetCurrentProcess(), processAffinityMask);
    }

    SetProcessWorkingSetSize(GetCurrentProcess(), -1, -1);
#endif
}

int main(int argc, char *argv[])
{
    // Optimize application startup
    qputenv("QT_ENABLE_GLYPH_CACHE_WORKAROUND", "1");
    qputenv("QT_QPA_DISABLE_MODERN_PROCESS", "1");
    qputenv("QT_ENABLE_SHADER_DISK_CACHE", "1");
    qputenv("QML_DISK_CACHE_ONLY", "1");

    // High performance attributes
    QGuiApplication::setAttribute(Qt::AA_UseDesktopOpenGL);
    QGuiApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
    QGuiApplication::setAttribute(Qt::AA_CompressHighFrequencyEvents);
    QGuiApplication::setAttribute(Qt::AA_DontCheckOpenGLContextThreadAffinity);

    // Setup high DPI support
    setupHighDPI();

    // Setup graphics configuration
    setupGraphics();

    // Create application instance
    QGuiApplication app(argc, argv);

    // Setup system optimizations
    setupSystemOptimizations();

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

#ifdef Q_OS_WIN
        SetThreadExecutionState(ES_CONTINUOUS | ES_DISPLAY_REQUIRED | ES_SYSTEM_REQUIRED);
        SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_HIGHEST);
        timeBeginPeriod(1);
#endif

        // Run the application
        int result = app.exec();

#ifdef Q_OS_WIN
        timeEndPeriod(1);
        SetThreadExecutionState(ES_CONTINUOUS);
#endif

        return result;

    } catch (const std::exception& e) {
        qCritical() << "Fatal error:" << e.what();
        return -1;
    } catch (...) {
        qCritical() << "Unknown fatal error occurred";
        return -1;
    }
}
