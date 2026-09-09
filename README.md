# Session Menu for Omarchy

An elegant, theme-aware popout session and power menu plugin for [Omarchy](https://omarchy.org), inspired by the Noctilia Shell v5 aesthetic.

It features a centered floating capsule with individual action cards, keyboard shortcuts, optional inline confirmations, and a status bar launcher with full drag-and-drop support.

---

## ✨ Features

- **Floating Capsule Design**: Centered floating pill dialog with theme-aware borders and backdrop scrim.
- **Theme-Adaptive**: Dynamically adopts the active Omarchy theme colors, fonts, border radii, and transparency settings.
- **Top Bar Widget**: Adds an interactive power icon (``) to the status bar that can be moved anywhere on the bar via click-and-hold drag gestures.
- **Keyboard Navigation**:
  - Direct numeric shortcuts (`1`, `2`, `3`, `4`, `5`, etc.) to trigger actions instantly.
  - `←` / `→` or `Tab` / `Shift+Tab` to cycle focus.
  - `Enter` / `Space` to execute the focused card.
  - `Esc` or click outside to dismiss.
- **Smart Confirmations**: Optional confirmation step for destructive actions (Reboot, Shut Down, Log Out) to prevent accidental triggers.
- **Visual Distinction**: Prominently highlights the "Shut Down" action with theme danger/accent styling.
- **Deep Customization**: Fully configurable via `~/.config/omarchy/session-menu.jsonc` with live hot-reloading on save.

---

## 📦 Installation

### From GitHub via Omarchy CLI

```bash
omarchy plugin add https://github.com/Owaisshaikh11/omarchy-session-menu.git --enable
```

When prompted, select the bar section (default: `right`).

### Local Development / Manual Symlink

If you clone the repository locally:

```bash
git clone https://github.com/Owaisshaikh11/omarchy-session-menu.git ~/omarchy-session-menu
ln -s ~/omarchy-session-menu ~/.config/omarchy/plugins/owaiss.session-menu
omarchy-shell shell rescanPlugins
omarchy plugin enable owaiss.session-menu
```

---

## ⌨️ Hyprland Keybinding

To open the session menu with **`Super + Escape`** (replacing the default Omarchy system menu):

Add the following to your `~/.config/hypr/bindings.lua`:

```lua
-- Unbind default system menu
hl.unbind("SUPER + ESCAPE")

-- Bind to Session Menu
o.bind("SUPER + ESCAPE", "Session Menu", "omarchy-shell shell toggle owaiss.session-menu")
```

Then reload Hyprland:

```bash
hyprctl reload
```

---

## ⚙️ Customization (`session-menu.jsonc`)

The plugin works out of the box with zero configuration. To customize the actions, order, icons, or commands, create `~/.config/omarchy/session-menu.jsonc`:

```jsonc
[
  {
    "id": "lock-suspend",
    "label": "Lock & Suspend",
    "icon": "󰒲",
    "key": "1",
    "command": "omarchy system lock && systemctl suspend",
    "destructive": false,
    "highlight": false
  },
  {
    "id": "logout",
    "label": "Log Out",
    "icon": "󰍃",
    "key": "2",
    "command": "omarchy system logout",
    "destructive": true,
    "highlight": false
  },
  {
    "id": "reboot",
    "label": "Reboot",
    "icon": "󰜉",
    "key": "3",
    "command": "omarchy system reboot",
    "destructive": true,
    "highlight": false
  },
  {
    "id": "shutdown",
    "label": "Shut Down",
    "icon": "",
    "key": "4",
    "command": "omarchy system shutdown",
    "destructive": true,
    "highlight": true
  },
  {
    "id": "uefi",
    "label": "UEFI",
    "icon": ">_",
    "key": "5",
    "command": "systemctl reboot --firmware-setup",
    "destructive": true,
    "highlight": false
  }
]
```

Changes saved to `session-menu.jsonc` take effect immediately without restarting the shell!

---

## 🛠️ Bar Settings

The plugin exposes schema settings configurable via **Omarchy menu → Setup → Bar**:

| Setting | Type | Default | Description |
|---|---|---|---|
| `cardSize` | integer | `96` | Size of each action card in logical pixels (72–128). |
| `confirmDestructive` | boolean | `true` | Require a second press/click to confirm destructive actions. |
| `showBadges` | boolean | `true` | Show hotkey numbers (1, 2, 3...) in the top-right corner. |
| `highlightShutdown` | boolean | `true` | Highlight the Shutdown card with theme accent styling. |

---

## 📄 License

MIT License. See [LICENSE](LICENSE).
