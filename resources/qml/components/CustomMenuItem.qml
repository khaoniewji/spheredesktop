// sphere/desktop/resources/qml/components/CustomMenuItem.qml
import QtQuick
import QtQuick.Controls

MenuItem {
    id: menuItem
    height: visible ? 28 : 0

    property bool hasSubmenu: false
    property bool isSubmenuOpen: false

    contentItem: Item {
        Rectangle {
            anchors.fill: parent
            color: menuItem.highlighted ? "#404040" : "transparent"
            opacity: enabled ? 1.0 : 0.3
        }

        Row {
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 12
                rightMargin: 12
            }
            spacing: 8

            Text {
                text: menuItem.text
                font {
                    family: "Segoe UI Variable"
                    pixelSize: 13
                    weight: menuItem.highlighted ? Font.DemiBold : Font.Normal
                }
                color: menuItem.highlighted ? "#FFFFFF" : "#CCCCCC"
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                visible: menuItem.hasSubmenu
                text: "►"
                font.pixelSize: 10
                color: menuItem.highlighted ? "#FFFFFF" : "#CCCCCC"
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
