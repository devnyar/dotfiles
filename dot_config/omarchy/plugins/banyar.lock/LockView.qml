import QtQuick
import QtQuick.Effects
import "LockTheme.js" as Theme

Item {
  id: root

  property string backgroundPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool unlocking: false
  property bool loadBackground: true
  property string passwordText: ""
  property bool syncingPasswordText: false

  readonly property int spokeCount: 16
  readonly property int hubRadius: 150
  readonly property real centerX: width / 2
  readonly property real centerY: height * 0.545
  readonly property real maxWebRadius: Math.max(260, Math.min(centerY - 40, height - centerY - 90, width / 2 - 60) * 0.9)
  readonly property bool errorState: failureMessage.length > 0
  readonly property int liveSpokes: Math.min(spokeCount, passwordInput.text.length)

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  function fileUrl(path) {
    if (!path) return "";
    var encoded = String(path).split("/").map(encodeURIComponent).join("/");
    return "file://" + encoded + "?v=" + backgroundVersion;
  }

  function forcePasswordFocus() {
    passwordInput.forceActiveFocus();
  }

  function clearPassword() {
    passwordTextEdited("");
  }

  function syncPasswordText() {
    if (passwordInput.text === passwordText) return;
    syncingPasswordText = true;
    passwordInput.text = passwordText;
    syncingPasswordText = false;
  }

  onInputEnabledChanged: {
    if (inputEnabled) Qt.callLater(forcePasswordFocus);
  }
  Component.onCompleted: {
    syncPasswordText();
    if (inputEnabled) Qt.callLater(forcePasswordFocus);
  }

  property bool deniedFlash: false
  onFailureMessageChanged: {
    if (failureMessage.length > 0) {
      deniedFlash = true;
      deniedTimer.restart();
      hubShake.restart();
    }
  }
  Timer {
    id: deniedTimer
    interval: 900
    onTriggered: root.deniedFlash = false
  }

  property int pulseTick: 0
  property int prevPasswordLength: 0
  onPasswordTextChanged: {
    syncPasswordText();
    if (passwordText.length > prevPasswordLength) pulseTick++;
    prevPasswordLength = passwordText.length;
  }
  onDeniedFlashChanged: if (deniedFlash) pulseTick++

  property var now: new Date()
  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.now = new Date()
  }
  readonly property string clockText: Qt.formatTime(now, "hh:mm")
  readonly property string dateText: Qt.formatDate(now, "dddd d MMMM").toUpperCase()

  Rectangle {
    anchors.fill: parent
    color: Theme.darkerBackground

    Image {
      id: wallpaper
      anchors.fill: parent
      source: root.loadBackground ? root.fileUrl(root.backgroundPath) : ""
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      sourceSize.width: width
      sourceSize.height: height
      transformOrigin: Item.Center
      scale: root.unlocking ? 1.05 : 1.0
      Behavior on scale { NumberAnimation { duration: 440; easing.type: Easing.OutCubic } }
    }

    MultiEffect {
      anchors.fill: wallpaper
      source: wallpaper
      autoPaddingEnabled: false
      blurEnabled: root.loadBackground && wallpaper.status === Image.Ready
      blur: 1.0
      blurMax: 128
      blurMultiplier: root.unlocking ? 0 : 1.25
      contrast: root.unlocking ? 0 : -0.08
      Behavior on blurMultiplier { NumberAnimation { duration: 440; easing.type: Easing.OutCubic } }
      Behavior on contrast { NumberAnimation { duration: 440; easing.type: Easing.OutCubic } }
    }

    Rectangle {
      anchors.fill: parent
      opacity: root.unlocking ? 0 : 0.6
      Behavior on opacity { NumberAnimation { duration: 440; easing.type: Easing.OutCubic } }
      gradient: Gradient {
        GradientStop { position: 0.0; color: Theme.lighterBackground }
        GradientStop { position: 0.55; color: Theme.background }
        GradientStop { position: 1.0; color: Theme.darkerBackground }
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: { root.wakeRequested(); root.forcePasswordFocus(); }
      onPositionChanged: root.wakeRequested()
    }

    Item {
      id: chrome
      anchors.fill: parent
      transformOrigin: Item.Center
      scale: root.unlocking ? 0.94 : 1.0
      opacity: root.unlocking ? 0 : 1
      Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
      Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

    LockWeb {
      anchors.fill: parent
      centerX: root.centerX
      centerY: root.centerY
      hubRadius: root.hubRadius
      maxRadius: root.maxWebRadius
      spokeCount: root.spokeCount
      liveCount: root.liveSpokes
      denied: root.deniedFlash
      pulseTick: root.pulseTick
    }

    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      y: Math.max(40, root.centerY - root.maxWebRadius - 190)
      spacing: 10

      Item {
        anchors.horizontalCenter: parent.horizontalCenter
        width: clockMain.implicitWidth
        height: clockMain.implicitHeight

        Text {
          anchors.centerIn: parent
          anchors.horizontalCenterOffset: -4
          text: root.clockText
          color: Theme.cyan
          opacity: 0.6
          font.family: "Archivo Black"
          font.weight: Font.Black
          font.pixelSize: 92
        }
        Text {
          anchors.centerIn: parent
          anchors.horizontalCenterOffset: 4
          text: root.clockText
          color: root.deniedFlash ? Theme.brightRed : Theme.red
          opacity: 0.6
          font.family: "Archivo Black"
          font.weight: Font.Black
          font.pixelSize: 92
        }
        Text {
          id: clockMain
          anchors.centerIn: parent
          text: root.clockText
          color: Theme.foreground
          font.family: "Archivo Black"
          font.weight: Font.Black
          font.pixelSize: 92
        }
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.dateText
        color: Theme.darkForeground
        font.family: "JetBrains Mono"
        font.pixelSize: 15
        font.letterSpacing: 4
      }
    }

    Item {
      id: hub
      x: root.centerX - width / 2
      y: root.centerY - height / 2
      width: root.hubRadius * 2
      height: root.hubRadius * 2

      property real shakeX: 0
      transform: Translate { x: hub.shakeX }
      SequentialAnimation {
        id: hubShake
        NumberAnimation { target: hub; property: "shakeX"; to: -10; duration: 55 }
        NumberAnimation { target: hub; property: "shakeX"; to: 9; duration: 55 }
        NumberAnimation { target: hub; property: "shakeX"; to: -6; duration: 55 }
        NumberAnimation { target: hub; property: "shakeX"; to: 4; duration: 55 }
        NumberAnimation { target: hub; property: "shakeX"; to: 0; duration: 55 }
      }

      Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.lighterBackground
        opacity: 0.95
      }

      Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: root.deniedFlash ? Theme.red : (root.passwordText.length > 0 ? Theme.accent : Qt.rgba(0.29, 0.18, 0.48, 0.9))
        Behavior on border.color { ColorAnimation { duration: 120 } }
      }

      Item {
        anchors.horizontalCenter: parent.horizontalCenter
        y: (heroSpider.y + heroSpider.height / 2 + (heroSpider.height * heroSpider.restScale) / 2 + 14) - hub.y
        width: Math.min(parent.width - 68, Math.max(120, passwordInput.implicitWidth + 24))
        height: 34

        TextInput {
            id: passwordInput
            anchors.centerIn: parent
            width: parent.width
            horizontalAlignment: TextInput.AlignHCenter
            activeFocusOnPress: true
            clip: true
            enabled: root.inputEnabled && !root.authenticatingPassword
            readOnly: root.authenticatingPassword
            echoMode: TextInput.Password
            passwordCharacter: "◆"
            passwordMaskDelay: 0
            color: root.deniedFlash ? Theme.red : Theme.accent
            selectionColor: Theme.selection
            selectedTextColor: Theme.foreground
            font.family: "Archivo Black"
            font.weight: Font.Black
            font.pixelSize: 20
            font.letterSpacing: 6
            cursorVisible: activeFocus && root.inputEnabled && !root.authenticatingPassword && text.length === 0
            cursorDelegate: Rectangle {
              width: 3
              height: 22
              color: Theme.accent
              visible: passwordInput.cursorVisible
              SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0; duration: 500 }
                NumberAnimation { to: 1; duration: 500 }
              }
            }

            onTextChanged: {
              if (!root.syncingPasswordText) root.passwordTextEdited(text);
              if (text.length > 0) root.wakeRequested();
              if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested();
            }

            onAccepted: {
              var submitted = root.passwordText;
              root.passwordTextEdited("");
              if (submitted.length > 0) root.submitPassword(submitted);
            }

            Keys.onPressed: function(event) {
              root.wakeRequested();
              if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
                root.passwordTextEdited("");
                event.accepted = true;
              }
            }
          }

        }
    }
    }

    Item {
      id: heroSpider
      readonly property real restScale: (root.hubRadius * 1.05) / 1024
      x: root.centerX - width / 2
      y: (root.centerY - 38) - height / 2
      width: 1024
      height: 1024
      transformOrigin: Item.Center
      scale: restScale
      opacity: 1.0

      Image {
        id: heroSpiderSrc
        anchors.fill: parent
        source: "SpidermanLogo.png"
        fillMode: Image.PreserveAspectFit
        sourceSize.width: 1024
        sourceSize.height: 1024
        smooth: true
        visible: false
      }

      readonly property real glitchOffset: width * (3 / 157.5)

      MultiEffect {
        anchors.fill: heroSpiderSrc
        source: heroSpiderSrc
        transform: Translate { x: -heroSpider.glitchOffset }
        colorization: 1.0
        colorizationColor: Theme.cyan
        opacity: 0.5
      }
      MultiEffect {
        anchors.fill: heroSpiderSrc
        source: heroSpiderSrc
        transform: Translate { x: heroSpider.glitchOffset }
        colorization: 1.0
        colorizationColor: root.deniedFlash ? Theme.brightRed : Theme.red
        opacity: 0.5
      }
      MultiEffect {
        anchors.fill: heroSpiderSrc
        source: heroSpiderSrc
        colorization: 1.0
        colorizationColor: root.deniedFlash ? Theme.red : (root.passwordText.length > 0 ? Theme.accent : Theme.foreground)
        Behavior on colorizationColor { ColorAnimation { duration: 150 } }
      }

      SequentialAnimation {
        id: authPulse
        loops: Animation.Infinite
        running: root.authenticatingPassword
        onStopped: heroSpider.opacity = 1.0
        NumberAnimation { target: heroSpider; property: "opacity"; to: 0.55; duration: 420; easing.type: Easing.InOutQuad }
        NumberAnimation { target: heroSpider; property: "opacity"; to: 1.0; duration: 420; easing.type: Easing.InOutQuad }
      }

      NumberAnimation {
        id: heroGrowAnim
        target: heroSpider
        property: "scale"
        to: 1.0
        duration: 300
        easing.type: Easing.OutQuint
      }
      NumberAnimation {
        id: heroFadeAnim
        target: heroSpider
        property: "opacity"
        to: 0
        duration: 260
        easing.type: Easing.InQuad
      }
      Timer { id: heroFadeDelay; interval: 200; onTriggered: heroFadeAnim.start() }

      Connections {
        target: root
        function onUnlockingChanged() {
          if (root.unlocking) {
            heroGrowAnim.start();
            heroFadeDelay.start();
          } else {
            heroGrowAnim.stop();
            heroFadeDelay.stop();
            heroFadeAnim.stop();
            heroSpider.scale = heroSpider.restScale;
            heroSpider.opacity = 1.0;
          }
        }
      }
    }

    Item {
      anchors.horizontalCenter: parent.horizontalCenter
      y: root.centerY + root.hubRadius + 46
      width: deniedMain.implicitWidth
      height: deniedMain.implicitHeight
      opacity: root.deniedFlash ? 1 : 0
      scale: root.deniedFlash ? 1 : 0.85
      Behavior on opacity { NumberAnimation { duration: 90 } }
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 3 } }

      Text {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -3
        text: "ACCESS DENIED"
        color: Theme.cyan
        opacity: 0.8
        font.family: "Archivo Black"
        font.weight: Font.Black
        font.pixelSize: 30
        font.letterSpacing: 2
      }
      Text {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: 3
        text: "ACCESS DENIED"
        color: Theme.brightRed
        opacity: 0.8
        font.family: "Archivo Black"
        font.weight: Font.Black
        font.pixelSize: 30
        font.letterSpacing: 2
      }
      Text {
        id: deniedMain
        anchors.centerIn: parent
        text: "ACCESS DENIED"
        color: Theme.foreground
        font.family: "Archivo Black"
        font.weight: Font.Black
        font.pixelSize: 30
        font.letterSpacing: 2
      }
    }

  }
}
