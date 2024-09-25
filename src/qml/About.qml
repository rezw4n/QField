import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import Theme 1.0
import org.smartfield 1.0

Item {
  id: aboutPanel

  Rectangle {
    color: "black"
    opacity: 0.8
    anchors.fill: parent
  }

  ColumnLayout {
    id: aboutContainer
    spacing: 6
    anchors.fill: parent
    anchors.margins: 20
    anchors.topMargin: 20 + mainWindow.sceneTopMargin
    anchors.bottomMargin: 20 + mainWindow.sceneBottomMargin

    ScrollView {
      Layout.fillWidth: true
      Layout.fillHeight: true
      ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
      ScrollBar.vertical.policy: ScrollBar.AsNeeded
      contentItem: information
      contentWidth: information.width
      contentHeight: information.height
      clip: true

      MouseArea {
        anchors.fill: parent
        onClicked: aboutPanel.visible = false
      }

      ColumnLayout {
        id: information
        spacing: 6
        width: aboutPanel.width - 40
        height: Math.max(mainWindow.height - linksButton.height * 2 - smartfieldAppDirectoryLabel.height - aboutContainer.spacing * 3 - aboutContainer.anchors.topMargin - aboutContainer.anchors.bottomMargin, smartfieldPart.height + opengisPart.height + spacing)

        ColumnLayout {
          id: smartfieldPart
          Layout.fillHeight: true
          Layout.alignment: Qt.AlignHCenter

          MouseArea {
            Layout.preferredWidth: 138
            Layout.preferredHeight: 138
            Image {
              id: smartfieldLogo
              width: parent.width
              height: parent.height
              source: "qrc:/images/smartfield_logo.svg"
              sourceSize.width: width * screen.devicePixelRatio
              sourceSize.height: height * screen.devicePixelRatio
            }
            onClicked: Qt.openUrlExternally("https://smartfield.org/")
          }

          Label {
            Layout.fillWidth: true
            Layout.maximumWidth: parent.width
            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            font: Theme.strongFont
            color: Theme.light
            textFormat: Text.RichText
            text: {
              var links = '<a href="https://github.com/rezw4n/' + gitRev + '">' + gitRev.substr(0, 6) + '</a>';
              if (appVersion && appVersion !== '1.0.0')
                links += ' <a href="https://github.com/rezw4n' + appVersion + '">' + appVersion + '</a>';
              return "SmartField<br>" + appVersionStr + " (" + links + ")<br>Qt " + qVersion;
            }
            onLinkActivated: link => Qt.openUrlExternally(link)
          }
        }

        ColumnLayout {
          id: opengisPart
          Layout.fillHeight: true
          Layout.alignment: Qt.AlignHCenter

          MouseArea {
            Layout.preferredWidth: 91
            Layout.preferredHeight: 113
            Image {
              id: opengisLogo
              width: parent.width
              height: parent.height
              source: "qrc:/images/opengis-logo.svg"
              sourceSize.width: width * screen.devicePixelRatio
              sourceSize.height: height * screen.devicePixelRatio
            }
          }

          Label {
            Layout.fillWidth: true
            Layout.maximumWidth: parent.width
            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            font: Theme.strongFont
            color: Theme.light
            textFormat: Text.RichText
            text: qsTr("Developed by") + '<br><a href="">AstroTech</a>'
            onLinkActivated: link => Qt.openUrlExternally(link)
          }
        }
      }
    }

    Label {
      id: smartfieldAppDirectoryLabel
      Layout.fillWidth: true
      Layout.maximumWidth: parent.width
      Layout.alignment: Qt.AlignCenter
      Layout.bottomMargin: 10
      horizontalAlignment: Text.AlignHCenter
      font: Theme.tinyFont
      color: Theme.secondaryTextColor
      textFormat: Text.RichText

      text: {
        let label = '';
        let isDesktopPlatform = Qt.platform.os !== "ios" && Qt.platform.os !== "android";
        let dataDirs = platformUtilities.appDataDirs();
        return label;
      }

      onLinkActivated: link => Qt.openUrlExternally(link)
    }

    QfButton {
      id: sponsorshipButton
      Layout.fillWidth: true
      icon.source: Theme.getThemeVectorIcon('ic_sponsor_white_24dp')

      text: qsTr('Made with Love')
    }

    QfButton {
      id: linksButton
      dropdown: true
      Layout.fillWidth: true
      icon.source: Theme.getThemeVectorIcon('ic_book_white_24dp')

      text: qsTr('Documentation')

      onClicked: {
        Qt.openUrlExternally("https://docs.smartfield.org/");
      }

      onDropdownClicked: {
        linksMenu.popup(linksButton.width - linksMenu.width + 10, linksButton.y + 10);
      }
    }
  }

  Menu {
    id: linksMenu
    title: qsTr("Links Menu")

    width: {
      var result = 0;
      var padding = 0;
      for (var i = 0; i < count; ++i) {
        var item = itemAt(i);
        result = Math.max(item.contentItem.implicitWidth, result);
        padding = Math.max(item.padding, padding);
      }
      return result + padding * 2;
    }

    MenuItem {
      text: qsTr('Changelog')

      font: Theme.defaultFont
      height: 48
      leftPadding: Theme.menuItemLeftPadding
      icon.source: Theme.getThemeVectorIcon('ic_speaker_white_24dp')

      onTriggered: {
        changelogPopup.open();
      }
    }
  }
}
