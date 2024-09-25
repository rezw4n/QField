import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts
import QtQuick.Controls.Material 2.14
import QtQuick.Controls.Material.impl 2.14
import org.smartfield 1.0
import org.qgis 1.0
import Theme 1.0
import "."
import ".."

EditorWidgetBase {
  id: valueMap

  anchors {
    left: parent.left
    right: parent.right
  }

  property var currentKeyValue: value

  // Workaround to get a signal when the value has changed
  onCurrentKeyValueChanged: {
    comboBox.currentIndex = comboBox.model.keyToIndex(currentKeyValue);
  }

  height: childrenRect.height
  enabled: isEnabled

  states: [
    // showing QfToggleButton without search
    State {
      name: "toggleButtonsView"
      PropertyChanges {
        target: toggleButtons
        visible: true
      }
      PropertyChanges {
        target: comboBox
        visible: false
      }
      PropertyChanges {
        target: searchButton
        visible: false
      }
    },
    // showing ComboBox with search option
    State {
      name: "comboBoxItemView"
      PropertyChanges {
        target: toggleButtons
        visible: false
      }
      PropertyChanges {
        target: comboBox
        visible: true
      }
      PropertyChanges {
        target: searchButton
        visible: searchButton.enabled
      }
    }
  ]

  // Using the search and comboBox when there are less than X items in the dropdown proves to be poor UI on normally
  // sized and oriented phones. Some empirical tests proved 6 to be a good number for now.
  readonly property int toggleButtonsThreshold: currentLayer && currentLayer.customProperty('SmartFieldSync/value_map_button_interface_threshold') !== undefined ? currentLayer.customProperty('SmartFieldSync/value_map_button_interface_threshold') : 0
  state: currentItemCount < toggleButtonsThreshold ? "toggleButtonsView" : "comboBoxItemView"

  property real currentItemCount: comboBox.count

  ValueMapModel {
    id: listModel
    filterCaseSensitivity: Qt.CaseInsensitive
    onMapChanged: {
      comboBox.currentIndex = keyToIndex(valueMap.currentKeyValue);
    }
  }

  RowLayout {
    anchors {
      left: parent.left
      right: parent.right
    }

    Item {
      id: toggleButtons
      Layout.fillWidth: true
      Layout.minimumHeight: flow.height + flow.anchors.topMargin + flow.anchors.bottomMargin

      property real selectedIndex: comboBox.currentIndex
      property string currentSelectedKey: ""
      property string currentSelectedValue: ""

      Flow {
        id: flow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 6
        anchors.bottomMargin: 6
        spacing: 8

        Repeater {
          id: repeater
          model: comboBox.model

          delegate: Rectangle {
            id: item
            width: Math.min(flow.width - 16, innerText.width + 16)
            height: 34
            radius: 4
            color: selected ? isEnabled ? Theme.mainColor : Theme.accentLightColor : "transparent"
            border.color: isEnabled ? selected ? Theme.mainColor : Theme.accentLightColor : "transparent"
            border.width: 1

            property bool selected: toggleButtons.selectedIndex == index

            Component.onCompleted: {
              if (selected) {
                toggleButtons.currentSelectedKey = key;
                toggleButtons.currentSelectedValue = value;
              }
            }

            Behavior on color  {
              ColorAnimation {
                duration: 150
              }
            }

            Text {
              id: innerText
              width: Math.min(flow.width - 32, implicitWidth)
              text: value
              elide: Text.ElideRight
              anchors.centerIn: parent
              font: Theme.defaultFont
              color: isEnabled ? Theme.mainTextColor : Theme.mainTextDisabledColor
            }

            MouseArea {
              id: mouseArea
              anchors.fill: parent
              onClicked: {
                if (toggleButtons.selectedIndex != index) {
                  comboBox.currentIndex = index;
                  toggleButtons.currentSelectedKey = key;
                  toggleButtons.currentSelectedValue = value;
                } else {
                  comboBox.currentIndex = -1;
                  toggleButtons.currentSelectedKey = "";
                  toggleButtons.currentSelectedValue = "";
                }
                valueChangeRequested(toggleButtons.currentSelectedKey, false);
              }

              Ripple {
                clip: true
                width: parent.width
                height: parent.height
                pressed: mouseArea.pressed
                anchor: parent
                color: Theme.darkTheme ? "#22ffffff" : "#22000000"
              }
            }
          }
        }
      }

      Rectangle {
        y: flow.height + flow.anchors.topMargin + flow.anchors.bottomMargin - 1
        visible: !isEnabled
        width: flow.width
        height: flow.activeFocus ? 2 : 1
        color: flow.activeFocus ? Theme.accentColor : Theme.accentLightColor
      }
    }

    QfComboBox {
      id: comboBox
      Layout.fillWidth: true
      font: Theme.defaultFont
      popup.font: Theme.defaultFont
      popup.topMargin: mainWindow.sceneTopMargin
      popup.bottomMargin: mainWindow.sceneTopMargin
      currentIndex: model.keyToIndex(value)
      model: listModel
      textRole: 'value'

      Component.onCompleted: {
        comboBox.popup.z = 10000; // 1000s are embedded feature forms, use a higher value to insure popups always show above embedded feature formes
        model.valueMap = config['map'];
      }

      onCurrentTextChanged: {
        if (searchFeaturePopup.opened || valueMap.state !== "comboBoxItemView") {
          return;
        }
        var key = model.keyForValue(currentText);
        if (currentKeyValue !== key) {
          if (valueMap.state === "comboBoxItemView") {
            valueChangeRequested(key, false);
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true

        onClicked: mouse.accepted = false
        onPressed: mouse => {
          forceActiveFocus();
          mouse.accepted = false;
        }
        onReleased: mouse.accepted = false
        onDoubleClicked: mouse.accepted = false
        onPositionChanged: mouse.accepted = false
        onPressAndHold: mouse.accepted = false
      }
    }

    FontMetrics {
      id: fontMetrics
      font: comboBox.font
    }

    QfToolButton {
      id: searchButton

      Layout.preferredWidth: enabled ? 48 : 0
      Layout.preferredHeight: 48

      bgcolor: "transparent"
      iconSource: Theme.getThemeIcon("ic_baseline_search_black")
      iconColor: Theme.mainTextColor

      onClicked: {
        searchFeaturePopup.open();
      }
    }

    Popup {
      id: searchFeaturePopup

      parent: mainWindow.contentItem
      x: Theme.popupScreenEdgeMargin
      y: Theme.popupScreenEdgeMargin
      z: 10000 // 1000s are embedded feature forms, use a higher value to insure feature form popups always show above embedded feature formes
      width: parent.width - Theme.popupScreenEdgeMargin * 2
      height: parent.height - Theme.popupScreenEdgeMargin * 2
      padding: 0
      modal: true
      closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
      focus: visible

      onOpened: {
        if (resultsList.contentHeight > resultsList.height) {
          searchField.forceActiveFocus();
        }
      }

      onClosed: {
        searchField.text = '';
      }

      Page {
        anchors.fill: parent

        header: QfPageHeader {
          title: fieldLabel
          showBackButton: false
          showApplyButton: false
          showCancelButton: true
          onCancel: {
            searchFeaturePopup.close();
            listModel.setFilterFixedString('');
            comboBox.currentIndex = listModel.keyToIndex(valueMap.currentKeyValue);
          }
        }

        TextField {
          id: searchField
          z: 1
          anchors.left: parent.left
          anchors.right: parent.right

          placeholderText: !focus && displayText === '' ? qsTr("Search…") : ''
          placeholderTextColor: Theme.mainColor

          height: fontMetrics.height * 2.5
          padding: 24
          bottomPadding: 9
          font: Theme.defaultFont
          selectByMouse: true
          verticalAlignment: TextInput.AlignVCenter

          inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhSensitiveData

          onDisplayTextChanged: listModel.setFilterFixedString(displayText)

          Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              if (listModel.rowCount() === 1) {
                resultsList.itemAtIndex(0).performClick();
                searchFeaturePopup.close();
              }
            }
          }
        }

        QfToolButton {
          id: clearButton
          z: 1
          width: fontMetrics.height
          height: fontMetrics.height
          anchors {
            top: searchField.top
            right: searchField.right
            topMargin: height - 7
            rightMargin: height - 7
          }

          padding: 0
          iconSource: Theme.getThemeIcon("ic_clear_black_18dp")
          iconColor: Theme.mainTextColor
          bgcolor: "transparent"

          opacity: searchField.displayText.length > 0 ? 1 : 0.25

          onClicked: {
            searchField.text = '';
          }
        }

        ListView {
          id: resultsList
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: searchField.bottom
          model: listModel

          width: parent.width
          height: searchFeaturePopup.height - searchField.height - 50
          clip: true

          ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            width: 6
            contentItem: Rectangle {
              implicitWidth: 6
              implicitHeight: 25
              color: Theme.mainColor
            }
          }

          delegate: Rectangle {
            id: delegateRect

            property string itemText: value ? value : "NULL"
            property bool itemChecked: currentKeyValue == key

            anchors.margins: 10
            height: radioButton.height
            width: parent ? parent.width : undefined
            color: itemChecked ? Theme.mainColor : searchFeaturePopup.Material ? searchFeaturePopup.Material.dialogColor : Theme.mainBackgroundColor

            RadioButton {
              id: radioButton

              anchors.verticalCenter: parent.verticalCenter
              width: resultsList.width - padding * 2
              padding: 12

              font.pointSize: Theme.defaultFont.pointSize
              font.weight: itemChecked ? Font.DemiBold : Font.Normal
              font.italic: value ? false : true

              checked: itemChecked
              indicator: Rectangle {
              }

              text: searchField.displayText !== '' ? itemText.replace(new RegExp('(' + searchField.displayText + ')', "i"), '<span style="text-decoration:underline;' + Theme.toInlineStyles({
                    "color": Theme.mainTextColor
                  }) + '">$1</span>') : itemText

              contentItem: Text {
                text: parent.text
                font: parent.font
                width: parent.width
                verticalAlignment: Text.AlignVCenter
                leftPadding: parent.indicator.width + parent.spacing
                elide: Text.ElideRight
                color: searchField.displayText !== '' ? Theme.secondaryTextColor : Theme.mainTextColor
                textFormat: Text.RichText
              }
            }

            /* bottom border */
            Rectangle {
              anchors.bottom: parent.bottom
              height: 1
              color: Theme.controlBorderColor
              width: resultsList.width
            }

            function performClick() {
              if (key === currentKeyValue) {
                return;
              }
              listModel.setFilterFixedString('');
              valueChangeRequested(key, false);
              searchFeaturePopup.close();
            }
          }

          MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true

            onClicked: mouse => {
              var item = resultsList.itemAt(resultsList.contentX + mouse.x, resultsList.contentY + mouse.y);
              if (!item)
                return;
              item.performClick();
            }
          }

          onMovementStarted: {
            Qt.inputMethod.hide();
          }
        }
      }
    }
  }
}
