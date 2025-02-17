import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

MenuItem {
    id: menuItem
    height: visible ? 32 : 0
    width: parent.width

    property string icon: ""
    property bool hasSubmenu: false
    property string shortcut: ""

    background: Rectangle {
        color: menuItem.highlighted ? "#404040" : "transparent"
        opacity: menuItem.enabled ? 1.0 : 0.5
    }

    contentItem: RowLayout {
        spacing: 8
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: 16
            rightMargin: 16
        }

        // Icon
        Text {
            visible: menuItem.icon !== ""
            text: menuItem.icon
            font {
                family: "Segoe Fluent Icons"
                pixelSize: 16
            }
            color: menuItem.highlighted ? "#FFFFFF" : "#CCCCCC"
            Layout.preferredWidth: 20
        }

        // Text
        Text {
            text: menuItem.text
            font {
                family: "Segoe UI Variable"
                pixelSize: 13
                weight: menuItem.highlighted ? Font.DemiBold : Font.Normal
            }
            color: menuItem.highlighted ? "#FFFFFF" : "#CCCCCC"
            Layout.fillWidth: true
        }

        // Shortcut
        Text {
            visible: menuItem.shortcut !== ""
            text: menuItem.shortcut
            font {
                family: "Segoe UI Variable"
                pixelSize: 12
            }
            color: menuItem.highlighted ? "#FFFFFF" : "#808080"
            Layout.alignment: Qt.AlignRight
        }

        // Submenu indicator
        Text {
            visible: menuItem.hasSubmenu
            text: "►"
            font.pixelSize: 10
            color: menuItem.highlighted ? "#FFFFFF" : "#808080"
            Layout.alignment: Qt.AlignRight
        }
    }
}
