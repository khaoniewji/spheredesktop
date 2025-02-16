// sphere/desktop/src/gui/mainscreen.cpp
#include "mainscreen.hpp"
#include "desktopmanager.hpp"

MainScreen::MainScreen(QObject* parent)
    : QObject(parent)
{
    // Register DesktopManager type
    qmlRegisterType<DesktopManager>("Sphere.Desktop", 1, 0, "DesktopManager");
}

MainScreen::~MainScreen()
{
}

bool MainScreen::initialize()
{
    m_engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));
    return !m_engine.rootObjects().isEmpty();
}
