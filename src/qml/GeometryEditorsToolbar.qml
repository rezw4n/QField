import QtQuick 2.14
import QtQml.Models 2.14
import org.qgis 1.0
import org.smartfield 1.0
import Theme 1.0

/**
This contains several geometry editing tools
A tool must subclass VisibilityFadingRow
And contains following functions:
  * function init(featureModel, mapSettings, editorRubberbandModel)
  * function cancel()
The following signal:
  * signal finished()
It can optionally implement properties:
  * blocking (bool) which prevents from switching tools
  * vertexRubberbandVisible (bool) to show the vertex rubberband (false by default)
It can optionally implement properties which will be bind:
  * screenHovering determines if a pen is currently hovering the screen
It can optionally implement the functions:
  * canvasClicked(point)
  * canvasLongPressed(point)
  These functions must return true if they catch the event
*/
VisibilityFadingRow {
  id: geometryEditorsToolbar

  property FeatureModel featureModel //<! the feature which has its geometry being edited
  property MapSettings mapSettings
  property RubberbandModel editorRubberbandModel //<! an additional Rubberband model for the tools (when drawing lines in split or add ring tools)
  property GeometryRenderer editorRenderer
  property bool screenHovering: false //<! if the stylus pen is used, one should not use the add button

  property string image: Theme.getThemeIcon("ic_edit_geometry_white")

  spacing: 4

  signal editorChanged

  GeometryEditorsModel {
    id: editors
  }

  Component.onCompleted: {
    editors.addEditor(qsTr("Vertex Tool"), "ic_vertex_tool_white_24dp", "geometryeditors/VertexEditor.qml");
    editors.addEditor(qsTr("Split Tool"), "ic_split_tool_white_24dp", "geometryeditors/SplitFeature.qml", GeometryEditorsModelSingleton.Line | GeometryEditorsModelSingleton.Polygon);
    editors.addEditor(qsTr("Reshape Tool"), "ic_reshape_tool_white_24dp", "geometryeditors/Reshape.qml", GeometryEditorsModelSingleton.Line | GeometryEditorsModelSingleton.Polygon);
    editors.addEditor(qsTr("Erase Tool"), "ic_erase_tool_white_24dp", "geometryeditors/Erase.qml", GeometryEditorsModelSingleton.Line | GeometryEditorsModelSingleton.Polygon);
    editors.addEditor(qsTr("Fill Ring Tool"), "ic_ring_tool_white_24dp", "geometryeditors/FillRing.qml", GeometryEditorsModelSingleton.Polygon);
  }

  function init() {
    var lastUsed = settings.value("/SmartField/GeometryEditorLastUsed", -1);
    if (lastUsed >= 0 && lastUsed < editors.rowCount()) {
      selectorRow.stateVisible = false;
      var toolbarQml = editors.data(editors.index(lastUsed, 0), GeometryEditorsModelSingleton.ToolbarRole);
      var iconPath = editors.data(editors.index(lastUsed, 0), GeometryEditorsModelSingleton.IconPathRole);
      var name = editors.data(editors.index(lastUsed, 0), GeometryEditorsModelSingleton.NameRole);
      geometryEditorsToolbar.image = Theme.getThemeVectorIcon(iconPath);
      toolbarRow.load(toolbarQml, iconPath, name);
    }
  }

  function cancelEditors() {
    if (toolbarRow.item) {
      toolbarRow.item.cancel();
    }
    featureModel.vertexModel.clear();
  }

  // returns true if handled
  function canvasClicked(point, type) {
    if (toolbarRow.item && toolbarRow.visible)
      return toolbarRow.item.canvasClicked(point, type);
    else
      return false;
  }

  // returns true if handled
  function canvasLongPressed(point, type) {
    if (toolbarRow.item && toolbarRow.visible)
      return toolbarRow.item.canvasLongPressed(point, type);
    else
      return false;
  }

  // returns true if handled or not defined
  function canvasFreehandBegin() {
    if (toolbarRow.item && toolbarRow.visible)
      return toolbarRow.item.canvasFreehandBegin ? toolbarRow.item.canvasFreehandBegin() : true;
    else
      return false;
  }

  // returns true if handled or not defined
  function canvasFreehandEnd() {
    if (toolbarRow.item && toolbarRow.visible)
      return toolbarRow.item.canvasFreehandEnd ? toolbarRow.item.canvasFreehandEnd() : true;
    else
      return false;
  }

  VisibilityFadingRow {
    id: selectorRow
    stateVisible: true

    spacing: 4

    Repeater {
      model: editors
      delegate: QfToolButton {
        round: true
        bgcolor: Theme.mainColor
        iconSource: Theme.getThemeVectorIcon(iconPath)
        visible: GeometryEditorsModelSingleton.supportsGeometry(featureModel.vertexModel.geometry, supportedGeometries)
        onClicked: {
          // close current tool
          if (toolbarRow.item) {
            toolbarRow.item.cancel();
          }
          selectorRow.stateVisible = false;
          geometryEditorsToolbar.image = Theme.getThemeVectorIcon(iconPath);
          toolbarRow.load(toolbar, iconPath, name);
          settings.setValue("/SmartField/GeometryEditorLastUsed", index);
        }
      }
    }
  }

  Loader {
    id: toolbarRow

    width: item && item.stateVisible ? item.implicitWidth : 0

    function load(qmlSource, iconPath, name) {
      source = qmlSource;
      item.init(geometryEditorsToolbar.featureModel, geometryEditorsToolbar.mapSettings, geometryEditorsToolbar.editorRubberbandModel, geometryEditorsToolbar.editorRenderer);
      if (toolbarRow.item.screenHovering !== undefined)
        toolbarRow.item.screenHovering = geometryEditorsToolbar.screenHovering;
      if (toolbarRow.item.vertexRubberbandVisible !== undefined)
        vertexRubberband.isVisible = toolbarRow.item.vertexRubberbandVisible;
      else
        vertexRubberband.isVisible = false;
      toolbarRow.item.stateVisible = true;
      displayToast(name);
    }

    onSourceChanged: {
      geometryEditorsToolbar.editorChanged();
    }
  }

  onScreenHoveringChanged: {
    if (toolbarRow.item && toolbarRow.item.screenHovering !== undefined)
      toolbarRow.item.screenHovering = geometryEditorsToolbar.screenHovering;
  }

  Connections {
    target: toolbarRow.item

    function onFinished() {
      featureModel.vertexModel.clear();
    }
  }

  QfToolButton {
    id: activeToolButton
    iconSource: Theme.getThemeIcon("more_horiz")
    round: true
    visible: !selectorRow.stateVisible && !(toolbarRow.item && toolbarRow.item.stateVisible && toolbarRow.item.blocking)
    bgcolor: Theme.mainColor
    onClicked: {
      toolbarRow.item.cancel();
      toolbarRow.source = '';
      vertexRubberband.isVisible = false;
      selectorRow.stateVisible = true;
      image = Theme.getThemeIcon("ic_edit_geometry_white");
      settings.setValue("/SmartField/GeometryEditorLastUsed", -1);
    }
  }
}
