<div align="center">

# 📱 Android System App Remover & Debloater
### *All-in-One • Auto-Detecting • Safe • No Root Required • 100% Reversible*

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE_alt)
[![Root: Not Required](https://img.shields.io/badge/Root-Not_Required-success.svg)](#-how-it-works--safety)
[![Android: 11 - 15](https://img.shields.io/badge/Android-11_%E2%80%94_15-orange.svg)](#-supported-brands--skins)
[![Platform: Linux | macOS | Windows](https://img.shields.io/badge/Platform-Linux_%7C_macOS_%7C_Windows-lightgrey.svg)](#-quick-start)
[![Safety: 100% Reversible](https://img.shields.io/badge/Safety-100%25_Reversible-green.svg)](#-restoring-uninstalled-apps)

<p align="center">
  A modern, unified, single-command runner to automatically detect your connected phone model and safely remove bloatware, tracking services, telemetry, and OEM adware without root access.
</p>

</div>

---

## ⚡ 1-Line Quick Run (No Git Clone Required)

Run the debloater instantly with a single command:

### 🐧 Linux & 🍎 macOS
```bash
curl -fsSL https://raw.githubusercontent.com/intelQong/Android_System_App_Remover/main/remover.sh | bash
```
*(Or using `wget`: `wget -qO- https://raw.githubusercontent.com/intelQong/Android_System_App_Remover/main/remover.sh | bash`)*

---

### 🖥️ Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/intelQong/Android_System_App_Remover/main/remover.bat -OutFile remover.bat; .\remover.bat
```

---

## 📸 Preview

```text
================================================================================
         📱  ANDROID SYSTEM APP REMOVER & DEBLOATER (v2.0)
               Safe • No Root Required • Fully Reversible
================================================================================
┌─[ CONNECTED DEVICE STATUS ]──────────────────────────────────────────────────┐
│ ● ONLINE | SAMSUNG GALAXY S23 ULTRA (Android 14 • ROM: One UI)               │
│ Serial: R5CW10ABCDE | Battery: 89% | Profile: SAMSUNG                        │
└──────────────────────────────────────────────────────────────────────────────┘

[ MAIN MENU ]
  [1] 🚀 Quick Safe Debloat (Auto-Detected: SAMSUNG)
       Instantly uninstall all safe bloatware for current profile with live status.
  [2] 📋 Interactive App Checklist
       Hand-pick and toggle specific apps to keep or remove.
  [3] 🔍 Search & Debloat by Keyword
       Find packages matching a search term (e.g. bixby, ads, facebook).
  [4] 🔄 Interactive App Restore Tool
       Reinstall previously uninstalled system apps on demand.
  [5] 🏷  Change OEM Profile [Current: SAMSUNG]
  [6] ✍  Manual Package Input
  [7] ℹ  Device Diagnostics & Bloatware Scanner
  [R] 🔄 Re-scan Device Connection
  [0] ❌ Exit
```

---

## ✨ Features

- ⚡ **Auto-Install ADB**: Detects if ADB is missing on your PC and offers 1-click automatic installation across Ubuntu/Debian (`apt`), Arch (`pacman`), Fedora (`dnf`), openSUSE (`zypper`), macOS (`brew`), and Windows (`powershell`/platform-tools).
- 📱 **Automatic Model & ROM Detection**: Zero configuration needed. The script automatically reads your connected phone's manufacturer, model, Android OS version, and custom skin (*HyperOS*, *MIUI*, *One UI*, *ColorOS*, *OxygenOS*, *OriginOS/FuntouchOS*, *MagicOS*, *My UX*, etc.) and loads the matching profile.
- 👁️ **Transparent App Telemetry**: Shows friendly app names alongside package IDs (e.g., `com.miui.analytics` → *Xiaomi Analytics & Telemetry*) with real-time status badges (`[✔ UNINSTALLED]`, `[– NOT INSTALLED]`, `[✖ FAILED]`) and a final summary report.
- 📋 **Interactive Checklist**: Hand-pick individual apps with `[X]` / `[ ]` checkboxes or debloat entire categories in seconds.
- 🔄 **1-Click Restore Tool**: Auto-detects uninstalled packages and lets you reinstall any removed app on-demand using `pm install-existing`.
- 🛡️ **100% Non-Destructive**: Uninstalls for current user (`--user 0`). The read-only `/system` partition is never modified. Warranty, Knox, and OTA updates remain 100% intact.

---

## 🚀 Alternative: Manual Clone & Run

### 🐧 For Linux & 🍎 macOS

```bash
# 1. Clone the repository
git clone https://github.com/intelQong/Android_System_App_Remover.git
cd Android_System_App_Remover

# 2. Make executable & run
chmod +x remover.sh
./remover.sh
```

### 🖥️ For Windows

1. Clone or download this repository.
2. Double-click or run:
   ```cmd
   remover.bat
   ```

---

## 🔄 Restoring Uninstalled Apps

Nothing removed by this tool is permanently deleted from the phone. You can restore any app at any time:

### Method 1: Using the Interactive Launcher
1. Open `./remover.sh` or `remover.bat`.
2. Select **Option [4] Interactive App Restore Tool**.
3. Choose the package(s) you wish to restore.

### Method 2: Via Manual ADB Command
```bash
adb shell pm install-existing <package_name>
```
*Example (Restoring Google YouTube Music):*
```bash
adb shell pm install-existing com.google.android.apps.youtube.music
```

---

## 🛡️ How It Works & Safety

1. **User 0 Uninstallation (`pm uninstall --user 0 <pkg>`)**:
   - System apps reside in the read-only `/system` or `/product` partition.
   - When uninstalled via this tool, the app is deactivated and removed from the active user's environment (`user 0`), freeing RAM, battery, CPU cycles, and background resources.
   - The app can be instantly re-enabled with `pm install-existing`.
2. **Safety Guarantees**:
   - ❌ **No Root Required**: Works completely over standard ADB permissions.
   - 🔒 **No Bootloop Risk**: Core system frameworks, dialers, and essential system providers are protected.
   - 🛡️ **Integrity Intact**: Banking apps, Google Pay, Widevine L1, Samsung Knox, and SafetyNet / Play Integrity are not tripped.
   - 🔄 **OTA Updates**: System updates will continue to work normally.

---

## 📱 Supported Brands & Skins

- **Xiaomi / Redmi / POCO** *(MIUI 11, 12, 13, 14 & HyperOS 1.0, 2.0)*
- **Samsung Galaxy** *(One UI 1.0 through 7.0 / Galaxy S, Z, A, M, F series)*
- **Google Pixel** *(Pixel 4 through Pixel 9 / Android 11 to 15)*
- **OnePlus** *(OxygenOS 11 through 14)*
- **Realme** *(Realme UI 1.0 through 5.0)*
- **Oppo** *(ColorOS 7 through 14)*
- **Vivo & iQOO** *(FuntouchOS & OriginOS)*
- **Huawei & Honor** *(EMUI & MagicOS)*
- **Transsion** *(Tecno HiOS, Infinix XOS, Itel)*
- **Motorola** *(My UX)*
- **Generic AOSP / Any Android 11–15 Device**

---

## 📖 Need Help Enabling USB Debugging?

Check out our comprehensive guide: **[edo.md (Developer Options & Wireless Debugging Guide)](file:///home/ubuntu/Android_System_App_Remover/edo.md)**.
- Step-by-step instructions for every manufacturer.
- Xiaomi/HyperOS specific security settings setup.
- Wireless Debugging pairing over Wi-Fi (Android 11+).

---

## 📜 Credits & License

- **Maintained & Enhanced by**: [Mahmudul Hoque Khan](https://x.com/intelQong)
- **Original Concept**: [Reajul Hasan Raju](https://twitter.com/rhraju03)
- **License**: [MIT License](LICENSE_alt)
