import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Controls.Material 2.14
import QtQuick.Layouts 1.14
import Theme 1.0

ToolBar {
  property alias title: titleLabel.text

  property bool backgroundFill: true

  property alias showBackButton: backButton.visible
  property alias showApplyButton: applyButton.visible
  property alias showCancelButton: cancelButton.visible

  property alias busyIndicatorState: busyIndicator.state
  property alias busyIndicatorValue: busyIndicator.value

  property double topMargin: 0.0

  height: topMargin + 48

  signal cancel
  signal apply
  signal back
  signal finished

  anchors {
    top: parent.top
    left: parent.left
    right: parent.right
  }

  background: Rectangle {
    id: backgroundRect
    color: backgroundFill ? Theme.mainColor : "transparent"

    ProgressBar {
      id: busyIndicator
      anchors.top: parent.bottom
      anchors.left: parent.left
      width: parent.width
      height: 6
      value: 50
      indeterminate: value == 0 ? true : false

      state: "off"

      visible: opacity > 0

      states: [
        State {
          name: 'on'
          PropertyChanges {
            target: busyIndicator
            opacity: 1.0
          }
        },
        State {
          name: 'off'
          PropertyChanges {
            target: busyIndicator
            opacity: 0.0
          }
        }
      ]
      transitions: [
        Transition {
          from: "off"
          to: "on"
          SequentialAnimation {
            NumberAnimation {
              target: busyIndicator
              property: 'opacity'
              duration: 100
            }
          }
        },
        Transition {
          from: "on"
          to: "off"
          SequentialAnimation {
            PauseAnimation {
              duration: 100
            }
            NumberAnimation {
              target: busyIndicator
              property: 'opacity'
              duration: 200
            }
          }
        }
      ]
    }
  }
  Material.foreground: undefined

  RowLayout {
    anchors.fill: parent
    anchors.topMargin: topMargin
    Layout.margins: 0

    QfToolButton {
      id: backButton

      Layout.alignment: Qt.AlignTop | Qt.AlignLeft
      clip: true
      iconSource: Theme.getThemeVectorIcon('ic_arrow_left_white_24dp')
      iconColor: backgroundFill ? Theme.light : Theme.mainTextColor

      onClicked: {
        back();
        finished();
      }
    }

    QfToolButton {
      id: applyButton

      Layout.alignment: Qt.AlignTop | Qt.AlignLeft
      clip: true
      iconSource: Theme.getThemeIcon('ic_check_white_48dp')
      iconColor: backgroundFill ? Theme.light : Theme.mainTextColor

      onClicked: {
        apply();
        finished();
      }
    }

    Label {
      id: titleLabel
      leftPadding: !showApplyButton && showCancelButton ? 48 : 0
      rightPadding: (showApplyButton || showBackButton) && !showCancelButton ? 48 : 0
      font: Theme.strongFont
      color: backgroundFill ? Theme.light : Theme.mainColor
      elide: Label.ElideRight
      horizontalAlignment: Qt.AlignHCenter
      verticalAlignment: Qt.AlignVCenter
      Layout.fillWidth: true
    }

    QfToolButton {
      id: cancelButton

      Layout.alignment: Qt.AlignTop | Qt.AlignRight
      clip: true
      iconSource: Theme.getThemeIcon('ic_close_white_24dp')
      iconColor: backgroundFill ? Theme.light : Theme.mainTextColor

      onClicked: {
        cancel();
        finished();
      }
    }
  }
}
