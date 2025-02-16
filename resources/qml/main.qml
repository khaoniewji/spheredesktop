// sphere/desktop/resources/qml/main.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Sphere.Desktop 1.0
import "./taskbar" as Taskbar

Window {
    id: root
    width: Screen.width
    height: Screen.height
    visible: true
    title: "Sphere Desktop"
    flags: Qt.Window | Qt.FramelessWindowHint

    // Property for performance monitoring
    property bool debugMode: false

    DesktopManager {
        id: desktopManager
    }

    // Desktop background with optimizations
    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        color: "#000000"

        Image {
            id: wallpaper
            anchors.fill: parent
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
            cache: true
            asynchronous: true
            sourceSize.width: width
            sourceSize.height: height
            smooth: false
            mipmap: true

            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            onStatusChanged: {
                if (status === Image.Error) {
                    console.error("Failed to load wallpaper:", source)
                }
            }
        }
    }

    // Desktop icons area
    Item {
        id: desktopIconsArea
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: taskbar.top
        }

        // Selection rectangle
        Rectangle {
            id: selectionRect
            visible: false
            color: "#3373737F"
            border.color: "#737373"
            border.width: 1
            z: 1000
            antialiasing: true
        }

        // Optimized repeater for desktop icons
        Repeater {
            model: desktopManager.desktopItems

            delegate: Item {
                id: iconDelegate
                width: 100
                height: 100
                x: modelData.x !== undefined ? modelData.x : desktopManager.getDefaultPosition(index).x
                y: modelData.y !== undefined ? modelData.y : desktopManager.getDefaultPosition(index).y

                property bool isSelected: false

                Rectangle {
                    anchors.fill: parent
                    color: iconDelegate.isSelected ? "#3373737F" : "transparent"
                    radius: 5
                    visible: iconDelegate.isSelected || dragArea.drag.active
                    antialiasing: true
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
                    }
                }

                // Optimized MouseArea with timer for drag detection
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

                    onPressed: {
                        if (mouse.button === Qt.LeftButton) {
                            startPos = Qt.point(mouse.x, mouse.y)
                            if (!(mouse.modifiers & Qt.ControlModifier)) {
                                Qt.callLater(function() {
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

                    onReleased: {
                        dragTimer.stop()
                        if (isDragging) {
                            Qt.callLater(function() {
                                desktopManager.saveIconPosition(index, parent.x, parent.y)
                            })
                            isDragging = false
                        } else if (mouse.button === Qt.RightButton) {
                            contextMenu.popup()
                        }
                    }

                    onDoubleClicked: {
                        if (mouse.button === Qt.LeftButton) {
                            desktopManager.openItem(modelData.path)
                        }
                    }
                }

                // Smooth animations
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

        // Optimized selection area
        MouseArea {
            id: selectionArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            z: -1

            property point selectionStart

            Timer {
                id: selectionUpdateTimer
                interval: 16 // ~60 FPS
                repeat: true
                running: selectionArea.pressed
                onTriggered: updateSelection()
            }

            onPressed: {
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
                Qt.callLater(function() {
                    let selRect = Qt.rect(selectionRect.x, selectionRect.y,
                                        selectionRect.width, selectionRect.height)
                    for (let i = 0; i < desktopIconsArea.children.length; i++) {
                        let item = desktopIconsArea.children[i]
                        if (item.isSelected !== undefined) {
                            let itemRect = Qt.rect(item.x, item.y, item.width, item.height)
                            item.isSelected = intersectRect(itemRect, selRect)
                        }
                    }
                })
            }
        }

        function intersectRect(r1, r2) {
            return !(r2.x > r1.x + r1.width ||
                    r2.x + r2.width < r1.x ||
                    r2.y > r1.y + r1.height ||
                    r2.y + r2.height < r1.y)
        }
    }

    // Taskbar
    Taskbar.TaskbarMain {
        id: taskbar
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 48
    }
    // Desktop context menu
    Menu {
        id: contextMenu

        Menu {
            title: "View"

            MenuItem {
                text: "Large icons"
                onTriggered: desktopManager.setIconSize("large")
            }

            MenuItem {
                text: "Medium icons"
                onTriggered: desktopManager.setIconSize("medium")
            }

            MenuItem {
                text: "Small icons"
                onTriggered: desktopManager.setIconSize("small")
            }
        }

        Menu {
            title: "Sort by"

            MenuItem {
                text: "Name"
                onTriggered: desktopManager.sortBy("name")
            }

            MenuItem {
                text: "Size"
                onTriggered: desktopManager.sortBy("size")
            }

            MenuItem {
                text: "Type"
                onTriggered: desktopManager.sortBy("type")
            }

            MenuItem {
                text: "Date modified"
                onTriggered: desktopManager.sortBy("date")
            }
        }

        MenuSeparator { }

        MenuItem {
            text: "Refresh"
            onTriggered: desktopManager.refresh()
        }

        MenuSeparator { }

        MenuItem {
            text: "Personalize"
            onTriggered: desktopManager.openPersonalization()
        }

        MenuItem {
            text: "Reset icon positions"
            onTriggered: desktopManager.resetIconPositions()
        }
    }
}
