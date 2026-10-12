.pragma library


var RADIUS_RATIOS = { 1: [0.5], 2: [0.55, 1.0], 3: [0.42, 0.72, 1.0] };
var OFFSETS = [0, 8, 5];
var CAPS = [6, 8, 9];

function ringsOf(count) {
    if (!count) return [];
    if (count <= CAPS[0]) return [count];
    if (count <= CAPS[0] + CAPS[1]) {
        var inner = Math.max(4, Math.round(count * 0.38));
        return [inner, count - inner];
    }
    var total = CAPS[0] + CAPS[1] + CAPS[2];
    var a = Math.max(4, Math.round((count * CAPS[0]) / total));
    var b = Math.max(5, Math.round((count * CAPS[1]) / total));
    return [a, b, count - a - b];
}

function layout(count, cx, cy, maxRadius, minRadius) {
    var rings = ringsOf(count);
    var ratios = RADIUS_RATIOS[rings.length] || RADIUS_RATIOS[3];
    var floor = minRadius || 0;
    var radii = ratios.map(function(r) { return Math.max(floor, r * maxRadius); });
    var out = [];
    var i = 0;
    for (var r = 0; r < rings.length; r++) {
        var n = rings[r];
        var offset = OFFSETS[r] || 0;
        for (var k = 0; k < n; k++) {
            var deg = -90 + offset + (k * 360) / n;
            var rad = (deg * Math.PI) / 180;
            out.push({
                index: i,
                ring: r,
                ratio: n > 1 ? k / n : 0,
                radius: radii[r],
                deg: deg,
                x: cx + Math.cos(rad) * radii[r],
                y: cy + Math.sin(rad) * radii[r]
            });
            i++;
        }
    }
    return { slots: out, rings: rings, radii: radii };
}

function moveDir(slots, currentIndex, vx, vy) {
    var cur = null;
    for (var s = 0; s < slots.length; s++) {
        if (slots[s].index === currentIndex) { cur = slots[s]; break; }
    }
    if (!cur) return currentIndex;

    var best = null;
    var bestScore = Infinity;
    for (var i = 0; i < slots.length; i++) {
        var slot = slots[i];
        if (slot.index === cur.index) continue;
        var dx = slot.x - cur.x;
        var dy = slot.y - cur.y;
        var dist = Math.hypot(dx, dy);
        if (!dist) continue;
        var align = (dx * vx + dy * vy) / dist;
        if (align < 0.35) continue;
        var score = dist / Math.pow(align, 2.2);
        if (score < bestScore) {
            bestScore = score;
            best = slot;
        }
    }
    return best ? best.index : currentIndex;
}

function buildWeb(slots, cx, cy, hubRadius) {
    var spokes = [];
    for (var i = 0; i < slots.length; i++) {
        var s = slots[i];
        var rad = (s.deg * Math.PI) / 180;
        spokes.push({
            index: s.index,
            x1: cx + Math.cos(rad) * hubRadius,
            y1: cy + Math.sin(rad) * hubRadius,
            x2: s.x,
            y2: s.y
        });
    }

    var byRing = {};
    for (var j = 0; j < slots.length; j++) {
        var slot = slots[j];
        (byRing[slot.ring] = byRing[slot.ring] || []).push(slot);
    }

    function arcChords(ring, radius, sagFactor) {
        var n = ring.length;
        var sag = radius * sagFactor;
        var out = [];
        for (var k = 0; k < n; k++) {
            var a = ring[k].deg;
            var b = ring[(k + 1) % n].deg + (k === n - 1 ? 360 : 0);
            var mid = ((a + b) / 2) * (Math.PI / 180);
            var ra = (a * Math.PI) / 180;
            var rb = (b * Math.PI) / 180;
            out.push({
                x1: cx + Math.cos(ra) * radius,
                y1: cy + Math.sin(ra) * radius,
                cx1: cx + Math.cos(mid) * sag,
                cy1: cy + Math.sin(mid) * sag,
                x2: cx + Math.cos(rb) * radius,
                y2: cy + Math.sin(rb) * radius
            });
        }
        return out;
    }

    var chords = [];
    var innerChords = [];
    Object.keys(byRing).forEach(function(r) {
        var ring = byRing[r];
        var n = ring.length;
        if (n < 2) return;
        var radius = ring[0].radius;
        if (radius < hubRadius + 16) return;
        var sagFactor = n > 6 ? 0.965 : 0.94;
        chords = chords.concat(arcChords(ring, radius, sagFactor));
        if (radius * 0.88 > hubRadius + 16) {
            innerChords = innerChords.concat(arcChords(ring, radius * 0.88, sagFactor));
        }
    });

    var diagonals = [];
    var ringKeys = Object.keys(byRing).map(Number).sort(function(a, b) { return a - b; });
    for (var ri = 1; ri < ringKeys.length; ri++) {
        var outer = byRing[ringKeys[ri]];
        var inner = byRing[ringKeys[ri - 1]];
        for (var oi = 0; oi < outer.length; oi++) {
            var node = outer[oi];
            var nearest = inner[0];
            var bestDelta = 361;
            for (var ii = 0; ii < inner.length; ii++) {
                var delta = Math.abs(((inner[ii].deg - node.deg + 540) % 360) - 180);
                if (delta < bestDelta) {
                    bestDelta = delta;
                    nearest = inner[ii];
                }
            }
            diagonals.push({ x1: node.x, y1: node.y, x2: nearest.x, y2: nearest.y });
        }
    }

    return { spokes: spokes, chords: chords, innerChords: innerChords, diagonals: diagonals };
}
