// sphere/desktop/resources/qml/components/ContextMenu.qml
import QtQuick
import QtQuick.Controls

Menu {
    id: menu
    width: 280

    background: Rectangle {
        implicitWidth: menu.width
        color: "#2A2A2A"
        opacity: 0.98
        radius: 8
        border.width: 1
        border.color: "#404040"

        // Inner shadow
        Rectangle {
            anchors.fill: parent
            color: "#1A1A1A"
            radius: 8
            opacity: 0.3
        }
    }

    enter: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 100
            easing.type: Easing.OutCubic
        }
    }

    exit: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1.0
            to: 0.0
            duration: 80
            easing.type: Easing.InCubic
        }
    }
}
