// sphere/desktop/resources/qml/dock/Dock.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: dockRoot
    color: "#2E2E2E"
    opacity: 0.95
    radius: 12
    height: 64
    width: dockLayout.width + 20

    // Properties
    property int iconSize: 48
    property font iconFont: Qt.font({
        family: "Segoe Fluent Icons",
        fallbackFamilies: ["Segoe MDL2 Assets"],
        pixelSize: 32
    })

    // Main layout
    RowLayout {
        id: dockLayout
        anchors.centerIn: parent
        spacing: 8

        // Pinned apps
        Repeater {
            model: ListModel {
                ListElement { name: "Finder"; icon: "\uE8B7" }
                ListElement { name: "Terminal"; icon: "\uE756" }
                ListElement { name: "Browser"; icon: "\uE774" }
                ListElement { name: "Store"; icon: "\uE719" }
                ListElement { name: "Settings"; icon: "\uE713" }
            }

            delegate: Button {
                Layout.preferredWidth: dockRoot.iconSize
                Layout.preferredHeight: dockRoot.iconSize

                background: Rectangle {
                    color: "transparent"
                    radius: 8

                    // Indicator dot for running apps
                    Rectangle {
                        width: 4
                        height: 4
                        radius: 2
                        color: "white"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        visible: index < 3  // Example: first 3 apps are "running"
                    }
                }

                contentItem: Text {
                    text: icon
                    font: dockRoot.iconFont
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                // Hover animation
                scale: hovered ? 1.1 : 1.0

                Behavior on scale {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.OutCubic
                    }
                }

                ToolTip {
                    visible: parent.hovered
                    text: name
                    font.family: "Segoe UI Variable"
                    font.pixelSize: 13
                }
            }
        }

        // Separator
        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: dockRoot.iconSize - 16
            color: "#555555"
            Layout.alignment: Qt.AlignVCenter
        }

        // Recent apps/files section
        Repeater {
            model: ListModel {
                ListElement { name: "Document.txt"; icon: "\uE8A5" }
                ListElement { name: "Image.jpg"; icon: "\uEB9F" }
            }

            delegate: Button {
                Layout.preferredWidth: dockRoot.iconSize
                Layout.preferredHeight: dockRoot.iconSize

                background: Rectangle {
                    color: "transparent"
                    radius: 8
                }

                contentItem: Text {
                    text: icon
                    font: dockRoot.iconFont
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                scale: hovered ? 1.1 : 1.0

                Behavior on scale {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.OutCubic
                    }
                }

                ToolTip {
                    visible: parent.hovered
                    text: name
                    font.family: "Segoe UI Variable"
                    font.pixelSize: 13
                }
            }
        }
    }
}
