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

  // User customizable settings (defaults from manifest)
  property int cardSize: 96
  property bool confirmDestructive: true
  property bool showBadges: true
  property bool highlightShutdown: true

  // Config file path for user customization
  property string userConfigPath: Quickshell.env("HOME") + "/.config/omarchy/session-menu.jsonc"

  function open(payloadJson) {
    root.opened = true
    root.confirmingIndex = -1
    root.focusedIndex = -1
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    root.confirmingIndex = -1
    root.opened = false
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open("{}")
  }

  function loadConfig(rawText) {
    root.actions = Model.parseActions(rawText)
  }

  function loadDefaultConfig() {
    root.actions = Model.defaultActions()
  }

  function triggerAction(index) {
    if (index < 0 || index >= root.actions.length) return
    var action = root.actions[index]

    if (root.confirmDestructive && action.destructive) {
      if (root.confirmingIndex === index) {
        root.executeAction(action)
      } else {
        root.confirmingIndex = index
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
    interval: 3000
    repeat: false
    onTriggered: root.confirmingIndex = -1
  }

  FileView {
    id: userConfigFile
    path: root.userConfigPath
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
    WlrLayershell.namespace: "omarchy-session-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    // Backdrop Scrim
    Rectangle {
      anchors.fill: parent
      color: Util.alpha(Color.background, 0.55)
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
          root.close()
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
          if (root.focusedIndex >= 0 && root.focusedIndex < root.actions.length) {
            root.triggerAction(root.focusedIndex)
          }
          event.accepted = true
          return
        }

        var t = event.text
        if (t && t.length > 0) {
          for (var i = 0; i < root.actions.length; i++) {
            if (String(root.actions[i].key).toLowerCase() === t.toLowerCase()) {
              root.triggerAction(i)
              event.accepted = true
              return
            }
          }
        }
      }

      // Center Capsule Popout Container
      Rectangle {
        id: capsule
        anchors.centerIn: parent
        width: contentRow.width + 20
        height: root.cardSize + 20
        radius: Style.cornerRadius + 6
        color: Color.menu.background
        border.color: Util.alpha(Color.menu.border, 0.6)
        border.width: 1

        scale: root.opened ? 1.0 : 0.94
        opacity: root.opened ? 1.0 : 0.0
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        MouseArea {
          anchors.fill: parent
          onClicked: {} // Catch clicks so backdrop doesn't close on capsule click
        }

        Row {
          id: contentRow
          anchors.centerIn: parent
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
              readonly property bool isHovered: cardMouseArea.containsMouse

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

              scale: (isHovered || isFocused) ? 1.04 : 1.0
              Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

              // Card Background
              Rectangle {
                id: cardBg
                anchors.fill: parent
                radius: Math.max(6, Style.cornerRadius)

                color: {
                  if (cardItem.isConfirming) return Color.urgent
                  if (cardItem.isHighlighted) return cardItem.highlightBg
                  if (cardItem.isHovered || cardItem.isFocused) return Util.alpha(Color.foreground, 0.12)
                  return Util.alpha(Color.foreground, 0.05)
                }

                border.color: {
                  if (cardItem.isConfirming) return Color.urgent
                  if (cardItem.isHighlighted) return cardItem.highlightBg
                  if (cardItem.isHovered || cardItem.isFocused) return Util.alpha(Color.accent, 0.8)
                  return Util.alpha(Color.foreground, 0.08)
                }
                border.width: (cardItem.isHovered || cardItem.isFocused) ? 1.5 : 1

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                // Number Hotkey Badge (Top-Right)
                Rectangle {
                  id: badge
                  visible: root.showBadges && modelData.key !== ""
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
                    text: cardItem.isConfirming ? "\u21b5" : modelData.key
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
                    text: modelData.icon
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
                    text: cardItem.isConfirming ? "Confirm?" : modelData.label
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
