import QtQuick 2.14
import QtQuick.Controls 2.14
import Theme 1.0
import org.smartfield 1.0
import org.qgis 1.0
import "."

ProcessingParameterWidgetBase {
  id: distanceItem

  height: childrenRect.height

  Row {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    spacing: 5

    QfComboBox {
      id: unitTypesComboBox

      width: parent.width
      model: configuration["options"]

      onCurrentIndexChanged: {
        if (currentIndex != value) {
          valueChangeRequested(currentIndex);
        }
      }

      Component.onCompleted: {
        currentIndex = value;
      }
    }
  }
}
