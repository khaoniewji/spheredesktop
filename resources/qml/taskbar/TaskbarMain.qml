// sphere/desktop/resources/qml/taskbar/TaskbarMain.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: taskbarRoot
    color: "#2E2E2E"
    opacity: 0.95
    height: 24  // Fixed height like macOS

    // Properties for customization
    property int iconSize: 16  // Reduced icon size
    property int padding: 2    // Reduced padding
    property string accentColor: "#3DAEE9"

    // Font properties
    property font iconFont: Qt.font({
        family: "Segoe Fluent Icons",
        fallbackFamilies: ["Segoe MDL2 Assets"],
        pixelSize: 12  // Smaller icon font
    })

    property font systemFont: Qt.font({
        family: "Segoe UI Variable",
        fallbackFamilies: ["Segoe UI", "Arial"],
        pixelSize: 11  // Smaller system font
    })

    // Icon constants remain the same
    readonly property var icons: ({
        start: "\uE700",
        windows: "\uE782",
        terminal: "\uE756",
        browser: "\uE774",
        folder: "\uE8B7",
        network: "\uE839",
        volume: "\uE767",
        battery: "\uE83F",
        search: "\uE721",
        settings: "\uE713",
        wifi: "\uE701",
        bluetooth: "\uE702",
        notification: "\uE7E7"
    })

    RowLayout {
        anchors.fill: parent
        spacing: 4  // Reduced spacing
        anchors.margins: 2  // Reduced margins

        // Windows logo
        Button {
            id: windowsButton
            Layout.preferredWidth: taskbarRoot.height - 4  // Adjusted size
            Layout.preferredHeight: taskbarRoot.height - 4
            Layout.alignment: Qt.AlignVCenter

            background: Rectangle {
                color: windowsButton.pressed ? Qt.darker(taskbarRoot.color, 1.2)
                                          : windowsButton.hovered ? Qt.lighter(taskbarRoot.color, 1.1)
                                          : taskbarRoot.color
                radius: 2  // Smaller radius
            }

            Text {
                anchors.centerIn: parent
                text: taskbarRoot.icons.windows
                font: taskbarRoot.iconFont
                color: "white"
            }
        }

        // Active App Name
        Text {
            id: activeAppName
            text: "Sphere Desktop"
            color: "white"
            font: taskbarRoot.systemFont
            Layout.alignment: Qt.AlignVCenter
        }

        // Spacer
        Item {
            Layout.fillWidth: true
        }

        // System Controls
        RowLayout {
            spacing: 2  // Reduced spacing
            Layout.alignment: Qt.AlignVCenter

            // Control Center items
            Repeater {
                model: [
                    { icon: icons.wifi, tooltip: "Wi-Fi" },
                    { icon: icons.bluetooth, tooltip: "Bluetooth" },
                    { icon: icons.volume, tooltip: "Sound" },
                    { icon: icons.battery, tooltip: "Battery" }
                ]

                Button {
                    Layout.preferredWidth: taskbarRoot.height - 6  // Adjusted size
                    Layout.preferredHeight: taskbarRoot.height - 6
                    Layout.alignment: Qt.AlignVCenter

                    background: Rectangle {
                        color: parent.pressed ? Qt.darker(taskbarRoot.color, 1.2)
                                            : parent.hovered ? Qt.lighter(taskbarRoot.color, 1.1)
                                            : taskbarRoot.color
                        radius: 2  // Smaller radius
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        font: taskbarRoot.iconFont
                        color: "white"
                    }

                    ToolTip {
                        visible: parent.hovered
                        text: modelData.tooltip
                        font: taskbarRoot.systemFont
                        delay: 500  // Quicker tooltip
                    }
                }
            }

            // Separator
            Rectangle {
                width: 1
                height: taskbarRoot.height - 8  // Adjusted height
                color: "#555555"
                Layout.alignment: Qt.AlignVCenter
            }

            // Clock - Single line
            Button {
                id: clock
                Layout.preferredHeight: taskbarRoot.height - 4
                Layout.preferredWidth: timeText.width + 16  // Dynamic width
                Layout.alignment: Qt.AlignVCenter

                background: Rectangle {
                    color: clock.pressed ? Qt.darker(taskbarRoot.color, 1.2)
                                       : clock.hovered ? Qt.lighter(taskbarRoot.color, 1.1)
                                       : taskbarRoot.color
                    radius: 2
                }

                Text {
                    id: timeText
                    anchors.centerIn: parent
                    text: new Date().toLocaleTimeString(Qt.locale(), "HH:mm")
                    color: "white"
                    font: taskbarRoot.systemFont
                }

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: timeText.text = new Date().toLocaleTimeString(Qt.locale(), "HH:mm")
                }

                ToolTip {
                    visible: parent.hovered
                    text: new Date().toLocaleDateString(Qt.locale(), "ddd MMM d")
                    font: taskbarRoot.systemFont
                    delay: 500
                }
            }

            // Control Center
            Button {
                Layout.preferredWidth: taskbarRoot.height - 4
                Layout.preferredHeight: taskbarRoot.height - 4
                Layout.alignment: Qt.AlignVCenter

                background: Rectangle {
                    color: parent.pressed ? Qt.darker(taskbarRoot.color, 1.2)
                                        : parent.hovered ? Qt.lighter(taskbarRoot.color, 1.1)
                                        : taskbarRoot.color
                    radius: 2
                }

                Text {
                    anchors.centerIn: parent
                    text: taskbarRoot.icons.settings
                    font: taskbarRoot.iconFont
                    color: "white"
                }

                ToolTip {
                    visible: parent.hovered
                    text: "Control Center"
                    font: taskbarRoot.systemFont
                    delay: 500
                }
            }
        }
    }

    // Bottom shadow
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: "#1A1A1A"
    }
}
