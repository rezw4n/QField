import QtQuick 2.14
import QtQuick.Controls 2.14
import Theme 1.0

Container {
  id: container

  enum Direction {
    Up,
    Down,
    Left,
    Right
  }

  property string name: ''
  property real size: 48
  property int direction: QfToolButtonDrawer.Direction.Down
  property bool collapsed: true
  property alias round: toggleButton.round
  property alias bgcolor: toggleButton.bgcolor
  property alias iconSource: toggleButton.iconSource
  property alias iconColor: toggleButton.iconColor

  onNameChanged: {
    collapsed = settings.valueBool("SmartField/QfToolButtonContainer/" + name + "/collapsed", true);
  }

  width: {
    switch (container.direction) {
    case QfToolButtonDrawer.Direction.Up:
    case QfToolButtonDrawer.Direction.Down:
      return size;
    case QfToolButtonDrawer.Direction.Left:
    case QfToolButtonDrawer.Direction.Right:
      return collapsed ? size : size + content.contentWidth + container.spacing * 2;
    }
  }
  height: {
    switch (container.direction) {
    case QfToolButtonDrawer.Direction.Up:
    case QfToolButtonDrawer.Direction.Down:
      return collapsed ? size : size + content.contentHeight + container.spacing * 2;
    case QfToolButtonDrawer.Direction.Left:
    case QfToolButtonDrawer.Direction.Right:
      return size;
    }
  }
  spacing: 4
  clip: true

  Behavior on width  {
    enabled: true
    NumberAnimation {
      duration: 200
    }
  }

  Behavior on height  {
    enabled: true
    NumberAnimation {
      duration: 200
    }
  }

  contentItem: Rectangle {
    radius: size / 2
    color: Qt.hsla(toggleButton.bgcolor.hslHue, toggleButton.bgcolor.hslSaturation, toggleButton.bgcolor.hslLightness, 0.3)
    clip: true

    ListView {
      id: content
      width: {
        switch (container.direction) {
        case QfToolButtonDrawer.Direction.Up:
        case QfToolButtonDrawer.Direction.Down:
          return container.size;
        case QfToolButtonDrawer.Direction.Left:
        case QfToolButtonDrawer.Direction.Right:
          return content.contentWidth;
        }
      }
      height: {
        switch (container.direction) {
        case QfToolButtonDrawer.Direction.Up:
        case QfToolButtonDrawer.Direction.Down:
          return content.contentHeight;
        case QfToolButtonDrawer.Direction.Left:
        case QfToolButtonDrawer.Direction.Right:
          return container.size;
        }
      }
      x: {
        switch (container.direction) {
        case QfToolButtonDrawer.Direction.Up:
        case QfToolButtonDrawer.Direction.Down:
        case QfToolButtonDrawer.Direction.Left:
          return container.spacing;
        case QfToolButtonDrawer.Direction.Right:
          return container.size + container.spacing;
        }
      }
      y: {
        switch (container.direction) {
        case QfToolButtonDrawer.Direction.Up:
        case QfToolButtonDrawer.Direction.Left:
        case QfToolButtonDrawer.Direction.Right:
          return container.spacing;
        case QfToolButtonDrawer.Direction.Down:
          return container.size + container.spacing;
        }
      }
      model: container.contentModel
      snapMode: ListView.SnapToItem
      orientation: container.direction === QfToolButtonDrawer.Direction.Up || container.direction === QfToolButtonDrawer.Direction.Down ? ListView.Vertical : ListView.Horizontal
      spacing: container.spacing
    }

    QfToolButton {
      id: toggleButton
      width: container.size
      height: container.size
      x: {
        switch (direction) {
        case QfToolButtonDrawer.Direction.Down:
        case QfToolButtonDrawer.Direction.Right:
          return 0;
        case QfToolButtonDrawer.Direction.Up:
        case QfToolButtonDrawer.Direction.Left:
          return container.width - container.size;
        }
      }
      y: {
        switch (direction) {
        case QfToolButtonDrawer.Direction.Down:
        case QfToolButtonDrawer.Direction.Right:
          return 0;
        case QfToolButtonDrawer.Direction.Up:
        case QfToolButtonDrawer.Direction.Left:
          return container.height - container.size;
        }
      }
      round: true

      onClicked: {
        container.collapsed = !container.collapsed;
        if (name != "") {
          settings.setValue("SmartField/QfToolButtonContainer/" + name + "/collapsed", container.collapsed);
        }
      }
    }
  }
}
