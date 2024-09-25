import QtQuick 2.14
import QtQuick.Shapes 1.14
import Theme 1.0
import org.smartfield 1.0
import org.qgis 1.0

LinePolygonShape {
  id: linePolygonShape

  onPolylinesChanged: {
    if (polylines.length > 0) {
      const pathElements = [];
      for (const polyline of polylines) {
        var pathPolyline = componentPathPolyline.createObject(shapePath);
        pathPolyline.path = polyline;
        pathElements.push(pathPolyline);
      }
      shapePath.pathElements = pathElements;
    } else {
      shapePath.pathElements = [componentPathPolyline.createObject(shapePath)];
    }
  }

  Component {
    id: componentPathPolyline

    PathPolyline {
    }
  }

  Shape {
    id: shape
    anchors.fill: parent

    ShapePath {
      id: shapePath
      strokeColor: linePolygonShape.color
      strokeWidth: linePolygonShape.lineWidth / linePolygonShape.scale
      strokeStyle: ShapePath.SolidLine
      fillColor: linePolygonShape.polylinesType === Qgis.GeometryType.Polygon ? Qt.hsla(strokeColor.hslHue, strokeColor.hslSaturation, strokeColor.hslLightness, 0.25) : "transparent"
      joinStyle: ShapePath.RoundJoin
      capStyle: ShapePath.RoundCap
    }
  }
}
