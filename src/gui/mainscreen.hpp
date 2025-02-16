// sphere/desktop/src/gui/mainscreen.hpp
#pragma once

#include <QObject>
#include <QQmlApplicationEngine>

class MainScreen : public QObject {
    Q_OBJECT

public:
    explicit MainScreen(QObject* parent = nullptr);
    ~MainScreen();

    bool initialize();
    QQmlApplicationEngine& engine() { return m_engine; }

private:
    QQmlApplicationEngine m_engine;
};
