// sphere/desktop/src/gui/taskbar.hpp
#pragma once

#include <QObject>

class Taskbar : public QObject {
    Q_OBJECT

public:
    explicit Taskbar(QObject* parent = nullptr);
    ~Taskbar();
};