import QtQuick
import Quickshell
import Quickshell.Wayland
import "../models"
import "../components"
import "../components/SpiderverseTheme.js" as Theme
import "../models/RadialLayout.js" as Radial

PanelWindow {
    id: surface

    property bool opened: false
    property bool showContent: false
    property int currentIndex: -1

    property var targetScreen: null

    readonly property real hubRadius: 124
    readonly property real centerX: width / 2
    readonly property real centerY: height * 0.56

    readonly property real maxRadius: Math.max(160, Math.min(centerY - 80, height - centerY - 60, width / 2 - 70) - 20)

    readonly property int maxVisible: 14
    readonly property var results: catalog.results
    readonly property var visibleResults: results.length > maxVisible ? results.slice(0, maxVisible) : results
    readonly property var radialLayout: Radial.layout(visibleResults.length, centerX, centerY, maxRadius, hubRadius + 50)
    readonly property var web: Radial.buildWeb(radialLayout.slots, centerX, centerY, hubRadius)
    readonly property var currentEntry: (currentIndex >= 0 && currentIndex < visibleResults.length) ? visibleResults[currentIndex] : null

    screen: targetScreen
    color: "transparent"
    visible: opened && targetScreen !== null
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omarchy-spiderverse-launcher"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function openApps() {
        if (opened) return;
        search.text = "";
        catalog.query = "";
        currentIndex = catalog.results.length > 0 ? 0 : -1;
        opened = true;
        showContent = true;
        Qt.callLater(function() { search.forceActiveFocus(); });
    }

    function close() {
        if (!opened) return;
        showContent = false;
        opened = false;
    }

    function toggle() { opened ? close() : openApps(); }

    function step(dir) {
        const count = visibleResults.length;
        if (count === 0) return;
        currentIndex = (currentIndex + dir + count) % count;
    }

    function moveDirection(vx, vy) {
        if (currentIndex < 0) return;
        currentIndex = Radial.moveDir(radialLayout.slots, currentIndex, vx, vy);
    }

    function launchCurrent() {
        if (!currentEntry) return;
        const entry = currentEntry;
        catalog.launch(entry);
        close();
    }

    ApplicationCatalog { id: catalog }

    onVisibleResultsChanged: currentIndex = visibleResults.length > 0 ? Math.min(currentIndex < 0 ? 0 : currentIndex, visibleResults.length - 1) : -1

    Rectangle {
        anchors.fill: parent
        color: Theme.darkerBackground
        opacity: surface.showContent ? 0.94 : 0.0
        MouseArea { anchors.fill: parent; onClicked: surface.close() }
    }

    Item {
        anchors.fill: parent
        opacity: surface.showContent ? 1.0 : 0.0

        HalftoneOverlay {
            anchors.fill: parent
            intensity: 0.5
        }

        SpiderWeb {
            anchors.fill: parent
            spokes: surface.web.spokes
            chords: surface.web.chords
            innerChords: surface.web.innerChords
            diagonals: surface.web.diagonals
            selectedIndex: surface.currentIndex
            hubRadius: surface.hubRadius
            hubCenterX: surface.centerX
            hubCenterY: surface.centerY
        }

        HubPanel {
            x: surface.centerX - width / 2
            y: surface.centerY - height / 2
            initialsText: surface.currentEntry ? Theme.initials(surface.currentEntry.label) : "??"
            iconSource: surface.currentEntry && surface.currentEntry.icon ? catalog.resolvedIcon(surface.currentEntry.icon) : ""
            appName: surface.currentEntry ? surface.currentEntry.label : "no results"
            category: surface.currentEntry ? (surface.currentEntry.description || "") : ""
        }

        Repeater {
            model: surface.radialLayout.slots

            delegate: NodeCard {
                required property var modelData
                readonly property var entry: surface.visibleResults[modelData.index]

                x: modelData.x - width / 2
                y: modelData.y - height / 2
                z: modelData.index === surface.currentIndex ? 10 : 1

                label: entry ? entry.label : ""
                initialsText: entry ? Theme.initials(entry.label) : ""
                iconSource: entry && entry.icon ? catalog.resolvedIcon(entry.icon) : ""
                tint: Theme.tintFor(entry ? entry.description : "", modelData.index)
                active: modelData.index === surface.currentIndex

                onRequested: surface.currentIndex = modelData.index
                onActivated: {
                    surface.currentIndex = modelData.index;
                    surface.launchCurrent();
                }
            }
        }

        Rectangle {
            id: searchBar
            anchors.top: parent.top
            anchors.topMargin: 30
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(640, parent.width - 120)
            height: 50
            color: Qt.rgba(0.176, 0.106, 0.306, 0.5)
            border.color: Qt.rgba(0.29, 0.18, 0.48, 0.95)
            border.width: 1

            Text {
                id: prompt
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: "❯"
                color: Theme.accent
                font.family: "Archivo Black"
                font.pixelSize: 16
            }

            Text {
                id: countLabel
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: surface.visibleResults.length < surface.results.length
                    ? (surface.visibleResults.length + " shown / " + surface.results.length + " apps")
                    : (surface.results.length + " / " + catalog.applications.length + " apps")
                color: Theme.muted
                font.family: "JetBrains Mono"
                font.pixelSize: 13
            }

            TextInput {
                id: search
                anchors.left: prompt.right
                anchors.leftMargin: 12
                anchors.right: countLabel.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.foreground
                font.family: "JetBrains Mono"
                font.pixelSize: 18
                focus: true

                Keys.onEscapePressed: text.length > 0 ? (text = "") : surface.close()
                Keys.onReturnPressed: surface.launchCurrent()
                Keys.onTabPressed: (event) => { surface.step(event.modifiers & Qt.ShiftModifier ? -1 : 1); }
                Keys.onUpPressed: surface.moveDirection(0, -1)
                Keys.onDownPressed: surface.moveDirection(0, 1)
                Keys.onLeftPressed: (event) => {
                    if (cursorPosition === 0) surface.moveDirection(-1, 0);
                    else event.accepted = false;
                }
                Keys.onRightPressed: (event) => {
                    if (cursorPosition === text.length) surface.moveDirection(1, 0);
                    else event.accepted = false;
                }
                onTextChanged: catalog.query = text
            }
        }

    }
}
