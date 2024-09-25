import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import org.qgis 1.0
import org.smartfield 1.0
import Theme 1.0

Popup {
  id: popup

  width: Math.min(400, mainWindow.width - Theme.popupScreenEdgeMargin)
  height: mainWindow.height - 160
  x: (parent.width - width) / 2
  y: (parent.height - height) / 2
  padding: 0

  Page {
    id: page
    width: parent.width
    height: parent.height
    padding: 10
    header: QfPageHeader {
      id: pageHeader
      title: qsTr("Plugins")

      showBackButton: false
      showApplyButton: false
      showCancelButton: true
      backgroundFill: false

      onCancel: {
        popup.close();
      }
    }

    ColumnLayout {
      spacing: 4
      width: parent.width
      height: parent.height

      Label {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: 20
        visible: pluginsList.model.count === 0

        text: qsTr('No plugins have been installed yet. To learn more about plugins, %1read the documentation%2.').arg('<a href="https://docs.smartfield.org/how-to/plugins/">').arg('</a>')
        font: Theme.defaultFont
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        onLinkActivated: Qt.openUrlExternally(link)
      }

      ListView {
        id: pluginsList
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: model.count > 0
        clip: true

        model: ListModel {
        }

        delegate: Rectangle {
          id: rectangle
          width: parent.width
          height: inner.height + 10
          color: "transparent"

          GridLayout {
            id: inner
            width: parent.width
            anchors.leftMargin: 20
            anchors.rightMargin: 20

            columns: 2
            columnSpacing: 0
            rowSpacing: 2

            RowLayout {
              Layout.fillWidth: true

              Image {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24

                source: Icon !== '' ? 'file://' + Icon : ''
                fillMode: Image.PreserveAspectFit
                mipmap: true
              }

              Label {
                Layout.fillWidth: true
                text: Name
                font: Theme.defaultFont
                color: Theme.mainTextColor
                wrapMode: Text.WordWrap

                MouseArea {
                  anchors.fill: parent
                  onClicked: {
                    if (!Enabled) {
                      pluginManager.enableAppPlugin(Uuid);
                    } else {
                      pluginManager.disableAppPlugin(Uuid);
                    }
                  }
                }
              }
            }

            QfSwitch {
              id: toggleEnabledPlugin
              Layout.preferredWidth: implicitContentWidth
              checked: Enabled

              onClicked: {
                Enabled = checked == true;
                if (Enabled) {
                  pluginManager.enableAppPlugin(Uuid);
                } else {
                  pluginManager.disableAppPlugin(Uuid);
                }
              }
            }

            ColumnLayout {
              Layout.fillWidth: true

              Label {
                Layout.fillWidth: true
                text: qsTr('Authored by %1%2%3').arg('<a href="details">').arg(Author).arg(' ⚠</a>')
                font: Theme.tipFont
                color: Theme.secondaryTextColor
                wrapMode: Text.WordWrap
                onLinkActivated: link => {
                  authorDetails.authorName = Author;
                  authorDetails.authorHomepage = Homepage;
                  authorDetails.open();
                }
              }

              Label {
                Layout.fillWidth: true
                text: Description
                font: Theme.tipFont
                color: Theme.secondaryTextColor
                wrapMode: Text.WordWrap
              }

              Label {
                Layout.fillWidth: true
                text: "<a href='delete'>" + (Version != "" ? qsTr("Uninstall version %1").arg(Version) : qsTr("Uninstall plugin")) + "</a>"
                font: Theme.tipFont
                color: Theme.secondaryTextColor
                wrapMode: Text.WordWrap

                onLinkActivated: link => {
                  uninstallConfirmation.pluginName = Name;
                  uninstallConfirmation.pluginUuid = Uuid;
                  uninstallConfirmation.open();
                }
              }
            }
          }
        }
      }

      QfButton {
        id: installFromUrlButton
        Layout.fillWidth: true
        dropdown: true

        text: qsTr("Install plugin from URL")

        onClicked: {
          installFromUrlDialog.open();
        }

        onDropdownClicked: {
          pluginsManagementMenu.popup(installFromUrlButton.width - pluginsManagementMenu.width + 10, installFromUrlButton.y + 10);
        }
      }

      Menu {
        id: pluginsManagementMenu
        title: qsTr('Plugins management menu')

        width: {
          let result = 50;
          let padding = 0;
          for (let i = 0; i < count; ++i) {
            let item = itemAt(i);
            result = Math.max(item.contentItem.implicitWidth, result);
            padding = Math.max(item.leftPadding + item.rightPadding, padding);
          }
          return mainWindow.width > 0 ? Math.min(result + padding, mainWindow.width - 20) : result + padding;
        }

        MenuItem {
          text: qsTr('Clear remembered permissions')

          font: Theme.defaultFont
          height: 48
          leftPadding: Theme.menuItemLeftPadding

          onTriggered: {
            pluginManager.clearPluginPermissions();
          }
        }
      }
    }
  }

  Dialog {
    id: authorDetails
    title: authorName
    parent: mainWindow.contentItem
    x: (mainWindow.width - width) / 2
    y: (mainWindow.height - height - 80) / 2

    property string authorName: ""
    property string authorHomepage: ""

    Column {
      width: mainWindow.width - 60 < authorWarningLabelMetrics.width ? mainWindow.width - 60 : authorWarningLabelMetrics.width
      height: childrenRect.height
      spacing: 10

      TextMetrics {
        id: authorWarningLabelMetrics
        font: authorWarningLabel.font
        text: authorWarningLabel.text
      }

      Label {
        id: authorHomepageLabel
        visible: authorDetails.authorHomepage !== ""
        width: parent.width
        text: "<a href='" + authorDetails.authorHomepage + "'>" + authorDetails.authorHomepage + "</a>"
        wrapMode: Text.WordWrap
        font: Theme.defaultFont
        color: Theme.mainTextColor

        onLinkActivated: link => {
          Qt.openUrlExternally(link);
        }
      }

      Label {
        id: authorWarningLabel
        width: parent.width
        text: "⚠ " + qsTr("The author details shown above are self-reported by the plugin and not independently verified. Please make sure you trust the plugin's origin.")
        wrapMode: Text.WordWrap
        font: Theme.defaultFont
        color: Theme.mainTextColor
      }
    }

    standardButtons: Dialog.Close
  }

  Dialog {
    id: installFromUrlDialog
    title: "Install Plugin from URL"
    parent: mainWindow.contentItem
    focus: true
    font: Theme.defaultFont

    x: (mainWindow.width - width) / 2
    y: (mainWindow.height - height - 80) / 2

    onAboutToShow: {
      installFromUrlInput.text = '';
    }

    Column {
      width: childrenRect.width
      height: childrenRect.height
      spacing: 10

      TextMetrics {
        id: installFromUrlLabelMetrics
        font: installFromUrlLabel.font
        text: installFromUrlLabel.text
      }

      Label {
        id: installFromUrlLabel
        width: mainWindow.width - 60 < installFromUrlLabelMetrics.width ? mainWindow.width - 60 : installFromUrlLabelMetrics.width
        text: qsTr("Type a URL below to download and install a plugin:")
        wrapMode: Text.WordWrap
        font: Theme.defaultFont
        color: Theme.mainTextColor
      }

      QfTextField {
        id: installFromUrlInput
        width: installFromUrlLabel.width
      }
    }

    standardButtons: Dialog.Ok | Dialog.Cancel
    onAccepted: {
      pluginManager.installFromUrl(installFromUrlInput.text);
    }
  }

  Dialog {
    id: uninstallConfirmation
    title: "Uninstall Plugin"
    parent: mainWindow.contentItem
    x: (mainWindow.width - width) / 2
    y: (mainWindow.height - height - 80) / 2

    property string pluginName: ""
    property string pluginUuid: ""

    Column {
      width: childrenRect.width
      height: childrenRect.height
      spacing: 10

      TextMetrics {
        id: uninstallLabelMetrics
        font: uninstallLabel.font
        text: uninstallLabel.text
      }

      Label {
        id: uninstallLabel
        width: mainWindow.width - 60 < uninstallLabelMetrics.width ? mainWindow.width - 60 : uninstallLabelMetrics.width
        text: qsTr("Are you sure you want to uninstall `%1`?").arg(uninstallConfirmation.pluginName)
        wrapMode: Text.WordWrap
        font: Theme.defaultFont
        color: Theme.mainTextColor
      }
    }

    standardButtons: Dialog.Ok | Dialog.Cancel
    onAccepted: {
      pluginManager.uninstall(pluginUuid);
    }
  }

  Connections {
    target: pluginManager

    function onInstallTriggered(name) {
      pageHeader.busyIndicatorState = "on";
      pageHeader.busyIndicatorValue = 0;
      displayToast(qsTr("Installing %1").arg(name));
    }

    function onInstallProgress(progress) {
      pageHeader.busyIndicatorValue = progress;
    }

    function onInstallEnded(uuid, error) {
      pageHeader.busyIndicatorState = "off";
      if (uuid !== '') {
        pluginManager.enableAppPlugin(uuid);
      } else {
        displayToast(qsTr('Plugin installation failed: ' + error, 'error'));
      }
    }

    function onAppPluginEnabled(uuid) {
      for (let i = 0; i < pluginsList.model.count; i++) {
        if (pluginsList.model.get(i).Uuid === uuid) {
          pluginsList.model.get(i).Enabled = true;
        }
      }
    }

    function onAppPluginDisabled(uuid) {
      for (let i = 0; i < pluginsList.model.count; i++) {
        if (pluginsList.model.get(i).Uuid === uuid) {
          pluginsList.model.get(i).Enabled = false;
        }
      }
    }

    function onAvailableAppPluginsChanged() {
      refreshAppPluginsList();
    }
  }

  function refreshAppPluginsList() {
    pluginsList.model.clear();
    for (const plugin of pluginManager.availableAppPlugins) {
      pluginsList.model.append({
          "Uuid": plugin.uuid,
          "Enabled": pluginManager.isAppPluginEnabled(plugin.uuid),
          "Name": plugin.name,
          "Description": plugin.description,
          "Author": plugin.author,
          "Homepage": plugin.homepage,
          "Icon": plugin.icon,
          "Version": plugin.version
        });
    }
  }

  Component.onCompleted: {
    refreshAppPluginsList();
  }
}
