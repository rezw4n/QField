import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import org.smartfield 1.0
import Theme 1.0

Item {
  id: smartcloudLogin

  property bool isServerUrlEditingActive: false
  property bool isVisible: false

  Image {
    id: sourceImg
    fillMode: Image.Stretch
    width: parent.width
    height: 200
    smooth: true
    opacity: 1
    source: "qrc:/images/smartcloud_background.svg"
    sourceSize.width: 1024
    sourceSize.height: 1024
  }

  ColumnLayout {
    id: connectionSettings
    width: parent.width
    Layout.maximumWidth: 410
    spacing: 0

    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.maximumWidth: 410
      Layout.minimumHeight: (logo.height + fontMetrics.height * 9) * 2
      Layout.alignment: Qt.AlignHCenter
      spacing: 10

      Image {
        id: logo
        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        fillMode: Image.PreserveAspectFit
        smooth: true
        source: "qrc:/images/smartcloud_logo.svg"
        sourceSize.width: 124
        sourceSize.height: 124

        MouseArea {
          anchors.fill: parent
          onDoubleClicked: toggleServerUrlEditing()
        }
      }

      Text {
        id: loginFeedbackLabel
        Layout.fillWidth: true
        visible: false
        text: qsTr("Failed to sign in")
        horizontalAlignment: Text.AlignHCenter
        font: Theme.defaultFont
        color: Theme.errorColor
        wrapMode: Text.Wrap

        Connections {
          target: cloudConnection

          function onLoginFailed(reason) {
            if (!smartfieldCloudLogin.parent.visible)
              return;
            loginFeedbackLabel.visible = true;
            loginFeedbackLabel.text = reason;
          }

          function onStatusChanged() {
            if (cloudConnection.status === SmartCloudConnection.Connecting) {
              loginFeedbackLabel.visible = false;
              loginFeedbackLabel.text = '';
            } else {
              loginFeedbackLabel.visible = cloudConnection.status === SmartCloudConnection.Disconnected && loginFeedbackLabel.text.length;
            }
          }
        }
      }

      Text {
        id: serverUrlLabel
        Layout.fillWidth: true
        visible: cloudConnection.status === SmartCloudConnection.Disconnected && (cloudConnection.url !== cloudConnection.defaultUrl || isServerUrlEditingActive)
        text: qsTr("Server URL\n(Leave empty to use the default server)")
        horizontalAlignment: Text.AlignHCenter
        font: Theme.defaultFont
        color: 'gray'
        wrapMode: Text.WordWrap
      }

      QfTextField {
        id: serverUrlField
        Layout.preferredWidth: parent.width / 1.3
        Layout.alignment: Qt.AlignHCenter
        visible: cloudConnection.status === SmartCloudConnection.Disconnected && (prefixUrlWithProtocol(cloudConnection.url) !== cloudConnection.defaultUrl || isServerUrlEditingActive)
        enabled: visible
        font: Theme.defaultFont
        horizontalAlignment: Text.AlignHCenter
        text: prefixUrlWithProtocol(cloudConnection.url) === cloudConnection.defaultUrl ? '' : cloudConnection.url

        onTextChanged: text = text.replace(/\s+/g, '')
        onEditingFinished: cloudConnection.url = text ? prefixUrlWithProtocol(text) : cloudConnection.defaultUrl
        Keys.onReturnPressed: loginFormSumbitHandler()

        function prefixUrlWithProtocol(url) {
          if (!url || url.startsWith('http://') || url.startsWith('https://'))
            return url;
          return 'https://' + url;
        }
      }

      Text {
        id: usernamelabel
        Layout.fillWidth: true
        visible: cloudConnection.status === SmartCloudConnection.Disconnected
        text: qsTr("Username or email")
        horizontalAlignment: Text.AlignHCenter
        font: Theme.defaultFont
        color: Theme.mainTextColor
      }

      QfTextField {
        id: usernameField
        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhPreferLowercase
        Layout.preferredWidth: parent.width / 1.3
        Layout.alignment: Qt.AlignHCenter
        visible: cloudConnection.status === SmartCloudConnection.Disconnected
        enabled: visible
        font: Theme.defaultFont
        horizontalAlignment: Text.AlignHCenter

        onTextChanged: text = text.replace(/\s+/g, '')
        Keys.onReturnPressed: loginFormSumbitHandler()
      }

      Text {
        id: passwordlabel
        Layout.fillWidth: true
        visible: cloudConnection.status === SmartCloudConnection.Disconnected
        text: qsTr("Password")
        horizontalAlignment: Text.AlignHCenter
        font: Theme.defaultFont
        color: Theme.mainTextColor
      }

      QfTextField {
        id: passwordField
        echoMode: TextInput.Password
        inputMethodHints: Qt.ImhHiddenText | Qt.ImhNoPredictiveText | Qt.ImhSensitiveData | Qt.ImhNoAutoUppercase | Qt.ImhPreferLowercase
        Layout.preferredWidth: parent.width / 1.3
        Layout.alignment: Qt.AlignHCenter
        visible: cloudConnection.status === SmartCloudConnection.Disconnected
        enabled: visible
        font: Theme.defaultFont
        horizontalAlignment: Text.AlignHCenter

        Keys.onReturnPressed: loginFormSumbitHandler()
      }

      FontMetrics {
        id: fontMetrics
        font: Theme.defaultFont
      }

      QfButton {
        Layout.fillWidth: true
        text: cloudConnection.status == SmartCloudConnection.LoggedIn ? qsTr("Sign out") : cloudConnection.status == SmartCloudConnection.Connecting ? qsTr("Signing in, please wait") : qsTr("Sign in")
        enabled: cloudConnection.status != SmartCloudConnection.Connecting

        onClicked: loginFormSumbitHandler()
      }

      Text {
        id: cloudRegisterLabel
        Layout.fillWidth: true
        Layout.topMargin: 6
        text: qsTr('New user?') + ' <a href="https://app.smartfield.cloud/accounts/signup/">' + qsTr('Register an account') + '</a>.'
        horizontalAlignment: Text.AlignHCenter
        font: Theme.defaultFont
        color: Theme.mainTextColor
        textFormat: Text.RichText
        wrapMode: Text.WordWrap
        visible: cloudConnection.status === SmartCloudConnection.Disconnected

        onLinkActivated: link => {
          if (Qt.platform.os === "ios" || Qt.platform.os === "android") {
            browserPopup.url = link;
            browserPopup.fullscreen = true;
            browserPopup.open();
          } else {
            Qt.openUrlExternally(link);
          }
        }
      }

      Text {
        id: cloudIntroLabel
        Layout.fillWidth: true
        text: qsTr('The easiest way to transfer you project from QGIS/ArcGIS Enterprise to your devices!') + ' <a href="https://smartfield.cloud/">' + qsTr('Learn more about SmartCloud') + '</a>.'
        horizontalAlignment: Text.AlignHCenter
        font: Theme.defaultFont
        color: Theme.mainTextColor
        textFormat: Text.RichText
        wrapMode: Text.WordWrap

        onLinkActivated: link => {
          Qt.openUrlExternally(link);
        }
      }

      Item {
        // spacer item
        Layout.fillWidth: true
        Layout.fillHeight: true
      }
    }
  }

  Connections {
    target: cloudConnection

    function onStatusChanged() {
      if (cloudConnection.status === SmartCloudConnection.LoggedIn)
        usernameField.text = cloudConnection.username;
    }
  }

  function loginFormSumbitHandler() {
    if (cloudConnection.status == SmartCloudConnection.LoggedIn) {
      cloudConnection.logout();
    } else {
      cloudConnection.username = usernameField.text;
      cloudConnection.password = passwordField.text;
      cloudConnection.login();
    }
  }

  function toggleServerUrlEditing() {
    if (cloudConnection.url != cloudConnection.defaultUrl) {
      isServerUrlEditingActive = true;
      return;
    }
    isServerUrlEditingActive = !isServerUrlEditingActive;
  }
}
