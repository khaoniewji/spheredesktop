// sphere/desktop/resources/qml/main.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Sphere.Desktop 1.0
import QtQuick.Effects
import "./taskbar" as Taskbar
import "./components" as Components


Window {
    id: root
    width: Screen.width
    height: Screen.height
    visible: true
    title: "Sphere Desktop"
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"

    // Properties
    property bool debugMode: true
    property int windowBorderRadius: 8
    property color windowBorderColor: "#1A1A1A"

    // Performance properties
    property bool fastRendering: true

    Component.onCompleted: {
        if (fastRendering) {
            QQuickWindow.sceneGraphBackend = "threaded"
            QQuickWindow.graphicsApi = "opengl"
        }
    }

    DesktopManager {
        id: desktopManager
    }

    Components.DesktopMenuStyle {
        id: menuStyle
    }

    // Window background
    Rectangle {
        id: windowFrame
        anchors.fill: parent
        color: "#2E2E2E"
        radius: windowBorderRadius
        border {
            width: 1
            color: windowBorderColor
        }
    }

    // Desktop background with optimizations
    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        anchors.margins: 1
        color: "#000000"

        ShaderEffectSource {
            id: wallpaperSource
            anchors.fill: parent
            sourceItem: Image {
                id: wallpaperImage
                width: wallpaperSource.width
                height: wallpaperSource.height
                source: desktopManager.wallpaperPath ? "file:///" + desktopManager.wallpaperPath : ""
                fillMode: {
                    switch(desktopManager.wallpaperStyle) {
                        case "0": return Image.PreserveAspectFit;
                        case "2": return Image.PreserveAspectCrop;
                        case "6": return Image.PreserveAspectCrop;
                        case "10": return Image.PreserveAspectCrop;
                        case "22": return Image.Tile;
                        default: return Image.PreserveAspectCrop;
                    }
                }
                asynchronous: true
                cache: true
                smooth: false
                mipmap: true

                sourceSize {
                    width: Screen.width
                    height: Screen.height
                }
            }
            live: false
            hideSource: true
            smooth: false
            // textureProvider: true
            recursive: false
        }

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.02
        }
    }

    // Window drag area
    MouseArea {
        id: windowDragArea
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: 24
        property point clickPos: "1,1"

        onPressed: (mouse) => {
            clickPos = Qt.point(mouse.x, mouse.y)
        }

        onPositionChanged: (mouse) => {
            if (pressed) {
                let delta = Qt.point(mouse.x - clickPos.x, mouse.y - clickPos.y)
                root.x += delta.x
                root.y += delta.y
            }
        }
    }

    // Desktop icons area with optimization
    Item {
        id: desktopIconsArea
        anchors {
            top: taskbar.bottom
            left: parent.left
            right: parent.right
            bottom: dock.top
            margins: 1
        }

        // Selection rectangle with hardware acceleration
        Rectangle {
            id: selectionRect
            visible: false
            color: "#3373737F"
            border.color: "#737373"
            border.width: 1
            z: 1000
            antialiasing: true
            layer.enabled: root.useHardwareAcceleration
        }

        // Optimized desktop icons
        Repeater {
            model: desktopManager.desktopItems
            delegate: Item {
                id: iconDelegate
                width: 100
                height: 100
                x: modelData.x !== undefined ? modelData.x : desktopManager.getDefaultPosition(index).x
                y: modelData.y !== undefined ? modelData.y : desktopManager.getDefaultPosition(index).y

                property bool isSelected: false

                // Optimize rendering by disabling when not visible
                visible: {
                    let itemRect = Qt.rect(x, y, width, height)
                    let viewRect = Qt.rect(0, 0, desktopIconsArea.width, desktopIconsArea.height)
                    return root.intersectRect(itemRect, viewRect)
                }

                Rectangle {
                    anchors.fill: parent
                    color: iconDelegate.isSelected ? "#3373737F" : "transparent"
                    radius: 5
                    visible: iconDelegate.isSelected || dragArea.drag.active
                    antialiasing: true
                    layer.enabled: visible && root.useHardwareAcceleration
                }

                Column {
                    anchors.fill: parent
                    spacing: 4
                    anchors.margins: 5

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.icon
                        font {
                            family: "Segoe Fluent Icons"
                            pixelSize: 32
                        }
                        color: "white"
                        renderType: Text.NativeRendering
                        layer.enabled: root.useHardwareAcceleration
                    }

                    Text {
                        width: parent.width
                        text: modelData.name
                        color: "white"
                        font {
                            family: "Segoe UI Variable"
                            pixelSize: 12
                        }
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                        layer.enabled: root.useHardwareAcceleration
                    }
                }

                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    drag.target: parent
                    drag.threshold: 5
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    Timer {
                        id: dragTimer
                        interval: 100
                        running: false
                        repeat: false
                        onTriggered: dragArea.isDragging = true
                    }

                    property point startPos
                    property bool isDragging: false

                    onPressed: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            startPos = Qt.point(mouse.x, mouse.y)
                            if (!(mouse.modifiers & Qt.ControlModifier)) {
                                Qt.callLater(() => {
                                    for (let i = 0; i < desktopIconsArea.children.length; i++) {
                                        let item = desktopIconsArea.children[i]
                                        if (item.isSelected !== undefined) {
                                            item.isSelected = false
                                        }
                                    }
                                })
                            }
                            iconDelegate.isSelected = true
                            dragTimer.start()
                        }
                    }

                    onReleased: (mouse) => {
                        dragTimer.stop()
                        if (isDragging) {
                            Qt.callLater(() => {
                                desktopManager.saveIconPosition(index, parent.x, parent.y)
                            })
                            isDragging = false
                        } else if (mouse.button === Qt.RightButton) {
                            contextMenu.popup()
                        }
                    }

                    onDoubleClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            desktopManager.openItem(modelData.path)
                        }
                    }
                }

                Behavior on x {
                    enabled: !dragArea.drag.active
                    SmoothedAnimation {
                        duration: 100
                        velocity: 200
                    }
                }

                Behavior on y {
                    enabled: !dragArea.drag.active
                    SmoothedAnimation {
                        duration: 100
                        velocity: 200
                    }
                }
            }
        }

        // Selection area with optimization
        MouseArea {
            id: selectionArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            z: -1

            property point selectionStart

            Timer {
                id: selectionUpdateTimer
                interval: 16
                repeat: true
                running: selectionArea.pressed
                onTriggered: parent.updateSelection()
            }

            onPressed: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    selectionStart = Qt.point(mouse.x, mouse.y)
                    selectionRect.x = selectionStart.x
                    selectionRect.y = selectionStart.y
                    selectionRect.width = 0
                    selectionRect.height = 0
                    selectionRect.visible = true
                }
            }

            onPositionChanged: {
                if (pressed) {
                    updateSelectionRect()
                }
            }

            onReleased: {
                selectionRect.visible = false
                selectionUpdateTimer.stop()
            }

            function updateSelectionRect() {
                let x = Math.min(mouseX, selectionStart.x)
                let y = Math.min(mouseY, selectionStart.y)
                let width = Math.abs(mouseX - selectionStart.x)
                let height = Math.abs(mouseY - selectionStart.y)

                selectionRect.x = x
                selectionRect.y = y
                selectionRect.width = width
                selectionRect.height = height
            }

            function updateSelection() {
                Qt.callLater(() => {
                    let selRect = Qt.rect(selectionRect.x, selectionRect.y,
                                        selectionRect.width, selectionRect.height)
                    for (let i = 0; i < desktopIconsArea.children.length; i++) {
                        let item = desktopIconsArea.children[i]
                        if (item.isSelected !== undefined) {
                            let itemRect = Qt.rect(item.x, item.y, item.width, item.height)
                            item.isSelected = root.intersectRect(itemRect, selRect)
                        }
                    }
                })
            }
        }
    }

    // Helper function for intersection testing
    function intersectRect(r1, r2) {
        return !(r2.x > r1.x + r1.width ||
                r2.x + r2.width < r1.x ||
                r2.y > r1.y + r1.height ||
                r2.y + r2.height < r1.y)
    }

    // Performance optimized components
    Taskbar.TaskbarMain {
        id: taskbar
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 1
        }
        height: 24
        layer.enabled: root.useHardwareAcceleration
    }

    Components.Dock {
        id: dock
        anchors {
            bottom: parent.bottom
            bottomMargin: 12
            horizontalCenter: parent.horizontalCenter
        }
        height: 64
        layer.enabled: root.useHardwareAcceleration
    }

    // Optimized context menu
    Menu {
        id: contextMenu
        width: menuStyle.menuWidth

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 100 }
        }

        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 100 }
        }

        background: Rectangle {
            implicitWidth: menuStyle.menuWidth
            color: menuStyle.backgroundColor
            opacity: 0.98
            radius: menuStyle.radius
            border.width: 1
            border.color: menuStyle.borderColor
            layer.enabled: root.useHardwareAcceleration

            Rectangle {
                anchors.fill: parent
                color: "#1A1A1A"
                radius: menuStyle.radius
                opacity: 0.3
            }
        }
    }

    // Performance monitor (visible when debugMode is true)
    Column {
        visible: debugMode
        z: 1000
        anchors {
            right: parent.right
            top: parent.top
            margins: 10
        }

        Text {
            color: "white"
            font.pixelSize: 12
            text: "FPS: " + fpsCounter.fps.toFixed(1)
        }

        Text {
            color: "white"
            font.pixelSize: 12
            text: "Frame Time: " + fpsCounter.frameTime.toFixed(1) + "ms"
        }
    }

    // FPS Counter
    Item {
        id: fpsCounter
        property real fps: 0
        property real frameTime: 0
        property int frameCount: 0
        property real lastTime: Date.now()

        Timer {
            interval: 1000
            repeat: true
            running: root.debugMode
            onTriggered: {
                var current = Date.now()
                var delta = (current - parent.lastTime) / 1000
                parent.fps = parent.frameCount / delta
                parent.frameTime = delta * 1000 / parent.frameCount
                parent.frameCount = 0
                parent.lastTime = current
            }
        }

        Connections {
            target: root
            function onAfterRendering() {
                fpsCounter.frameCount++
            }
        }
    }
}
