# Session Menu for Omarchy

An elegant, theme-aware popout session and power menu plugin for [Omarchy](https://omarchy.org), inspired by the Noctilia Shell v5 aesthetic.

---

## ✨ Features

- **Floating Capsule Layout**: Centered floating pill dialog with theme-adaptive styling and backdrop scrim.
- **Theme-Adaptive Accents**: Automatically inherits active Omarchy theme colors (`Color.urgent` for Shutdown highlight, theme font, border radius, and surface tokens).
- **Omarchy Native Actions**:
  - `1`: **Lock** (`omarchy system lock`)
  - `2`: **Suspend** (`systemctl suspend`)
  - `3`: **Logout** (`omarchy system logout`)
  - `4`: **Reboot** (`omarchy system reboot`)
  - `5`: **Shutdown** (`omarchy system shutdown` — highlighted rightmost card)
- **Top Bar Launcher**: Adds an interactive power icon (``) to the status bar with native click-and-hold drag reordering.
- **Keyboard Navigation**:
  - Direct numeric shortcuts (`1`, `2`, `3`, `4`, `5`) to trigger actions instantly.
  - `←` / `→` or `Tab` / `Shift+Tab` to navigate focus.
  - `Enter` / `Space` to execute focused action.
  - `Esc` or click outside to dismiss.
- **Safe Confirmations**: Optional inline confirmation step for destructive actions (Logout, Reboot, Shutdown).
- **Auto-Fallback Keybinding**: Cleanly opens this menu when enabled, and falls back to Omarchy's default system menu when disabled.
- **Hot-Reloadable Config**: Fully customizable via `~/.config/omarchy/session-menu.jsonc`.

---

## 📦 Installation

### Via Omarchy CLI (Recommended)

```bash
omarchy plugin add https://github.com/Owaisshaikh11/omarchy-session-menu.git --enable
```

### Local Development / Manual Symlink

```bash
git clone https://github.com/Owaisshaikh11/omarchy-session-menu.git ~/omarchy-session-menu
ln -s ~/omarchy-session-menu ~/.config/omarchy/plugins/owaiss.session-menu
omarchy-shell shell rescanPlugins
omarchy plugin enable owaiss.session-menu --section right
```

---

## ⌨️ Hyprland Keybinding

Add the following to `~/.config/hypr/bindings.lua` to replace `Super + Escape` with automatic fallback:

```lua
-- Rebind SUPER + ESCAPE to Session Menu with automatic fallback
hl.unbind("SUPER + ESCAPE")
o.bind("SUPER + ESCAPE", "Session Menu", "bash -c 'grep -q \"owaiss.session-menu\" ~/.config/omarchy/shell.json 2>/dev/null && exec omarchy-shell shell toggle owaiss.session-menu || exec omarchy-menu toggle system'")
```

Reload Hyprland:

```bash
hyprctl reload
```

---

## ⚙️ Customization (`session-menu.jsonc`)

The plugin works out of the box with zero configuration. To add, remove, reorder, or customize actions, create `~/.config/omarchy/session-menu.jsonc`:

```jsonc
[
  {
    "id": "lock",
    "label": "Lock",
    "icon": "",
    "key": "1",
    "command": "omarchy system lock",
    "destructive": false,
    "highlight": false
  },
  {
    "id": "suspend",
    "label": "Suspend",
    "icon": "󰒲",
    "key": "2",
    "command": "systemctl suspend",
    "destructive": false,
    "highlight": false
  },
  {
    "id": "logout",
    "label": "Logout",
    "icon": "󰍃",
    "key": "3",
    "command": "omarchy system logout",
    "destructive": true,
    "highlight": false
  },
  {
    "id": "reboot",
    "label": "Reboot",
    "icon": "󰜉",
    "key": "4",
    "command": "omarchy system reboot",
    "destructive": true,
    "highlight": false
  },
  {
    "id": "shutdown",
    "label": "Shutdown",
    "icon": "",
    "key": "5",
    "command": "omarchy system shutdown",
    "destructive": true,
    "highlight": true,
    // Optional custom color overrides:
    // "highlightColor": "#ea6962",
    // "highlightTextColor": "#161616"
  }
]
```

Changes saved to `session-menu.jsonc` take effect immediately without restarting the shell.

---

## 🛠️ Bar Settings

Configurable via **Omarchy menu → Setup → Bar**:

| Setting | Type | Default | Description |
|---|---|---|---|
| `cardSize` | integer | `96` | Width and height of each action card in logical pixels. |
| `confirmDestructive` | boolean | `true` | Require pressing again or clicking to confirm destructive actions. |
| `showBadges` | boolean | `true` | Show hotkey number badges (1, 2, 3...) on cards. |
| `highlightShutdown` | boolean | `true` | Highlight the Shutdown card with theme accent styling. |

---

## 📄 License

MIT License. See [LICENSE](LICENSE).
