// sphere/desktop/resources/qml/components/CustomMenu.qml
import QtQuick
import QtQuick.Controls

Menu {
    id: customMenu
    topPadding: 4
    bottomPadding: 4

    delegate: CustomMenuItem { }
    // In CustomMenu.qml, add:
    enter: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 100
        }
    }

    exit: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1.0
            to: 0.0
            duration: 100
        }
    }

    background: Rectangle {
        implicitWidth: 200
        color: "#2A2A2A"
        border.color: "#404040"
        border.width: 1
        radius: 4

        Rectangle {
            anchors.fill: parent
            color: "#1A1A1A"
            radius: 4
            opacity: 0.5
        }
    }
}
