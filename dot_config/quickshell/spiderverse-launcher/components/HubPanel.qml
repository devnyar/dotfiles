import QtQuick
import "SpiderverseTheme.js" as Theme

Item {
    id: hub

    property string initialsText: "??"
    property url iconSource: ""
    property string appName: "no results"
    property string category: ""
    property string execLabel: ""

    implicitWidth: 240
    implicitHeight: 240

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.lighterBackground
        opacity: 0.95
        border.color: Qt.rgba(1, 0.18, 0.58, 0.45)
        border.width: 1
    }

    Column {
        anchors.centerIn: parent
        spacing: 10
        width: parent.width - 52

        Item {
            id: iconStack
            width: parent.width
            height: 64

            readonly property bool imageVisible: String(hub.iconSource).length > 0 && hubIcon.status !== Image.Error

            Image {
                id: hubIcon
                anchors.centerIn: parent
                width: 60
                height: 60
                source: hub.iconSource
                sourceSize.width: width
                sourceSize.height: height
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                visible: iconStack.imageVisible
            }

            Text {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -3
                text: hub.initialsText
                color: Theme.cyan
                opacity: iconStack.imageVisible ? 0 : 0.7
                font.family: "Archivo Black"
                font.pixelSize: 46
                visible: !iconStack.imageVisible
            }
            Text {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: 3
                text: hub.initialsText
                color: Theme.red
                opacity: iconStack.imageVisible ? 0 : 0.7
                font.family: "Archivo Black"
                font.pixelSize: 46
                visible: !iconStack.imageVisible
            }
            Text {
                id: initialsMain
                anchors.centerIn: parent
                text: hub.initialsText
                color: Theme.accent
                font.family: "Archivo Black"
                font.pixelSize: 46
                visible: !iconStack.imageVisible
            }
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: hub.appName
            color: Theme.foreground
            font.family: "Archivo Black"
            font.pixelSize: 20
            font.capitalization: Font.AllUppercase
            wrapMode: Text.WordWrap
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: hub.category
            color: Theme.darkForeground
            font.family: "JetBrains Mono"
            font.pixelSize: 11
            font.letterSpacing: 1.6
            font.capitalization: Font.AllUppercase
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: hub.execLabel
            color: Theme.muted
            font.family: "JetBrains Mono"
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }
}
