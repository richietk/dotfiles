import qs.modules.common.widgets.shapes
import "shapes/material-shapes.js" as MaterialShapes

ShapeCanvas {
    id: root
    enum Shape {
        Circle,
        Arrow,
        Pill,
        Diamond,
        ClamShell,
        Pentagon,
        Gem,
        Sunny,
        VerySunny,
        Cookie7Sided,
        Ghostish,
        Clover4Leaf,
        SoftBurst,
        PuffyDiamond,
        PixelCircle
    }
    required property var shape
    property double implicitSize
    implicitHeight: implicitSize
    implicitWidth: implicitSize
    polygonIsNormalized: true
    roundedPolygon: {
        switch (root.shape) {
            case MaterialShape.Shape.Circle: return MaterialShapes.getCircle();
            case MaterialShape.Shape.Arrow: return MaterialShapes.getArrow();
            case MaterialShape.Shape.Pill: return MaterialShapes.getPill();
            case MaterialShape.Shape.Diamond: return MaterialShapes.getDiamond();
            case MaterialShape.Shape.ClamShell: return MaterialShapes.getClamShell();
            case MaterialShape.Shape.Pentagon: return MaterialShapes.getPentagon();
            case MaterialShape.Shape.Gem: return MaterialShapes.getGem();
            case MaterialShape.Shape.Sunny: return MaterialShapes.getSunny();
            case MaterialShape.Shape.VerySunny: return MaterialShapes.getVerySunny();
            case MaterialShape.Shape.Cookie7Sided: return MaterialShapes.getCookie7Sided();
            case MaterialShape.Shape.Ghostish: return MaterialShapes.getGhostish();
            case MaterialShape.Shape.Clover4Leaf: return MaterialShapes.getClover4Leaf();
            case MaterialShape.Shape.SoftBurst: return MaterialShapes.getSoftBurst();
            case MaterialShape.Shape.PuffyDiamond: return MaterialShapes.getPuffyDiamond();
            case MaterialShape.Shape.PixelCircle: return MaterialShapes.getPixelCircle();
            default: return MaterialShapes.getCircle();
        }
    }
}
