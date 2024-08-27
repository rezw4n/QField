import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.qfield
import Theme

ColumnLayout {
  function reset() {
    Qt.inputMethod.hide();
    table.model.reloadVariables();
  }

  function apply() {
    table.model.save();
  }

  anchors.fill: parent
  Layout.fillWidth: true
  Layout.fillHeight: true
  spacing: 4

  Rectangle {
    Layout.fillWidth: true
    Layout.fillHeight: true
    color: Theme.mainBackgroundColor
    border.color: Theme.controlBorderColor
    border.width: 1

    ListView {
      id: table
      model: ExpressionVariableModel {
        currentProject: qgisProject
      }
      flickableDirection: Flickable.VerticalFlick
      boundsBehavior: Flickable.StopAtBounds
      clip: true
      spacing: 1
      anchors.fill: parent
      anchors.margins: 3
      anchors.leftMargin: 9
      anchors.rightMargin: 5

      delegate: Rectangle {
        id: rectangle
        width: parent ? parent.width : 0
        height: line.height
        color: "transparent"

        property var itemRow: index
        property bool canDelete: VariableEditable && VariableScope == ExpressionVariableModel.GlobalScope

        function forceFocusOnVariableName() {
          variableNameText.forceActiveFocus();
        }

        Row {
          id: line
          spacing: 5

          QfSwipeAnimator {
            id: variableNameTextAnimator
            width: 0.35 * table.width - 10
            height: 40
            shouldAutoFlick: (width < variableNameText.implicitWidth) && !dragging && !variableNameText.activeFocus
            contentImplicitWidth: variableNameText.implicitWidth
            contentWidth: variableNameText.implicitWidth
            duration: shouldAutoFlick ? Math.abs(variableNameText.width - width) * 100 + 10 : 10000

            TextField {
              id: variableNameText
              topPadding: 10
              bottomPadding: 10
              leftPadding: 1
              rightPadding: 1
              width: variableNameTextAnimator.width
              text: VariableName
              enabled: VariableScope == ExpressionVariableModel.GlobalScope && VariableEditable
              font: Theme.tipFont
              horizontalAlignment: TextInput.AlignLeft
              placeholderText: displayText === '' ? qsTr("Enter name") : ''
              background: Rectangle {
                y: variableNameText.height - height - variableNameText.bottomPadding / 2
                height: variableNameText.activeFocus ? 2 : variableNameText.enabled ? 1 : 0
                width: Math.max(variableNameTextAnimator.width, variableNameText.implicitWidth)
                color: variableNameText.activeFocus ? Theme.accentColor : "transparent"
              }

              onTextChanged: {
                if (enabled && VariableName != text) {
                  VariableName = text;
                }
              }

              onCursorRectangleChanged: {
                variableNameTextAnimator.ensureCursorVisible(cursorRectangle);
              }
            }
          }

          QfSwipeAnimator {
            id: variableValueTextAnimator
            width: 0.65 * table.width - 10 - (canDelete ? deleteVariableButton.width : 0)
            height: 40
            shouldAutoFlick: (width < variableValueText.implicitWidth) && !dragging && !variableValueText.activeFocus
            contentImplicitWidth: variableValueText.implicitWidth
            contentWidth: variableValueText.implicitWidth
            duration: shouldAutoFlick ? Math.abs(variableValueText.width - width) * 100 + 10 : 10000

            TextField {
              id: variableValueText
              topPadding: 10
              bottomPadding: 10
              leftPadding: 1
              rightPadding: 1
              width: variableValueTextAnimator.width
              text: VariableValue
              enabled: VariableEditable
              font: Theme.tipFont
              horizontalAlignment: TextInput.AlignLeft
              placeholderText: displayText === '' ? qsTr("Enter value") : ''
              background: Rectangle {
                y: variableValueText.height - height - variableValueText.bottomPadding / 2
                height: variableValueText.activeFocus ? 2 : variableNameText.enabled ? 1 : 0
                width: Math.max(variableValueTextAnimator.width, variableValueText.implicitWidth)
                color: variableValueText.activeFocus ? Theme.accentColor : "transparent"
              }

              onTextChanged: {
                if (enabled && VariableValue != text) {
                  VariableValue = text;
                  if (VariableScope == ExpressionVariableModel.ProjectScope) {
                    projectInfo.saveVariable(VariableName, text);
                  }
                }
              }

              onCursorRectangleChanged: {
                variableValueTextAnimator.ensureCursorVisible(cursorRectangle);
              }
            }
          }

          QfToolButton {
            id: deleteVariableButton
            width: 36
            height: 36
            anchors.verticalCenter: parent.verticalCenter
            visible: canDelete

            iconSource: Theme.getThemeIcon('ic_delete_forever_white_24dp')
            iconColor: Theme.mainTextColor
            bgcolor: "transparent"

            onClicked: {
              table.model.removeVariable(VariableScope, variableNameText.text);
            }
          }
        }
      }
    }
  }

  QfButton {
    id: addCustomVariableButton
    Layout.fillWidth: true
    text: qsTr("Add a new variable")

    onClicked: {
      let insertionPosition = table.model.addVariable(ExpressionVariableModel.GlobalScope, "new_variable", "");
      table.positionViewAtIndex(insertionPosition, ListView.Contain);
      table.itemAtIndex(insertionPosition).forceFocusOnVariableName();
    }
  }
}
