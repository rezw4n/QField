import QtQuick 2.14
import QtQuick.Shapes 1.14
import org.qgis 1.0
import org.smartfield 1.0
import Theme 1.0

Item {
  id: measuringTool

  property alias measuringRubberband: rubberband
  property bool isClosingArea: rubberband.model.vertexCount > 2 && vertexFirstLastDistance.screenDistance < 10
  property bool isArea: false

  MapToScreen {
    id: vertexFirstLastDistance
    mapSettings: rubberband.mapSettings
    mapDistance: GeometryUtils.distanceBetweenPoints(rubberband.model.firstCoordinate, rubberband.model.currentCoordinate)
  }

  Repeater {
    id: vertices
    model: rubberband.model.vertices
    delegate: Shape {
      id: shape
      MapToScreen {
        id: vertexToScreen
        mapSettings: rubberband.mapSettings
        mapPoint: modelData
      }

      visible: rubberband.model.vertexCount > 1

      x: vertexToScreen.screenPoint.x - width / 2
      y: vertexToScreen.screenPoint.y - width / 2

      width: isClosingArea && (index === 0 || index === rubberband.model.vertexCount - 1) ? 20 : 10
      height: width

      ShapePath {
        strokeColor: "#96ffffff"
        strokeWidth: 5
        fillColor: "transparent"
        PathAngleArc {
          centerX: shape.width / 2
          centerY: centerX
          radiusX: centerX
          radiusY: centerX
          startAngle: 0
          sweepAngle: 360
        }
      }
      ShapePath {
        strokeColor: "#96000000"
        strokeWidth: 3
        fillColor: "transparent"
        PathAngleArc {
          centerX: shape.width / 2
          centerY: centerX
          radiusX: centerX
          radiusY: centerX
          startAngle: 0
          sweepAngle: 360
        }
      }
    }
  }

  Rubberband {
    id: rubberband
    color: '#96000000'

    model: RubberbandModel {
      frozen: false
      geometryType: isClosingArea || isArea ? Qgis.GeometryType.Polygon : Qgis.GeometryType.Line
      crs: rubberband.mapSettings.destinationCrs
    }
  }

  Connections {
    target: rubberband.model

    function onVertexCountChanged() {
      if (rubberband.model.vertexCount > 2 && vertexFirstLastDistance.screenDistance < 10) {
        isArea = true;
      } else if (rubberband.model.vertexCount <= 1) {
        isArea = false;
      }
    }
  }
}
