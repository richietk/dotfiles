.pragma library

.import "shapes/point.js" as Point
.import "shapes/rounded-polygon.js" as RoundedPolygon
.import "shapes/corner-rounding.js" as CornerRounding
.import "geometry/offset.js" as Offset
.import "graphics/matrix.js" as Matrix

var _circle = null
var _arrow = null
var _pill = null
var _diamond = null
var _clamShell = null
var _pentagon = null
var _gem = null
var _verySunny = null
var _sunny = null
var _cookie7Sided = null
var _ghostish = null
var _clover4Leaf = null
var _softBurst = null
var _puffyDiamond = null
var _pixelCircle = null

var cornerRound15 = new CornerRounding.CornerRounding(0.15)
var cornerRound50 = new CornerRounding.CornerRounding(0.5)

var rotateNeg45 = new Matrix.Matrix();
rotateNeg45.rotateZ(-45);
var rotate45 = new Matrix.Matrix();
rotate45.rotateZ(45);
var rotate90 = new Matrix.Matrix();
rotate90.rotateZ(90);
var rotate180 = new Matrix.Matrix();
rotate180.rotateZ(180);

var rotate28th = new Matrix.Matrix();
rotate28th.rotateZ(360/28);

function getCircle() {
    if (_circle !== null) return _circle;
    _circle = circle();
    return _circle;
}

function getArrow() {
    if (_arrow !== null) return _arrow;
    _arrow = arrow();
    return _arrow;
}

function getPill() {
    if (_pill !== null) return _pill;
    _pill = pill();
    return _pill;
}

function getDiamond() {
    if (_diamond !== null) return _diamond;
    _diamond = diamond();
    return _diamond;
}

function getClamShell() {
    if (_clamShell !== null) return _clamShell;
    _clamShell = clamShell();
    return _clamShell;
}

function getPentagon() {
    if (_pentagon !== null) return _pentagon;
    _pentagon = pentagon();
    return _pentagon;
}

function getGem() {
    if (_gem !== null) return _gem;
    _gem = gem();
    return _gem;
}

function getSunny() {
    if (_sunny !== null) return _sunny;
    _sunny = sunny();
    return _sunny;
}

function getVerySunny() {
    if (_verySunny !== null) return _verySunny;
    _verySunny = verySunny();
    return _verySunny;
}

function getCookie7Sided() {
    if (_cookie7Sided !== null) return _cookie7Sided;
    _cookie7Sided = cookie7();
    return _cookie7Sided;
}

function getGhostish() {
    if (_ghostish !== null) return _ghostish;
    _ghostish = ghostish();
    return _ghostish;
}

function getClover4Leaf() {
    if (_clover4Leaf !== null) return _clover4Leaf;
    _clover4Leaf = clover4();
    return _clover4Leaf;
}

function getSoftBurst() {
    if (_softBurst !== null) return _softBurst;
    _softBurst = softBurst();
    return _softBurst;
}

function getPuffyDiamond() {
    if (_puffyDiamond !== null) return _puffyDiamond;
    _puffyDiamond = puffyDiamond();
    return _puffyDiamond;
}

function getPixelCircle() {
    if (_pixelCircle !== null) return _pixelCircle;
    _pixelCircle = pixelCircle();
    return _pixelCircle;
}

function circle() {
    return RoundedPolygon.RoundedPolygon.circle(10)
        .transformed((x, y) => rotate45.map(new Offset.Offset(x, y)))
        .normalized();
}

function arrow() {
    return customPolygon([
        new PointNRound(new Offset.Offset(1.225, 1.060), new CornerRounding.CornerRounding(0.211)),
        new PointNRound(new Offset.Offset(0.500, 0.892), new CornerRounding.CornerRounding(0.313)),
        new PointNRound(new Offset.Offset(-0.216, 1.050), new CornerRounding.CornerRounding(0.207)),
        new PointNRound(new Offset.Offset(0.499, -0.160), new CornerRounding.CornerRounding(0.215, 1.000)),
    ], 1).normalized();
}

function pill() {
    return customPolygon([
        new PointNRound(new Offset.Offset(0.428, -0.001), new CornerRounding.CornerRounding(0.426)),
        new PointNRound(new Offset.Offset(0.961, 0.039), new CornerRounding.CornerRounding(0.426)),
        new PointNRound(new Offset.Offset(1.001, 0.428)),
        new PointNRound(new Offset.Offset(1.000, 0.609), new CornerRounding.CornerRounding(1.000)),
    ], 2)
        .transformed((x, y) => rotate180.map(new Offset.Offset(x, y)))
        .normalized();
}

function diamond() {
    return customPolygon([
        new PointNRound(new Offset.Offset(0.500, 1.096), new CornerRounding.CornerRounding(0.151, 0.524)),
        new PointNRound(new Offset.Offset(0.040, 0.500), new CornerRounding.CornerRounding(0.159)),
    ], 2).normalized();
}

function clamShell() {
    return customPolygon([
        new PointNRound(new Offset.Offset(0.829, 0.841), new CornerRounding.CornerRounding(0.159)),
        new PointNRound(new Offset.Offset(0.171, 0.841), new CornerRounding.CornerRounding(0.159)),
        new PointNRound(new Offset.Offset(-0.020, 0.500), new CornerRounding.CornerRounding(0.140)),
    ], 2).normalized();
}

function pentagon() {
    return customPolygon([
        new PointNRound(new Offset.Offset(0.828, 0.970), new CornerRounding.CornerRounding(0.169)),
        new PointNRound(new Offset.Offset(0.172, 0.970), new CornerRounding.CornerRounding(0.169)),
        new PointNRound(new Offset.Offset(-0.030, 0.365), new CornerRounding.CornerRounding(0.164)),
        new PointNRound(new Offset.Offset(0.500, -0.009), new CornerRounding.CornerRounding(0.172)),
        new PointNRound(new Offset.Offset(1.030, 0.365), new CornerRounding.CornerRounding(0.164)),
    ], 1).normalized();
}

function gem() {
    return customPolygon([
        new PointNRound(new Offset.Offset(1.005, 0.792), new CornerRounding.CornerRounding(0.208)),
        new PointNRound(new Offset.Offset(0.5, 1.023), new CornerRounding.CornerRounding(0.241, 0.778)),
        new PointNRound(new Offset.Offset(-0.005, 0.792), new CornerRounding.CornerRounding(0.208)),
        new PointNRound(new Offset.Offset(0.073, 0.258), new CornerRounding.CornerRounding(0.228)),
        new PointNRound(new Offset.Offset(0.5, 0.000), new CornerRounding.CornerRounding(0.241, 0.778)),
        new PointNRound(new Offset.Offset(0.927, 0.258), new CornerRounding.CornerRounding(0.228)),
    ], 1).normalized();
}

function sunny() {
    return RoundedPolygon.RoundedPolygon.star(8, 1, 0.8, cornerRound15)
        .transformed((x, y) => rotate45.map(new Offset.Offset(x, y)))
        .normalized();
}

function verySunny() {
    return customPolygon([
        new PointNRound(new Offset.Offset(0.500, 1.080), new CornerRounding.CornerRounding(0.085)),
        new PointNRound(new Offset.Offset(0.358, 0.843), new CornerRounding.CornerRounding(0.085)),
    ], 8)
        .transformed((x, y) => rotateNeg45.map(new Offset.Offset(x, y)))
        .normalized();
}

function cookie7() {
    return RoundedPolygon.RoundedPolygon.star(7, 1, 0.75, cornerRound50)
        .normalized()
        .transformed((x, y) => rotate28th.map(new Offset.Offset(x, y)))
        .transformed((x, y) => rotate28th.map(new Offset.Offset(x, y)))
        .transformed((x, y) => rotate28th.map(new Offset.Offset(x, y)))
        .transformed((x, y) => rotate28th.map(new Offset.Offset(x, y)))
        .transformed((x, y) => rotate28th.map(new Offset.Offset(x, y)))
        .normalized();
}

function ghostish() {
    return customPolygon([
        new PointNRound(new Offset.Offset(1.000, 1.140), new CornerRounding.CornerRounding(0.254, 0.106)),
        new PointNRound(new Offset.Offset(0.575, 0.906), new CornerRounding.CornerRounding(0.253)),
        new PointNRound(new Offset.Offset(0.425, 0.906), new CornerRounding.CornerRounding(0.253)),
        new PointNRound(new Offset.Offset(0.000, 1.140), new CornerRounding.CornerRounding(0.254, 0.106)),
        new PointNRound(new Offset.Offset(0.000, 0.000), new CornerRounding.CornerRounding(1.0)),
        new PointNRound(new Offset.Offset(0.500, 0.000), new CornerRounding.CornerRounding(1.0)),
        new PointNRound(new Offset.Offset(1.000, 0.000), new CornerRounding.CornerRounding(1.0)),
    ], 1).normalized();
}

function clover4() {
    return customPolygon([
        new PointNRound(new Offset.Offset(1.099, 0.725), new CornerRounding.CornerRounding(0.476)),
        new PointNRound(new Offset.Offset(0.725, 1.099), new CornerRounding.CornerRounding(0.476)),
        new PointNRound(new Offset.Offset(0.500, 0.926)),
    ], 4).normalized();
}

function softBurst() {
    return customPolygon([
        new PointNRound(new Offset.Offset(0.193, 0.277), new CornerRounding.CornerRounding(0.053)),
        new PointNRound(new Offset.Offset(0.176, 0.055), new CornerRounding.CornerRounding(0.053)),
    ], 10)
        .transformed((x, y) => rotate180.map(new Offset.Offset(x, y)))
        .normalized();
}

function puffyDiamond() {
    return customPolygon([
        new PointNRound(new Offset.Offset(0.870, 0.130), new CornerRounding.CornerRounding(0.146)),
        new PointNRound(new Offset.Offset(0.818, 0.357)),
        new PointNRound(new Offset.Offset(1.000, 0.332), new CornerRounding.CornerRounding(0.853)),
        new PointNRound(new Offset.Offset(1.000, 1-0.332), new CornerRounding.CornerRounding(0.853)),
        new PointNRound(new Offset.Offset(0.818, 1-0.357)),
    ], 4)
        .transformed((x, y) => rotate90.map(new Offset.Offset(x, y)))
        .normalized();
}

function pixelCircle() {
    return customPolygon([
        new PointNRound(new Offset.Offset(1.000, 0.704)),
        new PointNRound(new Offset.Offset(0.926, 0.704)),
        new PointNRound(new Offset.Offset(0.926, 0.852)),
        new PointNRound(new Offset.Offset(0.843, 0.852)),
        new PointNRound(new Offset.Offset(0.843, 0.935)),
        new PointNRound(new Offset.Offset(0.704, 0.935)),
        new PointNRound(new Offset.Offset(0.704, 1.000)),
        new PointNRound(new Offset.Offset(0.500, 1.000)),
        new PointNRound(new Offset.Offset(1-0.704, 1.000)),
        new PointNRound(new Offset.Offset(1-0.704, 0.935)),
        new PointNRound(new Offset.Offset(1-0.843, 0.935)),
        new PointNRound(new Offset.Offset(1-0.843, 0.852)),
        new PointNRound(new Offset.Offset(1-0.926, 0.852)),
        new PointNRound(new Offset.Offset(1-0.926, 0.704)),
        new PointNRound(new Offset.Offset(1-1.000, 0.704)),
    ], 2)
        .normalized();
}

class PointNRound {
    constructor(o, r = CornerRounding.Unrounded) {
        this.o = o;
        this.r = r;
    }
}

function doRepeat(points, reps, center, mirroring) {
    if (mirroring) {
        const result = [];
        const angles = points.map(p => p.o.minus(center).angleDegrees());
        const distances = points.map(p => p.o.minus(center).getDistance());
        const actualReps = reps * 2;
        const sectionAngle = 360 / actualReps;
        for (let it = 0; it < actualReps; it++) {
            for (let index = 0; index < points.length; index++) {
                const i = (it % 2 === 0) ? index : points.length - 1 - index;
                if (i > 0 || it % 2 === 0) {
                    const baseAngle = angles[i];
                    const angle = it * sectionAngle + (it % 2 === 0 ? baseAngle : (2 * angles[0] - baseAngle));
                    const dist = distances[i];
                    const rad = angle * Math.PI / 180;
                    const x = center.x + dist * Math.cos(rad);
                    const y = center.y + dist * Math.sin(rad);
                    result.push(new PointNRound(new Offset.Offset(x, y), points[i].r));
                }
            }
        }
        return result;
    } else {
        const np = points.length;
        const result = [];
        for (let i = 0; i < np * reps; i++) {
            const point = points[i % np].o.rotateDegrees(Math.floor(i / np) * 360 / reps, center);
            result.push(new PointNRound(point, points[i % np].r));
        }
        return result;
    }
}

function customPolygon(pnr, reps = 1, center = new Offset.Offset(0.5, 0.5), mirroring = false) {
    const actualPoints = doRepeat(pnr, reps, center, mirroring);
    const vertices = [];
    for (const p of actualPoints) {
        vertices.push(p.o.x);
        vertices.push(p.o.y);
    }
    const perVertexRounding = actualPoints.map(p => p.r);
    return RoundedPolygon.RoundedPolygon.fromVertices(vertices, CornerRounding.Unrounded, perVertexRounding, center.x, center.y);
}
