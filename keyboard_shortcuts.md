# Polybar Interaction & Shortcuts Guide

This document lists all the interactive elements and mouse shortcuts built into the custom Polybar configuration.

## 🖱️ Global Module Interactions
All primary modules (System, Media, Connection, Battery) follow the **Exclusive Detail View** logic.

| Action | Result |
| :--- | :--- |
| **Middle Click** | Expand the clicked module and collapse all other modules. |
| **Middle Click (Again)** | Collapse the module back to icon-only mode. |

---

## 📊 Module-Specific Shortcuts

### 1. System Monitoring (CPU, Temp, RAM, Disk)
| Action | Result |
| :--- | :--- |
| **Middle Click** | Toggle between icons and full dashboard (%, °C). |

### 2. Media & Audio
| Action | Result |
| :--- | :--- |
| **Middle Click** | Toggle between icons and detailed info (Volume %, Mic Status). |
| **Left Click (Vol Icon)** | Toggle Speaker Mute/Unmute. |
| **Left Click (Mic Icon)** | Toggle Microphone Mute/Unmute. |
| **Scroll Up/Down** | Increase/Decrease Volume (5% steps). |
| **Right Click** | Open PulseAudio Volume Control (`pavucontrol`). |

### 3. Connection & Network (WiFi, Eth, Hotspot, BT)
| Action | Result |
| :--- | :--- |
| **Middle Click** | Toggle between icons and connection details (SSID, BT Device Name). |

### 4. Battery
| Action | Result |
| :--- | :--- |
| **Middle Click** | Toggle between icon and percentage/time remaining. |
| **Left Click** | Open the Power Management/Log-out Dashboard. |

---

## 🚀 Navigation & Workspaces

### Workspaces
| Action | Result |
| :--- | :--- |
| **Left Click** | Switch to that workspace. |
| **Middle Click** | Move the current window to that workspace. |

### App Launcher & Windows
| Action | Result |
| :--- | :--- |
| **Left Click (Menu Icon)** | Launch Jgmenu (Application Launcher). |
| **Left Click (Window Title)** | Show full list of open windows. |
| **Left Click (+ Icon)** | Create a new workspace. |

### Power & Session
| Action | Result |
| :--- | :--- |
| **Left Click (Power Icon)** | Open XFCE Session Logout menu. |

---

## ⌨️ Keyboard Layout
| Action | Result |
| :--- | :--- |
| **Right Click** | Open Keyboard Settings. |
| **Super + Space** | (System Shortcut) Toggle between Keyboard layouts. |
