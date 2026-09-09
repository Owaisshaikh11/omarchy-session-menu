// SessionMenuModel.js - Core logic and default actions for owaiss.session-menu

function stripJsonc(raw) {
  return String(raw || "")
    .replace(/^\s*\/\/[^\n]*(\n|$)/gm, "")
    .replace(/,(\s*[}\]])/g, "$1")
}

function defaultActions() {
  return [
    {
      id: "lock-suspend",
      label: "Lock & Suspend",
      icon: "\udb81\udcb2", // 󰒲
      key: "1",
      command: "omarchy system lock && systemctl suspend",
      destructive: false,
      highlight: false
    },
    {
      id: "logout",
      label: "Log Out",
      icon: "\udb80\udf43", // 󰍃
      key: "2",
      command: "omarchy system logout",
      destructive: true,
      highlight: false
    },
    {
      id: "reboot",
      label: "Reboot",
      icon: "\udb81\udf09", // 󰜉
      key: "3",
      command: "omarchy system reboot",
      destructive: true,
      highlight: false
    },
    {
      id: "shutdown",
      label: "Shut Down",
      icon: "\uf011", // 
      key: "4",
      command: "omarchy system shutdown",
      destructive: true,
      highlight: true
    },
    {
      id: "hibernate",
      label: "Hibernate",
      icon: "\udb81\udf01", // 󰤁
      key: "5",
      command: "systemctl hibernate",
      destructive: true,
      highlight: false
    }
  ]
}

function normalizeAction(raw, index) {
  var item = raw || {}
  var keyNum = item.key !== undefined ? String(item.key) : String(index + 1)
  return {
    id: item.id || ("action-" + index),
    label: item.label || "Action",
    icon: item.icon || "\uf011",
    key: keyNum,
    command: item.command || "",
    destructive: item.destructive !== undefined ? item.destructive : false,
    highlight: item.highlight !== undefined ? item.highlight : false
  }
}

function parseActions(rawJsonc) {
  var stripped = stripJsonc(rawJsonc).trim()
  if (!stripped) return defaultActions()

  var parsed
  try {
    parsed = JSON.parse(stripped)
  } catch (e) {
    return defaultActions()
  }

  var list = Array.isArray(parsed) ? parsed : (Array.isArray(parsed.actions) ? parsed.actions : null)
  if (!list || list.length === 0) return defaultActions()

  var out = []
  for (var i = 0; i < list.length; i++) {
    if (list[i] && typeof list[i] === "object") {
      out.push(normalizeAction(list[i], i))
    }
  }
  return out.length > 0 ? out : defaultActions()
}

if (typeof module !== "undefined") {
  module.exports = {
    stripJsonc: stripJsonc,
    defaultActions: defaultActions,
    parseActions: parseActions,
    normalizeAction: normalizeAction
  }
}
