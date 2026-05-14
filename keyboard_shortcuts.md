# Polybar & System Shortcuts Guide

This document is your reference for interacting with the Polybar UI and using system-wide keyboard hotkeys.

---

## 🖱️ Mouse Interactions (Polybar)
These actions are performed directly on the Polybar modules.

### 🌓 Dashboard Controls (Exclusive Toggle)
All main modules (System, Media, Connection, Battery) support the **Exclusive Detail View**.
*   **Middle Click:** Expand a module to see details (e.g., CPU %, SSID name, etc.) and collapse all others.
*   **Middle Click (Again):** Collapse the module back to icons.

### 🔊 Audio & Media
*   **Scroll Up/Down:** Increase/Decrease Volume (5% steps).
*   **Left Click (Volume Icon):** Toggle Speaker Mute/Unmute.
*   **Left Click (Mic Icon):** Toggle Microphone Mute/Unmute.
*   **Right Click:** Open full Audio Mixer (`pavucontrol`).

### 🌐 Connectivity
*   **Left Click (Hotspot Icon):** Disconnect Hotspot.
*   **Left Click (Bluetooth Icon):** Toggle Bluetooth Power (On/Off).
*   **Middle Click:** Show WiFi SSID, Ethernet status, and Bluetooth device names.
*   **Right Click (Hotspot Icon):** Open Hotspot Manager (View password & Create).

### 🔋 Power & Battery
*   **Left Click:** Open the logout/shutdown menu.
*   **Middle Click:** Show battery percentage and time remaining.

### 🎨 Themes
*   **Left Click:** Open the Theme Selector (Rofi menu).
*   **Middle Click:** Show the name of the active theme.

### 🚀 Navigation
*   **Left Click (Logo):** Open Application Menu (Jgmenu).
*   **Left Click (Window Title):** Show list of all open windows.
*   **Left Click (+ Icon):** Create a new workspace.

---

## ⌨️ Keyboard Shortcuts (Hotkeys)
These shortcuts use the **Super** (Windows) key for fast system navigation.

### 🛠️ System Tools
| Shortcut | Action |
| :--- | :--- |
| **Super + Return** | Open Terminal |
| **Super + Shift + B** | Open Web Browser |
| **Super + E** | Open File Manager (Thunar) |
| **Super + Escape** | Open App Menu (Jgmenu) |
| **Super + Tab** | Switch between open windows |
| **Super + Space** | Toggle Keyboard Layout (US/Other) |
| **PrintScreen** | Open Screenshot Dialog (Select Region/Window/Full) |
| **Alt + PrintScreen** | Take Window Screenshot |
| **Shift + PrintScreen** | Take Region Screenshot |

### 🖥️ Workspace Management
| Shortcut | Action |
| :--- | :--- |
| **Super + [1-0]** | Switch to Workspace 1 through 10 |
| **Super + Left/Right** | Switch to Previous/Next workspace |
| **Super + Equal (=)** | Create a new workspace |
| **Super + Minus (-)** | Delete current workspace |

### 🔧 Polybar Controls
| Shortcut | Action |
| :--- | :--- |
| **Super + Ctrl + Space** | **Open Theme Selector** |
| **Super + Ctrl + ← / →** | **Cycle Themes** (Prev/Next with OSD) |
| **Super + grave ( ` )** | **Reload Polybar** (Apply config changes) |
| **Super + H** | Toggle Polybar Size (Max / Mini) |
| **Super + Shift + H** | Hide Polybar completely (Toggle visibility) |
| **Super + K** | Kill Polybar |
| **Super + Shift + Q** | Force close Polybar |
| **Super + Alt + ↑/↓** | Move Mini Bar to Top/Bottom |
| **Super + Alt + ←/→** | Move Mini Bar to Left/Right |

### 📊 Dashboard Hotkeys (Toggle Info)
| Shortcut | Action |
| :--- | :--- |
| **Super + Ctrl + 1** | Toggle **System Monitoring** Details |
| **Super + Ctrl + 2** | Toggle **Media** Details |
| **Super + Ctrl + 3** | Toggle **Battery** Details |
| **Super + Ctrl + 4** | Toggle **Connection** Details |
| **Super + Ctrl + 5** | Toggle **Themes** Details |
