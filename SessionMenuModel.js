// SessionMenuModel.js - Core logic, predefined actions, and config parsing for owaiss.session-menu

function stripJsonc(raw) {
  var str = String(raw || "")
  var out = ""
  var inString = false
  var inLineComment = false
  var inBlockComment = false
  var escape = false

  for (var i = 0; i < str.length; i++) {
    var c = str[i]
    var next = i + 1 < str.length ? str[i + 1] : ""

    if (inLineComment) {
      if (c === "\n" || c === "\r") {
        inLineComment = false
        out += c
      }
      continue
    }

    if (inBlockComment) {
      if (c === "*" && next === "/") {
        inBlockComment = false
        i++
      }
      continue
    }

    if (inString) {
      out += c
      if (escape) {
        escape = false
      } else if (c === "\\") {
        escape = true
      } else if (c === '"') {
        inString = false
      }
      continue
    }

    if (c === '"') {
      inString = true
      out += c
      continue
    }

    if (c === "/" && next === "/") {
      inLineComment = true
      i++
      continue
    }

    if (c === "/" && next === "*") {
      inBlockComment = true
      i++
      continue
    }

    out += c
  }

  // Strip trailing commas before closing braces or brackets
  return out.replace(/,(\s*[}\]])/g, "$1")
}

function defaultActions() {
  return [
    {
      id: "lock",
      label: "Lock",
      icon: "\uf023", // 
      command: "omarchy system lock",
      destructive: false,
      highlight: false,
      enabled: true
    },
    {
      id: "suspend",
      label: "Suspend",
      icon: "\udb81\udcb2", // 󰒲
      command: "systemctl suspend",
      destructive: false,
      highlight: false,
      enabled: true
    },
    {
      id: "logout",
      label: "Logout",
      icon: "\udb80\udf43", // 󰍃
      command: "omarchy system logout",
      destructive: true,
      highlight: false,
      enabled: true
    },
    {
      id: "reboot",
      label: "Reboot",
      icon: "\udb81\udf09", // 󰜉
      command: "omarchy system reboot",
      destructive: true,
      highlight: false,
      enabled: true
    },
    {
      id: "shutdown",
      label: "Shutdown",
      icon: "\uf011", // 
      command: "omarchy system shutdown",
      destructive: true,
      highlight: true,
      enabled: true
    },
    {
      id: "hibernate",
      label: "Hibernate",
      icon: "\udb81\udf01", // 󰤁
      command: "systemctl hibernate",
      destructive: true,
      highlight: false,
      enabled: false
    },
    {
      id: "uefi",
      label: "UEFI",
      icon: "\udb80\udf5c", // 󰍜
      command: "systemctl reboot --firmware-setup",
      destructive: true,
      highlight: false,
      enabled: false
    },
    {
      id: "screensaver",
      label: "Screensaver",
      icon: "\udb81\udf04", // 󱄄
      command: "omarchy-launch-screensaver force",
      destructive: false,
      highlight: false,
      enabled: false
    },
    {
      id: "reload",
      label: "Reload",
      icon: "\uf021", // 
      command: "hyprctl reload && omarchy restart shell",
      destructive: false,
      highlight: false,
      enabled: false
    }
  ]
}

function normalizeAction(raw, autoKey) {
  var item = raw || {}
  var keyVal = (item.key !== undefined && String(item.key).trim() !== "")
    ? String(item.key)
    : String(autoKey)

  return {
    id: item.id || ("action-" + autoKey),
    label: item.label || "Action",
    icon: item.icon || "\uf011",
    key: keyVal,
    command: item.command || "",
    destructive: item.destructive !== undefined ? item.destructive : false,
    highlight: item.highlight !== undefined ? item.highlight : false,
    highlightColor: item.highlightColor || "",
    highlightTextColor: item.highlightTextColor || "",
    enabled: item.enabled !== false
  }
}

function filterAndAssignKeys(list) {
  var out = []
  var activeCount = 0
  for (var i = 0; i < list.length; i++) {
    if (list[i].enabled !== false) {
      activeCount++
      out.push(normalizeAction(list[i], activeCount))
    }
  }
  return out
}

function parseConfig(rawJsonc) {
  var stripped = stripJsonc(rawJsonc).trim()
  var defaults = defaultActions()
  var defaultOptions = {
    showPowerButton: true,
    showUptime: true,
    confirmDestructive: true,
    confirmDuration: 3,
    showBadges: true,
    highlightShutdown: true,
    cardSize: 96
  }

  if (!stripped) {
    return {
      options: defaultOptions,
      actions: filterAndAssignKeys(defaults)
    }
  }

  var parsed
  try {
    parsed = JSON.parse(stripped)
  } catch (e) {
    return {
      options: defaultOptions,
      actions: filterAndAssignKeys(defaults)
    }
  }

  var durationVal = 3
  if (parsed.confirmDuration !== undefined) {
    durationVal = Math.max(1, Math.min(30, Number(parsed.confirmDuration) || 3))
  } else if (parsed.confirmSeconds !== undefined) {
    durationVal = Math.max(1, Math.min(30, Number(parsed.confirmSeconds) || 3))
  }

  var showBtn = true
  if (parsed.showPowerButton !== undefined) {
    showBtn = Boolean(parsed.showPowerButton)
  } else if (parsed.showBarWidget !== undefined) {
    showBtn = Boolean(parsed.showBarWidget)
  }

  var options = {
    showPowerButton: showBtn,
    showUptime: parsed.showUptime !== undefined ? parsed.showUptime : true,
    confirmDestructive: parsed.confirmDestructive !== undefined ? parsed.confirmDestructive : true,
    confirmDuration: durationVal,
    showBadges: parsed.showBadges !== undefined ? parsed.showBadges : true,
    highlightShutdown: parsed.highlightShutdown !== undefined ? parsed.highlightShutdown : true,
    cardSize: parsed.cardSize || 96
  }

  var list = Array.isArray(parsed) ? parsed : (Array.isArray(parsed.actions) ? parsed.actions : null)
  if (!list || list.length === 0) {
    return { options: options, actions: filterAndAssignKeys(defaults) }
  }

  var filtered = []
  var activeCount = 0
  for (var i = 0; i < list.length; i++) {
    var rawItem = list[i]
    if (rawItem && typeof rawItem === "object" && rawItem.enabled !== false) {
      activeCount++
      filtered.push(normalizeAction(rawItem, activeCount))
    }
  }

  return {
    options: options,
    actions: filtered.length > 0 ? filtered : filterAndAssignKeys(defaults)
  }
}

function formatUptime(rawSeconds) {
  var totalSec = Math.floor(Number(rawSeconds) || 0)
  if (totalSec <= 0) return ""
  var hours = Math.floor(totalSec / 3600)
  var mins = Math.floor((totalSec % 3600) / 60)
  var days = Math.floor(hours / 24)
  hours = hours % 24
  if (days > 0) {
    return hours > 0 ? (days + "d " + hours + "h") : (days + "d")
  }
  if (hours > 0) {
    return mins > 0 ? (hours + "h " + mins + "m") : (hours + "h")
  }
  if (mins > 0) return mins + "m"
  return "< 1m"
}

function sampleConfigJsonc() {
  return [
    '// Session Menu Configuration',
    '// Located at: ~/.config/omarchy/session-menu.jsonc',
    '// Changes to this file take effect instantly without restarting the shell.',
    '{',
    '  // Optional display preferences',
    '  "showPowerButton": true,       // Show or hide the top bar power launcher icon',
    '  "showUptime": true,',
    '  "confirmDestructive": true,',
    '  "confirmDuration": 3,  // Countdown duration in seconds (e.g. 2, 3, 5)',
    '  "showBadges": true,',
    '  "highlightShutdown": true,',
    '  "cardSize": 96,',
    '',
    '  // Actions list: toggle "enabled" to true/false to show or hide any action.',
    '  "actions": [',
    '    {',
    '      "id": "lock",',
    '      "label": "Lock",',
    '      "icon": "",',
    '      "command": "omarchy system lock",',
    '      "destructive": false,',
    '      "enabled": true',
    '    },',
    '    {',
    '      "id": "suspend",',
    '      "label": "Suspend",',
    '      "icon": "󰒲",',
    '      "command": "systemctl suspend",',
    '      "destructive": false,',
    '      "enabled": true',
    '    },',
    '    {',
    '      "id": "logout",',
    '      "label": "Logout",',
    '      "icon": "󰍃",',
    '      "command": "omarchy system logout",',
    '      "destructive": true,',
    '      "enabled": true',
    '    },',
    '    {',
    '      "id": "reboot",',
    '      "label": "Reboot",',
    '      "icon": "󰜉",',
    '      "command": "omarchy system reboot",',
    '      "destructive": true,',
    '      "enabled": true',
    '    },',
    '    {',
    '      "id": "shutdown",',
    '      "label": "Shutdown",',
    '      "icon": "",',
    '      "command": "omarchy system shutdown",',
    '      "destructive": true,',
    '      "highlight": true,',
    '      "enabled": true',
    '    },',
    '    {',
    '      "id": "hibernate",',
    '      "label": "Hibernate",',
    '      "icon": "󰤁",',
    '      "command": "systemctl hibernate",',
    '      "destructive": true,',
    '      "enabled": false',
    '    },',
    '    {',
    '      "id": "uefi",',
    '      "label": "UEFI",',
    '      "icon": "󰍜",',
    '      "command": "systemctl reboot --firmware-setup",',
    '      "destructive": true,',
    '      "enabled": false',
    '    },',
    '    {',
    '      "id": "screensaver",',
    '      "label": "Screensaver",',
    '      "icon": "󱄄",',
    '      "command": "omarchy-launch-screensaver force",',
    '      "destructive": false,',
    '      "enabled": false',
    '    },',
    '    {',
    '      "id": "reload",',
    '      "label": "Reload",',
    '      "icon": "",',
    '      "command": "hyprctl reload && omarchy restart shell",',
    '      "destructive": false,',
    '      "enabled": false',
    '    }',
    '  ]',
    '}'
  ].join("\n") + "\n"
}

if (typeof module !== "undefined") {
  module.exports = {
    stripJsonc: stripJsonc,
    defaultActions: defaultActions,
    parseConfig: parseConfig,
    formatUptime: formatUptime,
    sampleConfigJsonc: sampleConfigJsonc
  }
}
