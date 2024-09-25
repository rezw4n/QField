import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import org.smartfield 1.0
import org.qgis 1.0
import Theme 1.0

Item {
  id: relationCombobox

  property FeatureCheckListModel featureListModel

  property bool useCompleter: false
  property bool useSearch: false
  property bool allowAddFeature: false
  property var relation: undefined

  Component.onCompleted: {
    comboBox.currentIndex = featureListModel.findKey(value);
    invalidWarning.visible = relation !== undefined ? !(relation.isValid) : false;
  }

  anchors {
    left: parent.left
    right: parent.right
  }
  height: childrenRect.height

  property var currentKeyValue: value
  property EmbeddedFeatureForm embeddedFeatureForm: embeddedPopup

  onCurrentKeyValueChanged: {
    comboBox._cachedCurrentValue = currentKeyValue;
    comboBox.currentIndex = featureListModel.findKey(currentKeyValue);
  }

  EmbeddedFeatureForm {
    id: addFeaturePopup

    embeddedLevel: form.embeddedLevel + 1
    digitizingToolbar: form.digitizingToolbar
    codeReader: form.codeReader

    onFeatureSaved: {
      var referencedValue = addFeaturePopup.attributeFormModel.attribute(relationCombobox.relation.resolveReferencedField(field.name));
      var index = featureListModel.findKey(referencedValue);
      if (index < 0) {
        // model not yet reloaded - keep the value and set it onModelReset
        comboBox._cachedCurrentValue = referencedValue;
      } else {
        comboBox.currentIndex = index;
      }
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
      if (searchableText.typedFilter != '') {
        searchField.text = searchableText.typedFilter;
      }
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
        onCancel: searchFeaturePopup.close()
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

        onDisplayTextChanged: {
          featureListModel.searchTerm = searchField.displayText;
        }

        Keys.onPressed: event => {
          if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (featureListModel.rowCount() === 1) {
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
        model: featureListModel
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

        section.property: featureListModel.groupField != "" ? "groupFieldValue" : ""
        section.labelPositioning: ViewSection.CurrentLabelAtStart | ViewSection.InlineLabels
        section.delegate: Component {
          Rectangle {
            width: parent.width
            height: featureListModel.displayGroupName ? 30 : 5
            color: Theme.controlBackgroundAlternateColor

            Text {
              anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
              }
              font.bold: true
              font.pointSize: Theme.resultFont.pointSize
              color: Theme.mainTextColor
              text: section
              visible: featureListModel.displayGroupName
            }
          }
        }

        delegate: Rectangle {
          id: delegateRect

          property int idx: index
          property string itemText: featureListModel.searchTerm != '' ? displayString.replace(new RegExp('(' + featureListModel.searchTerm + ')', "i"), '<span style="text-decoration:underline;' + Theme.toInlineStyles({
                "color": Theme.mainTextColor
              }) + '">$1</span>') : displayString

          anchors.margins: 10
          height: radioButton.visible ? radioButton.height : checkBoxButton.height
          width: parent ? parent.width : undefined
          color: model.checked ? Theme.mainColor : searchFeaturePopup.Material ? searchFeaturePopup.Material.dialogColor : Theme.mainBackgroundColor

          Row {
            RadioButton {
              id: radioButton

              visible: !featureListModel.allowMulti
              anchors.verticalCenter: parent.verticalCenter
              width: resultsList.width - padding * 2
              padding: 12

              font.pointSize: Theme.defaultFont.pointSize
              font.weight: model.checked ? Font.DemiBold : Font.Normal

              checked: model.checked
              indicator: Rectangle {
              }

              text: itemText
              contentItem: Text {
                text: parent.text
                font: parent.font
                width: parent.width
                verticalAlignment: Text.AlignVCenter
                leftPadding: parent.indicator.width + parent.spacing
                elide: Text.ElideRight
                color: featureListModel.searchTerm != '' ? Theme.secondaryTextColor : Theme.mainTextColor
                textFormat: Text.RichText
              }
            }

            CheckBox {
              id: checkBoxButton

              visible: !!featureListModel.allowMulti
              anchors.verticalCenter: parent.verticalCenter
              width: resultsList.width - padding * 2
              padding: 12

              font.pointSize: Theme.defaultFont.pointSize
              font.weight: model.checked ? Font.DemiBold : Font.Normal

              text: itemText
              contentItem: Text {
                text: parent.text
                font: parent.font
                width: parent.width
                verticalAlignment: Text.AlignVCenter
                leftPadding: parent.indicator.width + parent.spacing
                elide: Text.ElideRight
                color: Theme.mainTextColor
                textFormat: Text.RichText
              }
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
            model.checked = true;
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
            model.checked = !model.checked;
            if (!resultsList.model.allowMulti) {
              searchFeaturePopup.close();
            }
          }
        }

        onMovementStarted: {
          Qt.inputMethod.hide();
        }
      }
    }
  }

  RowLayout {
    anchors {
      left: parent.left
      right: parent.right
    }

    ComboBox {
      id: comboBox
      visible: !enabled || (!useSearch && !useCompleter && (relation !== undefined ? relation.isValid : true))
      Layout.fillWidth: true

      property var _cachedCurrentValue

      model: featureListModel
      textRole: 'display'
      valueRole: 'keyFieldValue'

      onCurrentIndexChanged: {
        var newValue = featureListModel.dataFromRowIndex(currentIndex, FeatureListModel.KeyFieldRole);
        if (newValue !== currentKeyValue) {
          valueChangeRequested(newValue, false);
        }
      }

      Connections {
        target: featureListModel

        function onModelReset() {
          comboBox.currentIndex = featureListModel.findKey(comboBox._cachedCurrentValue);
        }
      }

      MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true

        onClicked: mouse => {
          mouse.accepted = false;
        }
        onPressed: mouse => {
          forceActiveFocus();
          mouse.accepted = false;
        }
        onReleased: mouse => {
          mouse.accepted = false;
        }
        onDoubleClicked: mouse => {
          mouse.accepted = false;
        }
        onPositionChanged: mouse => {
          mouse.accepted = false;
        }
        onPressAndHold: mouse => {
          mouse.accepted = false;
        }
      }

      Component.onCompleted: {
        comboBox.popup.z = 10000; // 1000s are embedded feature forms, use a higher value to insure popups always show above embedded feature formes
      }

      font: Theme.defaultFont

      contentItem: Text {
        leftPadding: enabled ? 5 : 0
        height: fontMetrics.height + 20
        text: comboBox.currentIndex == -1 && value !== undefined ? '(' + value + ')' : comboBox.currentText
        font: comboBox.font
        color: value === undefined || !enabled ? Theme.mainTextDisabledColor : Theme.mainTextColor
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
      }

      popup: Popup {
        y: comboBox.height - 1
        width: comboBox.width
        implicitHeight: contentItem.implicitHeight
        padding: 1
        font: Theme.defaultFont
        topMargin: mainWindow.sceneTopMargin
        bottomMargin: mainWindow.sceneTopMargin

        contentItem: ListView {
          clip: true
          implicitHeight: Math.min(mainWindow.height - mainWindow.sceneTopMargin - mainWindow.sceneTopMargin, contentHeight)
          model: comboBox.popup.visible ? comboBox.delegateModel : null
          currentIndex: comboBox.highlightedIndex

          section.property: featureListModel.groupField != "" ? "groupFieldValue" : ""
          section.labelPositioning: ViewSection.CurrentLabelAtStart | ViewSection.InlineLabels
          section.delegate: Component {
            Rectangle {
              width: parent.width
              height: featureListModel.displayGroupName ? 30 : 5
              color: Theme.mainBackgroundColor

              Text {
                anchors {
                  horizontalCenter: parent.horizontalCenter
                  verticalCenter: parent.verticalCenter
                }
                font.bold: true
                font.pointSize: Theme.resultFont.pointSize
                color: Theme.mainTextColor
                text: section
                visible: featureListModel.displayGroupName
              }
            }
          }

          ScrollIndicator.vertical: ScrollIndicator {
          }
        }
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
          visible: enabled
          anchors.fill: parent
          border.color: comboBox.pressed ? Theme.accentColor : Theme.accentLightColor
          border.width: comboBox.visualFocus ? 2 : 1
          color: Theme.controlBackgroundAlternateColor
          radius: 2
        }
      }
    }

    FontMetrics {
      id: fontMetrics
      font: comboBox.font
    }

    Rectangle {
      id: searchable
      visible: !comboBox.visible
      height: fontMetrics.height + 12
      Layout.fillWidth: true
      Layout.topMargin: 5
      Layout.bottomMargin: 5

      Text {
        id: searchableLabel

        property bool useCompleter: false
        property string completer: ''

        anchors.verticalCenter: parent.verticalCenter
        topPadding: 0
        leftPadding: 5
        rightPadding: 5
        bottomPadding: 0
        width: parent.width - dropDownArrowCanvas.width - dropDownArrowCanvas.anchors.rightMargin * 2
        height: fontMetrics.height + 12
        text: useCompleter ? completer : comboBox.displayText
        font: comboBox.font
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        textFormat: Text.RichText
        clip: true
        elide: Text.ElideRight

        color: value === undefined || !enabled ? Theme.mainTextDisabledColor : searchableText.text === '' ? Theme.mainTextColor : Theme.mainTextDisabledColor
      }

      TextField {
        id: searchableText

        property string typedFilter: ''

        anchors.verticalCenter: parent.verticalCenter
        topPadding: 0
        rightPadding: 5
        leftPadding: 5
        bottomPadding: 0
        topInset: 0
        bottomInset: 0
        width: parent.width - dropDownArrowCanvas.width - dropDownArrowCanvas.anchors.rightMargin * 2
        text: ''
        font: comboBox.font
        horizontalAlignment: TextInput.AlignLeft
        verticalAlignment: TextInput.AlignVCenter

        color: Theme.mainTextColor
        background: Rectangle {
          color: "transparent"
          border.color: "transparent"
          border.width: 0
        }

        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhSensitiveData

        onDisplayTextChanged: {
          if (activeFocus) {
            if (text != comboBox.displayText) {
              var trimmedText = text.trim();
              var matches = featureListModel.findDisplayValueMatches(trimmedText);
              if (matches.length > 0) {
                var remainder = featureListModel.dataFromRowIndex(matches[0], featureListModel.DisplayStringRole).substring(trimmedText.length);
                searchableLabel.completer = '<span style="color:rgba(0,0,0,0);">' + trimmedText + '</span><span style="font-weight:' + (matches.length === 1 ? 'bold' : 'normal') + ';">' + remainder + '</span>';
                color = Theme.mainTextColor;
              } else {
                searchableLabel.completer = '';
                color = Theme.warningColor;
              }
            } else {
              searchableLabel.completer = '';
            }
          }
        }

        onActiveFocusChanged: {
          searchableLabel.useCompleter = activeFocus;
          if (activeFocus) {
            if (text === '') {
              if (!featureListModel.addNull || comboBox.currentIndex != 0) {
                text = comboBox.displayText;
                color = Theme.mainTextColor;
              }
              searchableLabel.completer = '';
            }
          } else {
            if (!isLastKeyPressedReturn) {
              if (text === '' && featureListModel.addNull) {
                comboBox.currentIndex = 0;
                searchableLabel.completer = comboBox.displayText;
              } else {
                applyAutoCompletion(true);
              }
            } else if (text !== '') {
              // the last return-triggered auto completion didn't match anything, we have to reset the item state
              text = '';
              searchableLabel.completer = comboBox.displayText;
            }
          }
          isLastKeyPressedReturn = false;
        }

        property bool isLastKeyPressedReturn: false
        Keys.onPressed: event => {
          if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (!isLastKeyPressedReturn) {
              applyAutoCompletion();
            }
            isLastKeyPressedReturn = true;
          } else {
            isLastKeyPressedReturn = false;
          }
        }

        function applyAutoCompletion(resetIfNone = false) {
          var trimmedText = text.trim();
          var matches = featureListModel.findDisplayValueMatches(trimmedText);
          if (matches.length > 0) {
            text = '';
            comboBox.currentIndex = matches[0];
            searchableLabel.completer = comboBox.displayText;
            if (matches.length > 1) {
              // remember the typed filter in case users want to see the multiple hits by clicking on the search button
              typedFilter = trimmedText;
              searchableTimer.restart();
            }
          } else if (resetIfNone) {
            text = '';
            searchableLabel.completer = comboBox.displayText;
          }
        }

        Timer {
          id: searchableTimer
          interval: 500
          onTriggered: {
            searchableText.typedFilter = '';
          }
        }
      }

      Canvas {
        id: dropDownArrowCanvas
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 30
        height: 15
        contextType: "2d"
        visible: !useCompleter

        onPaint: {
          if (!context) {
            return;
          }
          context.reset();
          context.moveTo(10, 5);
          context.lineTo(20, 5);
          context.lineTo(15, 10);
          context.closePath();
          context.fillStyle = !enabled ? Theme.mainTextDisabledColor : Theme.mainTextColor;
          context.fill();
        }

        onEnabledChanged: requestPaint()
      }

      border.color: comboBox.pressed ? Theme.accentColor : Theme.accentLightColor
      border.width: comboBox.visualFocus ? 2 : 1
      color: Theme.controlBackgroundAlternateColor
      radius: 2

      MouseArea {
        enabled: !useCompleter
        anchors.fill: parent

        onClicked: mouse => {
          mouse.accepted = true;
          searchFeaturePopup.open();
        }
      }
    }

    QfToolButton {
      id: searchButton

      Layout.preferredWidth: enabled ? 48 : 0
      Layout.preferredHeight: 48

      bgcolor: "transparent"
      iconSource: Theme.getThemeIcon("ic_baseline_search_black")
      iconColor: Theme.mainTextColor

      visible: enabled

      onClicked: {
        searchFeaturePopup.open();
      }
    }

    QfToolButton {
      id: addFeatureButton

      Layout.preferredWidth: comboBox.enabled ? 48 : 0
      Layout.preferredHeight: 48

      bgcolor: "transparent"
      opacity: enabled ? 1 : 0.3
      iconSource: Theme.getThemeIcon("ic_add_black_48dp")
      iconColor: Theme.mainTextColor

      visible: enabled && allowAddFeature && relation !== undefined && relation.isValid

      onClicked: {
        embeddedPopup.state = 'Add';
        embeddedPopup.currentLayer = relationCombobox.relation ? relationCombobox.relation.referencedLayer : null;
        embeddedPopup.open();
      }
    }

    Text {
      id: invalidWarning
      visible: false
      text: qsTr("Invalid relation")
      color: Theme.errorColor
    }
  }

  EmbeddedFeatureForm {
    id: embeddedPopup

    embeddedLevel: form.embeddedLevel + 1
    digitizingToolbar: form.digitizingToolbar
    codeReader: form.codeReader

    onFeatureSaved: {
      var referencedValue = embeddedPopup.attributeFormModel.attribute(relationCombobox.relation.resolveReferencedField(field.name));
      var index = featureListModel.findKey(referencedValue);
      if ((featureListModel.addNull == true && index < 1) || index < 0) {
        // model not yet reloaded - keep the value and set it onModelReset
        comboBox._cachedCurrentValue = referencedValue;
      } else {
        comboBox.currentIndex = index;
      }
    }
  }
}
