import Quickshell
import Quickshell.Io
import QtQuick
import qs.Commons
import qs.Ui
import "SessionMenuModel.js" as Model

BarWidget {
  id: root
  moduleName: "owaiss.session-menu"

  property bool showWidget: true

  visible: showWidget
  implicitWidth: showWidget ? button.implicitWidth : 0
  implicitHeight: showWidget ? button.implicitHeight : 0

  readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy"
  readonly property string userConfigPath: configDir + "/session-menu.jsonc"

  FileView {
    id: configFile
    path: root.userConfigPath
    watchChanges: true
    printErrors: false
    onLoaded: root.updateConfig(text())
    onFileChanged: reload()
  }

  function updateConfig(raw) {
    var cfg = Model.parseConfig(raw)
    if (cfg && cfg.options) {
      if (cfg.options.showPowerButton !== undefined) {
        root.showWidget = Boolean(cfg.options.showPowerButton)
      } else if (cfg.options.showBarWidget !== undefined) {
        root.showWidget = Boolean(cfg.options.showBarWidget)
      } else {
        root.showWidget = true
      }
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\uf011" // Power glyph 
    fontFamily: Style.font.family
    horizontalMargin: 7.5
    tooltipText: "Session Menu"
    onPressed: function(btn) {
      if (!root.bar) return
      if (btn === Qt.LeftButton || btn === undefined) {
        root.bar.run("omarchy-shell shell toggle owaiss.session-menu")
      }
    }
  }
}
