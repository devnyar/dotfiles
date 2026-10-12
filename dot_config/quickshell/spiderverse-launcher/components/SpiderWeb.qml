import QtQuick
import QtQuick.Shapes
import "SpiderverseTheme.js" as Theme

Item {
    id: web

    property var spokes: []
    property var chords: []
    property var innerChords: []
    property var diagonals: []
    property int selectedIndex: -1
    property real hubRadius: 124
    property real hubCenterX: width / 2
    property real hubCenterY: height / 2

    function chordsSvg(list) {
        var parts = [];
        for (var i = 0; i < list.length; i++) {
            var c = list[i];
            parts.push("M " + c.x1 + " " + c.y1 + " Q " + c.cx1 + " " + c.cy1 + " " + c.x2 + " " + c.y2);
        }
        return parts.join(" ");
    }

    function linesSvg(list, excludeIndex) {
        var parts = [];
        for (var i = 0; i < list.length; i++) {
            var s = list[i];
            if (excludeIndex !== undefined && s.index === excludeIndex) continue;
            parts.push("M " + s.x1 + " " + s.y1 + " L " + s.x2 + " " + s.y2);
        }
        return parts.join(" ");
    }

    function selectedSpoke(list, index) {
        for (var i = 0; i < list.length; i++) {
            if (list[i].index === index) return list[i];
        }
        return null;
    }

    readonly property var activeSpoke: selectedSpoke(spokes, selectedIndex)

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(0.7, 0.62, 0.84, 0.16)
            strokeWidth: 1
            PathSvg { path: web.linesSvg(web.diagonals) }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(0.7, 0.62, 0.84, 0.14)
            strokeWidth: 1
            PathSvg { path: web.chordsSvg(web.innerChords) }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(0.7, 0.62, 0.84, 0.35)
            strokeWidth: 1.2
            PathSvg { path: web.chordsSvg(web.chords) }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(0.7, 0.62, 0.84, 0.32)
            strokeWidth: 1
            PathSvg { path: web.linesSvg(web.spokes, web.selectedIndex) }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(0.29, 0.18, 0.48, 0.8)
            strokeWidth: 1
            PathAngleArc {
                centerX: web.hubCenterX
                centerY: web.hubCenterY
                radiusX: web.hubRadius
                radiusY: web.hubRadius
                startAngle: 0
                sweepAngle: 360
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: Theme.accent
            strokeWidth: 2
            PathSvg {
                path: web.activeSpoke
                    ? ("M " + web.activeSpoke.x1 + " " + web.activeSpoke.y1 + " L " + web.activeSpoke.x2 + " " + web.activeSpoke.y2)
                    : ""
            }
        }
    }
}
