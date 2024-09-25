import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Controls.Material.impl 2.14
import QtQuick.Layouts 1.14
import QtQuick.Particles 2.14
import QtCore
import org.smartfield 1.0
import Theme 1.0

Page {
  id: welcomeScreen

  property bool firstShown: false

  property alias model: table.model
  signal openLocalDataPicker
  signal showSmartCloudScreen

  Settings {
    id: registry
    category: 'SmartField'

    property string baseMapProject: ''
    property string defaultProject: ''
    property bool loadProjectOnLaunch: false
  }

  Rectangle {
    id: welcomeBackground
    anchors.fill: parent
    gradient: Gradient {
      GradientStop {
        position: 0.0
        color: Theme.darkTheme ? "#99000000" : "#99A5A5A5"
      }
      GradientStop {
        position: 0.33
        color: Theme.mainBackgroundColor
      }
    }
  }

  ScrollView {
    padding: 0
    topPadding: Math.max(0, Math.min(80, (mainWindow.height - welcomeGrid.height) / 2 - 45))
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AsNeeded
    contentItem: welcomeGrid
    contentWidth: welcomeGrid.width
    contentHeight: welcomeGrid.height
    anchors.fill: parent
    clip: true

    GridLayout {
      id: welcomeGrid
      columns: 1
      rowSpacing: 4

      width: mainWindow.width

      ImageDial {
        id: imageDialLogo
        value: 1

        Layout.margins: 6
        Layout.topMargin: 14
        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        Layout.preferredWidth: Math.min(138, mainWindow.height / 4)
        Layout.preferredHeight: Math.min(138, mainWindow.height / 4)

        source: "qrc:/images/smartfield_logo.svg"
        rotationOffset: 220
      }

      SwipeView {
        id: feedbackView
        visible: false

        Layout.margins: 6
        Layout.topMargin: 10
        Layout.bottomMargin: 10
        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        Layout.preferredWidth: Math.min(410, mainWindow.width - 30)
        Layout.preferredHeight: Math.max(ohno.childrenRect.height, intro.childrenRect.height, ohyeah.childrenRect.height)
        clip: true

        Behavior on Layout.preferredHeight  {
          NumberAnimation {
            duration: 100
            easing.type: Easing.InQuad
          }
        }

        interactive: false
        currentIndex: 1
        Item {
          id: ohno

          Rectangle {
            anchors.fill: parent
            gradient: Gradient {
              GradientStop {
                position: 0.0
                color: "#4480cc28"
              }
              GradientStop {
                position: 0.88
                color: "#0580cc28"
              }
            }

            radius: 6
          }

          ColumnLayout {
            spacing: 0
            anchors.centerIn: parent

            Text {
              Layout.margins: 6
              Layout.maximumWidth: feedbackView.width - 12
              text: qsTr("We're sorry to hear that. Click on the button below to comment or seek support.")
              font: Theme.defaultFont
              color: Theme.mainTextColor
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.WordWrap
            }

            RowLayout {
              spacing: 6
              Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
              Layout.bottomMargin: 10
              QfButton {
                leftPadding: 20
                rightPadding: 20

                text: qsTr("Reach out")
                icon.source: Theme.getThemeIcon('ic_create_white_24dp')

                onClicked: {
                  Qt.openUrlExternally("https://www.smartfield.org/");
                  feedbackView.Layout.preferredHeight = 0;
                }
              }
            }
          }
        }

        Item {
          id: intro

          Rectangle {
            anchors.fill: parent
            gradient: Gradient {
              GradientStop {
                position: 0.0
                color: "#4480cc28"
              }
              GradientStop {
                position: 0.88
                color: "#0580cc28"
              }
            }

            radius: 6
          }

          ColumnLayout {
            spacing: 0
            anchors.centerIn: parent

            Text {
              Layout.margins: 6
              Layout.maximumWidth: feedbackView.width - 12
              text: qsTr("Hey there, how do you like your experience with SmartField so far?")
              font: Theme.defaultFont
              color: Theme.mainTextColor
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.WordWrap
            }

            RowLayout {
              spacing: 6
              Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
              Layout.bottomMargin: 10
              QfToolButton {
                iconSource: Theme.getThemeVectorIcon('ic_dissatisfied_white_24dp')
                bgcolor: Theme.mainColor
                round: true

                onClicked: {
                  feedbackView.currentIndex = 0;
                }
              }
              QfToolButton {
                iconSource: Theme.getThemeVectorIcon('ic_satisfied_white_24dp')
                bgcolor: Theme.mainColor
                round: true

                onClicked: {
                  feedbackView.currentIndex = 2;
                }
              }
            }
          }
        }
        Item {
          id: ohyeah

          Rectangle {
            anchors.fill: parent
            gradient: Gradient {
              GradientStop {
                position: 0.0
                color: "#4480cc28"
              }
              GradientStop {
                position: 0.88
                color: "#0580cc28"
              }
            }

            radius: 6
          }

          ColumnLayout {
            spacing: 0
            anchors.centerIn: parent

            Text {
              Layout.margins: 6
              Layout.maximumWidth: feedbackView.width - 12
              text: qsTr("That's great! We'd love for you to click on the button below and leave a comment on the store.")
              font: Theme.defaultFont
              color: Theme.mainTextColor
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.WordWrap
            }

            RowLayout {
              spacing: 6
              Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
              Layout.margins: 6
              Layout.bottomMargin: 10
              QfButton {
                leftPadding: 20
                rightPadding: 20

                text: qsTr("Rate us")
                icon.source: Theme.getThemeVectorIcon('ic_star_white_24dp')

                onClicked: {
                  Qt.openUrlExternally("market://details?id=ch.opengis.smartfield");
                  feedbackView.Layout.preferredHeight = 0;
                }
              }
            }
          }
        }
      }

      SwipeView {
        id: collectionView
        visible: false

        Layout.margins: 0
        Layout.topMargin: 10
        Layout.bottomMargin: 10
        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        Layout.preferredWidth: Math.min(410, mainWindow.width - 20)
        Layout.preferredHeight: Math.max(collectionOhno.childrenRect.height, collectionIntro.childrenRect.height)
        clip: true

        Behavior on Layout.preferredHeight  {
          NumberAnimation {
            duration: 100
            easing.type: Easing.InQuad
          }
        }

        interactive: false
        currentIndex: 1
        Item {
          id: collectionOhno

          Rectangle {
            anchors.fill: parent
            gradient: Gradient {
              GradientStop {
                position: 0.0
                color: "#4480cc28"
              }
              GradientStop {
                position: 0.88
                color: "#0580cc28"
              }
            }

            radius: 6
          }

          ColumnLayout {
            spacing: 0
            anchors.centerIn: parent

            Text {
              Layout.margins: 6
              Layout.maximumWidth: collectionView.width - 12
              text: qsTr("Anonymized metrics collection has been disabled. You can re-enable through the settings panel.")
              font: Theme.defaultFont
              color: Theme.mainTextColor
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.WordWrap
            }
          }
        }

        Item {
          id: collectionIntro

          Rectangle {
            anchors.fill: parent
            gradient: Gradient {
              GradientStop {
                position: 0.0
                color: "#4480cc28"
              }
              GradientStop {
                position: 0.88
                color: "#0580cc28"
              }
            }

            radius: 6
          }

          ColumnLayout {
            spacing: 0
            anchors.centerIn: parent

            Text {
              Layout.margins: 6
              Layout.maximumWidth: collectionView.width - 12
              text: qsTr("To improve stability for everyone, SmartField collects and sends anonymized metrics.")
              font: Theme.defaultFont
              color: Theme.mainTextColor
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.WordWrap
            }

            RowLayout {
              spacing: 6
              Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
              Layout.bottomMargin: 10
              QfButton {
                text: qsTr('I agree')

                onClicked: {
                  smartfieldSettings.enableInfoCollection = true;
                  collectionView.visible = false;
                }
              }

              QfButton {
                text: qsTr('I prefer not')
                bgcolor: "transparent"
                color: Theme.mainColor

                onClicked: {
                  smartfieldSettings.enableInfoCollection = false;
                  collectionView.visible = false;
                }
              }
            }
          }
        }
      }

      Text {
        id: welcomeText
        visible: !feedbackView.visible
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        Layout.topMargin: 2
        Layout.bottomMargin: 2
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        text: ""
        font: Theme.defaultFont
        color: Theme.mainTextColor
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
      }

      Rectangle {
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        Layout.topMargin: 2
        Layout.bottomMargin: 2
        Layout.fillWidth: true
        Layout.maximumWidth: 410
        Layout.preferredHeight: welcomeActions.height
        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        color: "transparent"

        ColumnLayout {
          id: welcomeActions
          width: parent.width
          spacing: 12

          QfButton {
            id: cloudProjectButton
            Layout.fillWidth: true
            text: qsTr("SmartCloud projects")
            onClicked: {
              showSmartCloudScreen();
            }
          }
          QfButton {
            id: localProjectButton
            Layout.fillWidth: true
            text: qsTr("Open local file")
            onClicked: {
              openLocalDataPicker();
            }
          }

          Text {
            id: recentText
            text: qsTr("Recent Projects")
            font.pointSize: Theme.tipFont.pointSize
            font.bold: true
            color: Theme.mainTextColor
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: table.height
            color: "transparent"
            border.color: "transparent"
            border.width: 1

            ListView {
              id: table
              ScrollBar.vertical: ScrollBar {
              }
              flickableDirection: Flickable.AutoFlickIfNeeded
              boundsBehavior: Flickable.StopAtBounds
              clip: true
              width: parent.width
              height: contentItem.childrenRect.height

              delegate: Rectangle {
                id: rectangle
                objectName: "loadProjectItem_1" // todo, suffix with e.g. ProjectTitle

                property bool isPressed: false
                property string path: ProjectPath
                property string title: ProjectTitle
                property var type: ProjectType

                width: parent ? parent.width : undefined
                height: line.height + 8
                color: "transparent"

                Rectangle {
                  id: lineMask
                  width: line.width
                  height: line.height
                  radius: 10
                  color: "white"
                  visible: false
                  layer.enabled: true
                }

                Rectangle {
                  id: line
                  width: parent.width
                  height: previewImage.status === Image.Ready ? 120 : detailsContainer.height
                  anchors.verticalCenter: parent.verticalCenter
                  color: "transparent"
                  clip: true

                  layer.enabled: true
                  layer.effect: QfOpacityMask {
                    maskSource: lineMask
                  }

                  Image {
                    id: previewImage
                    width: parent.width
                    height: parent.height
                    source: welcomeScreen.visible ? 'image://projects/' + ProjectPath : ''
                    fillMode: Image.PreserveAspectCrop
                  }

                  Ripple {
                    clip: true
                    width: line.width
                    height: line.height
                    pressed: rectangle.isPressed
                    active: rectangle.isPressed
                    color: Qt.hsla(Theme.mainColor.hslHue, Theme.mainColor.hslSaturation, Theme.mainColor.hslLightness, 0.15)
                  }

                  Rectangle {
                    id: detailsContainer
                    color: Qt.hsla(Theme.mainBackgroundColor.hslHue, Theme.mainBackgroundColor.hslSaturation, Theme.mainBackgroundColor.hslLightness, Theme.darkTheme ? 0.75 : 0.9)
                    width: parent.width
                    height: details.childrenRect.height + details.topPadding + details.bottomPadding
                    anchors.bottom: parent.bottom

                    Row {
                      id: details
                      width: parent.width
                      topPadding: 3
                      bottomPadding: 3
                      spacing: 0

                      Image {
                        id: type
                        anchors.verticalCenter: parent.verticalCenter
                        source: switch (ProjectType) {
                        case 0:
                          return Theme.getThemeVectorIcon('ic_map_green_48dp');     // local project
                        case 1:
                          return Theme.getThemeVectorIcon('ic_cloud_project_48dp'); // cloud project
                        case 2:
                          return Theme.getThemeVectorIcon('ic_file_green_48dp');    // local dataset
                        default:
                          return '';
                        }
                        sourceSize.width: 80
                        sourceSize.height: 80
                        width: 40
                        height: 40
                      }
                      ColumnLayout {
                        id: inner
                        anchors.verticalCenter: parent.verticalCenter
                        width: rectangle.width - type.width - 20
                        spacing: 2
                        clip: true

                        Text {
                          id: projectTitle
                          topPadding: 4
                          leftPadding: 3
                          bottomPadding: projectNote.visible ? 0 : 5
                          text: ProjectTitle
                          font.pointSize: Theme.tipFont.pointSize
                          font.underline: true
                          color: Theme.mainColor
                          opacity: rectangle.isPressed ? 0.8 : 1
                          wrapMode: Text.WordWrap
                          Layout.fillWidth: true
                        }
                        Text {
                          id: projectNote
                          leftPadding: 3
                          bottomPadding: 4
                          text: {
                            var notes = [];
                            if (index == 0) {
                              var firstRun = settings && !settings.value("/SmartField/FirstRunFlag", false);
                              if (!firstRun && firstShown === false)
                                notes.push(qsTr("Last session"));
                            }
                            if (ProjectPath === registry.defaultProject) {
                              notes.push(qsTr("Default project"));
                            }
                            if (ProjectPath === registry.baseMapProject) {
                              notes.push(qsTr("Base map"));
                            }
                            if (notes.length > 0) {
                              return notes.join('; ');
                            } else {
                              return "";
                            }
                          }
                          visible: text != ""
                          font.pointSize: Theme.tipFont.pointSize - 2
                          font.italic: true
                          color: Theme.secondaryTextColor
                          wrapMode: Text.WordWrap
                          Layout.fillWidth: true
                        }
                      }
                    }
                  }
                }
              }

              MouseArea {
                property Item pressedItem
                anchors.fill: parent
                onClicked: mouse => {
                  var item = table.itemAt(mouse.x, mouse.y);
                  if (item) {
                    if (item.type == 1 && cloudConnection.hasToken && cloudConnection.status !== SmartCloudConnection.LoggedIn) {
                      cloudConnection.login();
                    }
                    iface.loadFile(item.path, item.title);
                  }
                }
                onPressed: mouse => {
                  var item = table.itemAt(mouse.x, mouse.y);
                  if (item) {
                    pressedItem = item;
                    pressedItem.isPressed = true;
                  }
                }
                onCanceled: {
                  if (pressedItem) {
                    pressedItem.isPressed = false;
                    pressedItem = null;
                  }
                }
                onReleased: {
                  if (pressedItem) {
                    pressedItem.isPressed = false;
                    pressedItem = null;
                  }
                }
                onPressAndHold: mouse => {
                  var item = table.itemAt(mouse.x, mouse.y);
                  if (item) {
                    recentProjectActions.recentProjectPath = item.path;
                    recentProjectActions.recentProjectType = item.type;
                    recentProjectActions.popup(mouse.x, mouse.y);
                  }
                }
              }

              Menu {
                id: recentProjectActions

                property string recentProjectPath: ''
                property int recentProjectType: 0

                title: qsTr('Recent Project Actions')

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

                topMargin: mainWindow.sceneTopMargin
                bottomMargin: mainWindow.sceneBottomMargin

                MenuItem {
                  id: defaultProject
                  visible: recentProjectActions.recentProjectType != 2

                  font: Theme.defaultFont
                  width: parent.width
                  height: visible ? 48 : 0
                  leftPadding: Theme.menuItemCheckLeftPadding
                  checkable: true
                  checked: recentProjectActions.recentProjectPath === registry.defaultProject

                  text: qsTr("Default Project")
                  onTriggered: {
                    registry.defaultProject = recentProjectActions.recentProjectPath === registry.defaultProject ? '' : recentProjectActions.recentProjectPath;
                  }
                }

                MenuItem {
                  id: baseMapProject
                  visible: recentProjectActions.recentProjectType != 2

                  font: Theme.defaultFont
                  width: parent.width
                  height: visible ? 48 : 0
                  leftPadding: Theme.menuItemCheckLeftPadding
                  checkable: true
                  checked: recentProjectActions.recentProjectPath === registry.baseMapProject

                  text: qsTr("Individual Datasets Base Map")
                  onTriggered: {
                    registry.baseMapProject = recentProjectActions.recentProjectPath === registry.baseMapProject ? '' : recentProjectActions.recentProjectPath;
                  }
                }

                MenuSeparator {
                  visible: baseMapProject.visible
                  width: parent.width
                  height: visible ? undefined : 0
                }

                MenuItem {
                  id: removeProject

                  font: Theme.defaultFont
                  width: parent.width
                  height: visible ? 48 : 0
                  leftPadding: Theme.menuItemIconlessLeftPadding

                  text: qsTr("Remove from Recent Projects")
                  onTriggered: {
                    iface.removeRecentProject(recentProjectActions.recentProjectPath);
                    model.reloadModel();
                  }
                }
              }
            }
          }

          RowLayout {
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            Label {
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              topPadding: 10
              bottomPadding: 10
              font: Theme.tipFont
              wrapMode: Text.WordWrap
              color: reloadOnLaunch.checked ? Theme.mainTextColor : Theme.secondaryTextColor

              text: registry.defaultProject != '' ? qsTr('Load default project on launch') : qsTr('Load last opened project on launch')

              MouseArea {
                anchors.fill: parent
                onClicked: reloadOnLaunch.checked = !reloadOnLaunch.checked
              }
            }

            QfSwitch {
              id: reloadOnLaunch
              Layout.preferredWidth: implicitContentWidth
              Layout.alignment: Qt.AlignVCenter
              width: implicitContentWidth
              small: true

              checked: registry.loadProjectOnLaunch
              onCheckedChanged: {
                registry.loadProjectOnLaunch = checked;
              }
            }
          }
        }
      }
    }
  }

  QfToolButton {
    id: currentProjectButton
    visible: false
    anchors {
      top: parent.top
      left: parent.left
      topMargin: mainWindow.sceneTopMargin
    }
    iconSource: Theme.getThemeIcon('ic_chevron_left_black_24dp')
    iconColor: Theme.mainTextColor
    bgcolor: "transparent"

    onClicked: {
      welcomeScreen.visible = false;
      welcomeScreen.focus = false;
    }
  }

  // Sparkles & unicorns
  Rectangle {
    anchors.fill: parent
    color: "#00000000"
    visible: imageDialLogo.value < 0.1

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      hoverEnabled: true
      propagateComposedEvents: true
      onReleased: mouse.accepted = false
      onDoubleClicked: mouse.accepted = false
      onPressAndHold: mouse.accepted = false
      onClicked: mouse => {
        burstSomeSparkles(mouse.x, mouse.y);
        mouse.accepted = false;
      }
      onPressed: mouse => {
        burstSomeSparkles(mouse.x, mouse.y);
        mouse.accepted = false;
      }
      onPositionChanged: mouse => {
        burstSomeSparkles(mouse.x, mouse.y);
        mouse.accepted = false;
      }
    }

    ParticleSystem {
      id: particles
      running: imageDialLogo.value < 0.1
    }

    ParticleSystem {
      id: unicorns
      running: imageDialLogo.value < 0.1
    }

    ImageParticle {
      anchors.fill: parent
      system: particles
      source: "qrc:///particleresources/star.png"
      sizeTable: "qrc:///images/sparkleSize.png"
      alpha: 1
      colorVariation: 0.3
    }

    ImageParticle {
      anchors.fill: parent
      system: unicorns
      source: "qrc:///images/icons/unicorn.png"
      alpha: 1
      redVariation: 0
      blueVariation: 0
      greenVariation: 0
      rotation: 0
      rotationVariation: 360
    }

    Emitter {
      id: emitterParticles
      x: -100
      y: -100
      system: particles
      emitRate: 60
      lifeSpan: 700
      size: 50
      sizeVariation: 10
      maximumEmitted: 100
      velocity: AngleDirection {
        angle: 0
        angleVariation: 360
        magnitude: 100
        magnitudeVariation: 50
      }
    }

    Emitter {
      id: emitterUnicorns
      x: -100
      y: -100
      system: unicorns
      emitRate: 20
      lifeSpan: 900
      size: 70
      sizeVariation: 10
      maximumEmitted: 100
      velocity: AngleDirection {
        angle: 90
        angleVariation: 20
        magnitude: 200
        magnitudeVariation: 50
      }
    }
  }

  function burstSomeSparkles(x, y) {
    emitterParticles.burst(50, x, y);
    emitterUnicorns.burst(1, x, y);
  }

  function adjustWelcomeScreen() {
    if (visible) {
      const currentProjectButtonVisible = !!qgisProject.fileName;
      currentProjectButton.visible = currentProjectButtonVisible;
      if (firstShown) {
        welcomeText.text = " ";
      } else {
        var firstRun = !settings.valueBool("/SmartField/FirstRunDone", false);
        if (firstRun) {
          welcomeText.text = qsTr("Welcome to SmartField. First time using this application? Try the sample projects listed below.");
          settings.setValue("/SmartField/FirstRunDone", true);
          settings.setValue("/SmartField/showMapCanvasGuide", true);
        } else {
          welcomeText.text = qsTr("Welcome back to SmartField.");
        }
      }
    }
  }

  Component.onCompleted: {
    adjustWelcomeScreen();
    var runCount = settings.value("/SmartField/RunCount", 0) * 1;
    var feedbackFormShown = settings.value("/SmartField/FeedbackFormShown", false);
    if (!feedbackFormShown) {
      var now = new Date();
      var dt = settings.value("/SmartField/FirstRunDate", "");
      if (dt != "") {
        dt = new Date(dt);
        var daysToPrompt = 30;
        var runsToPrompt = 5;
        if (runCount >= runsToPrompt && (now - dt) >= (daysToPrompt * 24 * 60 * 60 * 1000)) {
          feedbackView.visible = true;
          settings.setValue("/SmartField/FeedbackFormShown", true);
        }
      } else {
        settings.setValue("/SmartField/FirstRunDate", now.toISOString());
      }
    }
    if (platformUtilities.capabilities & PlatformUtilities.SentryFramework) {
      var collectionFormShown = settings.value("/SmartField/CollectionFormShownV2", false);
      if (!collectionFormShown) {
        collectionView.visible = true;
        settings.setValue("/SmartField/CollectionFormShownV2", true);
      }
    }
    settings.setValue("/SmartField/RunCount", runCount + 1);
    if (registry.defaultProject != '') {
      if (!FileUtils.fileExists(registry.defaultProject)) {
        registry.defaultProject = '';
      }
    }
  }

  onVisibleChanged: {
    adjustWelcomeScreen();
    focus = visible;
    if (!visible) {
      feedbackView.visible = false;
      collectionView.visible = false;
      firstShown = true;
    }
  }
}
