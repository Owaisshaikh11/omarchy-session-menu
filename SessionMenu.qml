import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Ui
import "SessionMenuModel.js" as Model

Item {
  id: root

  // Injected by omarchy-shell when loaded
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null

  // Plugin state
  property bool opened: false
  property var actions: Model.defaultActions()
  property int focusedIndex: -1
  property int confirmingIndex: -1
  property int confirmSeconds: 3
  property string uptimeString: ""

  // Configurable options
  property int cardSize: 96
  property bool confirmDestructive: true
  property bool showBadges: true
  property bool highlightShutdown: true
  property bool showUptime: true

  // Standard Omarchy config location
  readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy"
  readonly property string userConfigPath: configDir + "/session-menu.jsonc"
  readonly property string legacyConfigPath: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy-session-menu/config.jsonc"

  function open(payloadJson) {
    root.opened = true
    root.confirmingIndex = -1
    root.confirmSeconds = 3
    root.focusedIndex = -1
    if (root.showUptime) {
      uptimeFile.reload()
    }
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    root.confirmingIndex = -1
    confirmTimer.stop()
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function") {
      root.shell.hide(root.manifest ? root.manifest.id : "owaiss.session-menu")
    }
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open("{}")
  }

  function updateUptime() {
    var raw = ""
    try {
      if (typeof uptimeFile.text === "function") raw = uptimeFile.text()
      else if (uptimeFile.text) raw = String(uptimeFile.text)
    } catch (e) { raw = "" }

    if (!raw) return
    var parts = raw.trim().split(" ")
    if (parts.length > 0) {
      root.uptimeString = Model.formatUptime(parts[0])
    }
  }

  function applyConfig(cfg) {
    if (!cfg) return
    if (cfg.options) {
      if (cfg.options.cardSize !== undefined) root.cardSize = cfg.options.cardSize
      if (cfg.options.confirmDestructive !== undefined) root.confirmDestructive = cfg.options.confirmDestructive
      if (cfg.options.showBadges !== undefined) root.showBadges = cfg.options.showBadges
      if (cfg.options.highlightShutdown !== undefined) root.highlightShutdown = cfg.options.highlightShutdown
      if (cfg.options.showUptime !== undefined) root.showUptime = cfg.options.showUptime
    }
    if (Array.isArray(cfg.actions)) {
      root.actions = cfg.actions
    }
  }

  function loadConfig(rawText) {
    var cfg = Model.parseConfig(rawText)
    root.applyConfig(cfg)
  }

  function loadDefaultConfig() {
    var cfg = Model.parseConfig("")
    root.applyConfig(cfg)
  }

  function triggerAction(index) {
    if (index < 0 || index >= root.actions.length) return
    var action = root.actions[index]
    root.focusedIndex = index

    if (root.confirmDestructive && action.destructive) {
      if (root.confirmingIndex === index) {
        root.executeAction(action)
      } else {
        root.confirmingIndex = index
        root.confirmSeconds = 3
        confirmTimer.restart()
      }
    } else {
      root.executeAction(action)
    }
  }

  function executeAction(action) {
    root.close()
    if (action && action.command) {
      Util.execDetached(action.command)
    }
  }

  Timer {
    id: confirmTimer
    interval: 1000
    repeat: true
    onTriggered: {
      root.confirmSeconds--
      if (root.confirmSeconds <= 0) {
        root.confirmingIndex = -1
        confirmTimer.stop()
      }
    }
  }

  // Watch uptime from Linux /proc
  FileView {
    id: uptimeFile
    path: "/proc/uptime"
    watchChanges: false
    onLoaded: root.updateUptime()
  }

  // Watch primary user config file
  FileView {
    id: userConfigFile
    path: root.userConfigPath
    watchChanges: true
    printErrors: false
    onLoaded: root.loadConfig(text())
    onLoadFailed: legacyConfigFile.reload()
    onFileChanged: reload()
  }

  // Fallback to legacy config file location if primary not found
  FileView {
    id: legacyConfigFile
    path: root.legacyConfigPath
    watchChanges: true
    printErrors: false
    onLoaded: root.loadConfig(text())
    onLoadFailed: root.loadDefaultConfig()
    onFileChanged: reload()
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    // Set namespace to omarchy-menu so Hyprland applies consistent compositor layer rules
    WlrLayershell.namespace: "omarchy-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    // Theme-driven Backdrop Scrim
    Rectangle {
      anchors.fill: parent
      color: Color.menu.scrim
      opacity: root.opened ? 1.0 : 0.0
      Behavior on opacity { NumberAnimation { duration: 150 } }

      MouseArea {
        anchors.fill: parent
        onClicked: root.close()
      }
    }

    // Key Handler
    Item {
      id: keyCatcher
      anchors.fill: parent
      focus: true

      Keys.priority: Keys.BeforeItem
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          if (root.confirmingIndex >= 0) {
            root.confirmingIndex = -1
            confirmTimer.stop()
          } else {
            root.close()
          }
          event.accepted = true
          return
        }

        if (event.key === Qt.Key_Left) {
          if (root.focusedIndex <= 0) root.focusedIndex = root.actions.length - 1
          else root.focusedIndex--
          event.accepted = true
          return
        }

        if (event.key === Qt.Key_Right) {
          if (root.focusedIndex >= root.actions.length - 1) root.focusedIndex = 0
          else root.focusedIndex++
          event.accepted = true
          return
        }

        if (event.key === Qt.Key_Tab) {
          if (event.modifiers & Qt.ShiftModifier) {
            if (root.focusedIndex <= 0) root.focusedIndex = root.actions.length - 1
            else root.focusedIndex--
          } else {
            if (root.focusedIndex >= root.actions.length - 1) root.focusedIndex = 0
            else root.focusedIndex++
          }
          event.accepted = true
          return
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
          if (root.confirmingIndex >= 0) {
            root.triggerAction(root.confirmingIndex)
          } else if (root.focusedIndex >= 0 && root.focusedIndex < root.actions.length) {
            root.triggerAction(root.focusedIndex)
          }
          event.accepted = true
          return
        }

        var t = event.text
        if (t && t.length > 0) {
          for (var i = 0; i < root.actions.length; i++) {
            var k = root.actions[i].key !== undefined ? String(root.actions[i].key) : ""
            if (k && k.toLowerCase() === t.toLowerCase()) {
              root.triggerAction(i)
              event.accepted = true
              return
            }
          }
        }
      }

      // Center Floating Capsule Popout Container
      Rectangle {
        id: capsule
        anchors.centerIn: parent
        width: contentColumn.width + 24
        height: contentColumn.height + 20
        radius: Style.cornerRadius + 6
        color: Color.menu.background
        border.color: Util.alpha(Color.menu.border, 0.65)
        border.width: 1

        scale: root.opened ? 1.0 : 0.94
        opacity: root.opened ? 1.0 : 0.0
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        MouseArea {
          anchors.fill: parent
          onClicked: {} // Prevent backdrop dismissal when clicking inside capsule
        }

        Column {
          id: contentColumn
          anchors.centerIn: parent
          spacing: 10

          // Optional Uptime & User Info Chip
          Row {
            visible: root.showUptime && root.uptimeString !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6

            Text {
              text: "\uf108" // 󰌢
              font.family: Style.font.family
              font.pixelSize: 11
              color: Util.alpha(Color.foreground, 0.55)
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              text: Quickshell.env("USER") + "  \u2022  up " + root.uptimeString
              font.family: Style.font.menuFamily
              font.pixelSize: 11
              font.weight: Font.Medium
              color: Util.alpha(Color.foreground, 0.55)
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          // Horizontal Row of Action Cards
          Row {
            id: actionRow
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Repeater {
              model: root.actions

              delegate: Item {
                id: cardItem
                required property var modelData
                required property int index

                readonly property bool isFocused: root.focusedIndex === index
                readonly property bool isConfirming: root.confirmingIndex === index
                readonly property bool isHighlighted: root.highlightShutdown && modelData.highlight === true

                readonly property color highlightBg: {
                  if (modelData.highlightColor && String(modelData.highlightColor).length > 0) {
                    return Qt.color(modelData.highlightColor)
                  }
                  return Color.urgent
                }

                readonly property real highlightLum: (highlightBg.r * 0.299 + highlightBg.g * 0.587 + highlightBg.b * 0.114)
                readonly property color highlightFg: {
                  if (modelData.highlightTextColor && String(modelData.highlightTextColor).length > 0) {
                    return Qt.color(modelData.highlightTextColor)
                  }
                  return highlightLum > 0.55 ? "#161616" : "#ffffff"
                }

                width: root.cardSize
                height: root.cardSize

                scale: isFocused ? 1.04 : 1.0
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

                // Card Background
                Rectangle {
                  id: cardBg
                  anchors.fill: parent
                  radius: Math.max(6, Style.cornerRadius)
                  clip: true

                  color: {
                    if (cardItem.isConfirming) return Color.urgent
                    if (cardItem.isHighlighted) return cardItem.highlightBg
                    if (cardItem.isFocused) return Util.alpha(Color.foreground, 0.12)
                    return Util.alpha(Color.foreground, 0.05)
                  }

                  border.color: {
                    if (cardItem.isConfirming) return Color.urgent
                    if (cardItem.isHighlighted) return cardItem.highlightBg
                    if (cardItem.isFocused) return Util.alpha(Color.accent, 0.8)
                    return Util.alpha(Color.foreground, 0.08)
                  }
                  border.width: cardItem.isFocused ? 1.5 : 1

                  Behavior on color { ColorAnimation { duration: 120 } }
                  Behavior on border.color { ColorAnimation { duration: 120 } }

                  // Number Hotkey Badge (Top-Right)
                  Rectangle {
                    id: badge
                    visible: root.showBadges && modelData.key !== undefined && String(modelData.key) !== ""
                    anchors {
                      top: parent.top
                      right: parent.right
                      margins: 6
                    }
                    width: Math.max(16, badgeText.implicitWidth + 8)
                    height: 16
                    radius: 4

                    color: {
                      if (cardItem.isHighlighted && !cardItem.isConfirming) {
                        return cardItem.highlightLum > 0.55 ? Util.alpha("#000000", 0.18) : Util.alpha("#ffffff", 0.22)
                      }
                      return Util.alpha(Color.background, 0.7)
                    }

                    Text {
                      id: badgeText
                      anchors.centerIn: parent
                      text: cardItem.isConfirming ? "\u21b5" : (modelData.key !== undefined ? String(modelData.key) : "")
                      font.family: Style.font.family
                      font.pixelSize: 10
                      font.weight: Font.Bold
                      color: {
                        if (cardItem.isHighlighted && !cardItem.isConfirming) return cardItem.highlightFg
                        return Color.foreground
                      }
                    }
                  }

                  // Card Icon & Label
                  Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                      id: iconText
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: modelData.icon || "\uf011"
                      font.family: Style.font.family
                      font.pixelSize: 26
                      color: {
                        if (cardItem.isConfirming) return "#ffffff"
                        if (cardItem.isHighlighted) return cardItem.highlightFg
                        return Color.menu.text
                      }
                    }

                    Text {
                      id: labelText
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: cardItem.isConfirming ? ("Confirm (" + root.confirmSeconds + "s)") : (modelData.label || "")
                      font.family: Style.font.menuFamily
                      font.pixelSize: 11
                      font.weight: Font.Medium
                      color: {
                        if (cardItem.isConfirming) return "#ffffff"
                        if (cardItem.isHighlighted) return cardItem.highlightFg
                        return Color.menu.text
                      }
                    }
                  }

                  // Confirmation Progress Bar at the bottom of the card
                  Rectangle {
                    visible: cardItem.isConfirming
                    anchors {
                      left: parent.left
                      bottom: parent.bottom
                    }
                    height: 3
                    width: parent.width * (root.confirmSeconds / 3.0)
                    color: Util.alpha("#ffffff", 0.8)
                    Behavior on width {
                      enabled: cardItem.isConfirming && root.confirmSeconds < 3
                      NumberAnimation { duration: 950; easing.type: Easing.Linear }
                    }
                  }

                  MouseArea {
                    id: cardMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.triggerAction(cardItem.index)
                    onEntered: root.focusedIndex = cardItem.index
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
