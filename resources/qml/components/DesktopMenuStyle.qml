// sphere/desktop/resources/qml/components/DesktopMenuStyle.qml
import QtQuick

QtObject {
    property color backgroundColor: "#2A2A2A"
    property color borderColor: "#404040"
    property color highlightColor: "#404040"
    property color textColor: "#CCCCCC"
    property color textColorHighlighted: "#FFFFFF"
    property int itemHeight: 32
    property int menuWidth: 280
    property int radius: 8
    property font menuFont: Qt.font({
        family: "Segoe UI Variable",
        pixelSize: 13
    })
    property font iconFont: Qt.font({
        family: "Segoe Fluent Icons",
        pixelSize: 16
    })
}
