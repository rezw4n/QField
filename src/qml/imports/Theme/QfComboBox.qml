import QtQuick.Controls 2.14
import QtQuick.Controls.impl 2.14
import QtQuick 2.14
import QtQuick.Controls.Material 2.14
import QtQuick.Controls.Material.impl 2.14

ComboBox {
  id: comboBox

  contentItem: Text {
    leftPadding: enabled ? 5 : 0

    text: comboBox.displayText
    font: comboBox.font
    color: enabled ? Theme.mainTextColor : Theme.mainTextDisabledColor
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignLeft
    elide: Text.ElideRight
  }

  background: Item {
    implicitWidth: 120
    implicitHeight: 36

    Rectangle {
      visible: !enabled
      y: comboBox.height - 2
      width: comboBox.width
      height: comboBox.activeFocus ? 2 : 1
      color: comboBox.activeFocus ? Theme.accentColor : Theme.accentLightColor
    }

    Rectangle {
      id: backgroundRect
      visible: enabled
      anchors.fill: parent
      border.color: comboBox.pressed ? Theme.accentColor : Theme.accentLightColor
      border.width: comboBox.visualFocus ? 2 : 1
      color: Theme.controlBackgroundAlternateColor
      radius: 2
    }
  }
}
