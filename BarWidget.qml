import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "owaiss.session-menu"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

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
      root.bar.run("omarchy-shell shell toggle owaiss.session-menu")
    }
  }
}
