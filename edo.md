# 📖 Developer Options, USB Debugging & Wireless Debugging Guide

This guide covers step-by-step instructions for enabling Developer Options and USB Debugging across various Android phone manufacturers, as well as setting up Wireless Debugging.

---

## 1. How to Enable Developer Options

1. Open **Settings** on your Android device.
2. Scroll down to **About Phone** (or **About Device** / **System Info**).
3. Find the **Build Number** (or vendor equivalent):
   - **Google Pixel / Motorola / Sony / Generic**: Tap `Build number` **7 times**.
   - **Xiaomi / Redmi / POCO**: Tap `MIUI version` or `OS version` **7 times**.
   - **Samsung**: Go to `Software information` -> tap `Build number` **7 times**.
   - **OnePlus / Oppo / Realme**: Go to `About device` -> `Version` -> tap `Build number` **7 times**.
   - **Vivo / iQOO**: Go to `About phone` -> `Software version` -> tap `Software version` **7 times**.
   - **Huawei / Honor**: Go to `About phone` -> tap `Build number` **7 times**.
4. You will see a message on screen: **"You are now a developer!"** (enter your lock screen PIN/password if prompted).

---

## 2. How to Enable USB Debugging

1. Go back to **Settings**.
2. Navigate to **Developer Options**:
   - **Google Pixel / Motorola**: `Settings` -> `System` -> `Developer options`.
   - **Xiaomi / POCO / Redmi**: `Settings` -> `Additional settings` -> `Developer options`.
   - **Samsung**: `Settings` -> `Developer options` (at the very bottom).
   - **OnePlus / Oppo / Realme**: `Settings` -> `Additional settings` (or `System settings`) -> `Developer options`.
   - **Vivo / iQOO**: `Settings` -> `System` -> `Developer options`.
3. Toggle **USB Debugging** to **ON**.
4. Connect your phone to your PC via a USB cable.
5. A popup will appear on your phone screen: **"Allow USB debugging?"**.
   - Check the box: **"Always allow from this computer"**.
   - Tap **"Allow"** or **"OK"**.

---

## 3. Important Vendor-Specific Requirements

### ⚠️ Xiaomi, Redmi & POCO (MIUI / HyperOS)
Xiaomi devices have an additional security requirement to allow ADB commands:
1. In `Developer Options`, scroll down and also enable:
   - **USB Debugging (Security settings)** *(Allow granting permissions and simulating input via USB debugging)*.
   - **Install via USB**.
2. *Note:* Xiaomi requires an active SIM card and logging into a Mi Account to toggle this security setting on once.

### ⚠️ Oppo, Realme & OnePlus (ColorOS / Realme UI / OxygenOS)
1. Ensure `Disable Permission Monitoring` (if present) is toggled on if you experience permission denials.
2. Ensure the USB Connection Mode notification on your notification shade is set to **File Transfer (MTP)** or **MIDI** rather than *Charging only*.

---

## 4. Wireless Debugging Setup (Android 11+)

If you do not have a USB cable available, you can connect wirelessly over Wi-Fi:

1. Ensure your PC and Android phone are connected to the **same Wi-Fi network**.
2. On your phone: Go to `Developer Options` -> turn ON **Wireless Debugging**.
3. Tap **"Wireless Debugging"** -> Tap **"Pair device with pairing code"**.
4. You will see an **IP address & Port** (e.g. `192.168.1.50:37123`) and a **6-digit pairing code**.
5. On your computer terminal, run:
   ```bash
   adb pair <IP>:<Port> <Pairing_Code>
   # Example: adb pair 192.168.1.50:37123 123456
   ```
6. Once paired successfully, note the main Wireless Debugging IP & Port on your phone screen and connect:
   ```bash
   adb connect <IP>:<Main_Port>
   # Example: adb connect 192.168.1.50:41235
   ```
7. Verify connection:
   ```bash
   adb devices
   ```
8. Launch the remover tool: `./remover.sh` or `windows\remover.bat`.
