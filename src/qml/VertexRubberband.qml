import QtQuick 2.14
import QtQml 2.14
import org.qgis 1.0
import org.smartfield 1.0
import Theme 1.0

Repeater {
  id: vertexRubberband

  property MapSettings mapSettings
  property bool isVisible: false
  property bool isCycling: model.currentVertexIndex !== -1
  property bool isAddingVertex: model.editingMode === VertexModel.AddVertex

  delegate: Rectangle {
    MapToScreen {
      id: mapToScreen
      mapSettings: vertexRubberband.mapSettings
      mapPoint: Point
    }

    visible: vertexRubberband.isVisible

    x: mapToScreen.screenPoint.x - width / 2
    y: mapToScreen.screenPoint.y - width / 2
    opacity: !isCycling || (isAddingVertex && !ExistingVertex) || (!isAddingVertex && ExistingVertex) ? 1.0 : 0.25

    width: ((isAddingVertex && !ExistingVertex) || (!isAddingVertex && ExistingVertex) ? 16 : 8) * (CurrentVertex ? 1.33 : 1) / (rotation == 0 ? 1 : 1.25)
    height: width
    radius: ExistingVertex ? width / 2 : 0
    rotation: ExistingVertex ? 0 : 45

    color: "transparent"

    Rectangle {
      anchors.fill: parent
      radius: ExistingVertex ? width / 2 : 0
      color: "transparent"
      border.color: "#90FFFFFF"
      border.width: (VertexModel.ExistingVertex ? 4 : 2) * (CurrentVertex ? 1.5 : 1) + 2
    }

    Rectangle {
      anchors.fill: parent
      anchors.margins: 1
      radius: ExistingVertex ? width / 2 : 0
      color: CurrentVertex ? isAddingVertex ? Theme.vertexNewColorSemiOpaque : Theme.vertexSelectedColorSemiOpaque : Theme.vertexColorSemiOpaque
      border.color: CurrentVertex ? isAddingVertex ? Theme.vertexNewColor : Theme.vertexSelectedColor : Theme.vertexColor
      border.width: (VertexModel.ExistingVertex ? 4 : 2) * (CurrentVertex ? 1.5 : 1)
    }
  }
}
