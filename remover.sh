#!/usr/bin/env bash

# ==============================================================================
# Android System App Remover & Debloater v2.0
# Interactive CLI tool to safely remove bloatware, telemetry, and OEM apps.
# Supports Linux and macOS with automatic ADB setup, auto-device detection,
# live uninstallation progress with friendly app names, and restore tools.
# ==============================================================================

# Exit on unexpected errors in critical subshells, but keep interactive shell alive
set -o pipefail

# ------------------------------------------------------------------------------
# Terminal Color Codes
# ------------------------------------------------------------------------------
if [[ -t 1 ]]; then
    C_RESET='\033[0m'
    C_BOLD='\033[1m'
    C_DIM='\033[2m'
    C_RED='\033[0;31m'
    C_GREEN='\033[0;32m'
    C_YELLOW='\033[0;33m'
    C_BLUE='\033[0;34m'
    C_MAGENTA='\033[0;35m'
    C_CYAN='\033[0;36m'
    C_WHITE='\033[1;37m'
    C_BG_BLUE='\033[44m'
else
    C_RESET=''
    C_BOLD=''
    C_DIM=''
    C_RED=''
    C_GREEN=''
    C_YELLOW=''
    C_BLUE=''
    C_MAGENTA=''
    C_CYAN=''
    C_WHITE=''
    C_BG_BLUE=''
fi

# ------------------------------------------------------------------------------
# Global Variables & State
# ------------------------------------------------------------------------------
DEVICE_SERIAL=""
DEVICE_MANUFACTURER=""
DEVICE_BRAND=""
DEVICE_MODEL=""
DEVICE_ANDROID_VER=""
DEVICE_ROM_VER=""
DEVICE_BATTERY=""
DETECTED_PROFILE=""
CURRENT_PROFILE=""

# Arrays for candidate packages and descriptions
declare -a CANDIDATE_PKGS=()
declare -a CANDIDATE_DESCS=()
declare -a CANDIDATE_SELECTED=()

# ------------------------------------------------------------------------------
# Helper: Print Banners & Headers
# ------------------------------------------------------------------------------
print_banner() {
    clear 2>/dev/null || true
    echo -e "${C_CYAN}${C_BOLD}"
    echo "================================================================================"
    echo "         📱  ANDROID SYSTEM APP REMOVER & DEBLOATER (v2.0)"
    echo "               Safe • No Root Required • Fully Reversible"
    echo "================================================================================"
    echo -e "${C_RESET}"
}

print_device_header() {
    echo -e "${C_WHITE}${C_BOLD}┌─[ CONNECTED DEVICE STATUS ]──────────────────────────────────────────────────┐${C_RESET}"
    if [[ -n "$DEVICE_SERIAL" ]]; then
        local batt_str="N/A"
        [[ -n "$DEVICE_BATTERY" ]] && batt_str="${DEVICE_BATTERY}%"
        local rom_str=""
        [[ -n "$DEVICE_ROM_VER" ]] && rom_str=" • ROM: ${DEVICE_ROM_VER}"

        echo -e "${C_WHITE}│ ${C_GREEN}● ONLINE${C_WHITE} | ${C_CYAN}${DEVICE_BRAND^^} ${DEVICE_MODEL}${C_WHITE} (Android ${DEVICE_ANDROID_VER}${rom_str})${C_RESET}"
        echo -e "${C_WHITE}│ Serial: ${C_DIM}${DEVICE_SERIAL}${C_RESET}${C_WHITE} | Battery: ${C_YELLOW}${batt_str}${C_WHITE} | Profile: ${C_MAGENTA}${CURRENT_PROFILE^^}${C_RESET}"
    else
        echo -e "${C_WHITE}│ ${C_RED}● NO DEVICE CONNECTED / UNAUTHORIZED${C_RESET}"
    fi
    echo -e "${C_WHITE}${C_BOLD}└──────────────────────────────────────────────────────────────────────────────┘${C_RESET}"
    echo ""
}

# ------------------------------------------------------------------------------
# Feature 1: Automatic ADB Installation Check
# ------------------------------------------------------------------------------
ensure_adb_installed() {
    if command -v adb >/dev/null 2>&1 && adb version >/dev/null 2>&1; then
        return 0
    fi

    print_banner
    echo -e "${C_YELLOW}${C_BOLD}[!] ADB (Android Debug Bridge) is not installed on this system.${C_RESET}\n"
    echo -e "This tool requires ADB to communicate with your Android device."
    echo -e "Would you like this script to automatically install ADB for you?\n"

    read -rp "Install ADB now? [Y/n]: " choice
    choice=${choice:-Y}

    if [[ "$choice" =~ ^[Yy]$ ]]; then
        echo -e "\n${C_CYAN}[*] Detecting operating system and package manager...${C_RESET}"

        if [[ "$OSTYPE" == "darwin"* ]]; then
            if command -v brew >/dev/null 2>&1; then
                echo -e "${C_CYAN}[*] Running: brew install android-platform-tools${C_RESET}"
                brew install android-platform-tools
            else
                echo -e "${C_RED}[✖] Homebrew not found. Please install Homebrew or download platform-tools manually from:${C_RESET}"
                echo "    https://developer.android.com/studio/releases/platform-tools"
                exit 1
            fi
        elif [[ -f /etc/debian_version ]] || command -v apt-get >/dev/null 2>&1; then
            echo -e "${C_CYAN}[*] Running: sudo apt update && sudo apt install -y android-tools-adb${C_RESET}"
            sudo apt update && sudo apt install -y android-tools-adb android-tools-fastboot || sudo apt install -y adb
        elif [[ -f /etc/arch-release ]] || command -v pacman >/dev/null 2>&1; then
            echo -e "${C_CYAN}[*] Running: sudo pacman -S --noconfirm android-tools${C_RESET}"
            sudo pacman -S --noconfirm android-tools
        elif [[ -f /etc/fedora-release ]] || [[ -f /etc/redhat-release ]] || command -v dnf >/dev/null 2>&1; then
            echo -e "${C_CYAN}[*] Running: sudo dnf install -y android-tools${C_RESET}"
            sudo dnf install -y android-tools
        elif command -v zypper >/dev/null 2>&1; then
            echo -e "${C_CYAN}[*] Running: sudo zypper install -y android-tools${C_RESET}"
            sudo zypper install -y android-tools
        else
            echo -e "${C_RED}[✖] Unsupported Linux distribution. Please install 'android-tools' or 'adb' via your package manager.${C_RESET}"
            exit 1
        fi

        if command -v adb >/dev/null 2>&1; then
            echo -e "\n${C_GREEN}${C_BOLD}[✔] ADB installed successfully!${C_RESET}\n"
            sleep 2
        else
            echo -e "\n${C_RED}${C_BOLD}[✖] ADB installation failed or binary not found in PATH.${C_RESET}"
            exit 1
        fi
    else
        echo -e "\n${C_RED}[✖] ADB is required. Exiting.${C_RESET}"
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# Feature 2: Device Connection & OEM Identification
# ------------------------------------------------------------------------------
detect_device() {
    adb start-server >/dev/null 2>&1

    while true; do
        local raw_devices
        raw_devices=$(adb devices | grep -v "List of devices" | grep -v "^$" || true)

        if [[ -z "$raw_devices" ]]; then
            DEVICE_SERIAL=""
            print_banner
            print_device_header
            echo -e "${C_YELLOW}${C_BOLD}[!] No Android device detected via USB or Wireless ADB.${C_RESET}\n"
            echo -e "Please ensure:"
            echo -e "  1. Your phone is connected via USB cable (or Wireless Debugging is paired)."
            echo -e "  2. Developer Options and ${C_WHITE}${C_BOLD}USB Debugging${C_RESET} are ENABLED on your phone."
            echo -e "  3. (Xiaomi/HyperOS) ${C_WHITE}${C_BOLD}USB Debugging (Security settings)${C_RESET} is ENABLED."
            echo -e "  4. USB Connection Mode on phone is set to File Transfer (MTP) or MIDI.\n"
            echo -e "${C_CYAN}Options:${C_RESET}"
            echo -e "  [${C_WHITE}R${C_RESET}] Retry connection"
            echo -e "  [${C_WHITE}W${C_RESET}] View guide on enabling USB Debugging"
            echo -e "  [${C_WHITE}C${C_RESET}] Connect to Wireless ADB IP:Port"
            echo -e "  [${C_WHITE}Q${C_RESET}] Quit"
            echo ""
            read -rp "Select option [R/w/c/q]: " choice
            case "${choice,,}" in
                w) show_debugging_guide ;;
                c) connect_wireless_adb ;;
                q) exit 0 ;;
                *) sleep 1 ;;
            esac
            continue
        fi

        # Check for unauthorized state
        if echo "$raw_devices" | grep -q "unauthorized"; then
            DEVICE_SERIAL=""
            print_banner
            print_device_header
            echo -e "${C_RED}${C_BOLD}[!] Device is UNAUTHORIZED.${C_RESET}\n"
            echo -e "${C_YELLOW}Check your phone's screen right now!${C_RESET}"
            echo -e "A popup saying ${C_WHITE}'Allow USB Debugging?'${C_RESET} should appear."
            echo -e "Check the box ${C_WHITE}'Always allow from this computer'${C_RESET} and tap ${C_GREEN}${C_BOLD}'Allow' / 'OK'${C_RESET}.\n"
            read -rp "Press [Enter] once authorized, or [R] to retry: "
            continue
        fi

        # Pick the first authorized device
        DEVICE_SERIAL=$(echo "$raw_devices" | grep "device$" | head -n 1 | awk '{print $1}')
        if [[ -n "$DEVICE_SERIAL" ]]; then
            break
        fi
        sleep 1
    done

    # Query device details via adb shell getprop
    DEVICE_MANUFACTURER=$(adb -s "$DEVICE_SERIAL" shell getprop ro.product.manufacturer 2>/dev/null | tr -d '\r\n')
    DEVICE_BRAND=$(adb -s "$DEVICE_SERIAL" shell getprop ro.product.brand 2>/dev/null | tr -d '\r\n')
    DEVICE_MODEL=$(adb -s "$DEVICE_SERIAL" shell getprop ro.product.model 2>/dev/null | tr -d '\r\n')
    DEVICE_ANDROID_VER=$(adb -s "$DEVICE_SERIAL" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r\n')

    # Detect Custom ROMs / Skins
    local miui_ver
    miui_ver=$(adb -s "$DEVICE_SERIAL" shell getprop ro.miui.ui.version.name 2>/dev/null | tr -d '\r\n')
    local hyper_ver
    hyper_ver=$(adb -s "$DEVICE_SERIAL" shell getprop ro.build.version.incremental 2>/dev/null | tr -d '\r\n')
    local oneui_ver
    oneui_ver=$(adb -s "$DEVICE_SERIAL" shell getprop ro.build.version.oneui 2>/dev/null | tr -d '\r\n')
    local coloros_ver
    coloros_ver=$(adb -s "$DEVICE_SERIAL" shell getprop ro.build.version.opporom 2>/dev/null | tr -d '\r\n')

    DEVICE_ROM_VER=""
    if [[ -n "$miui_ver" ]]; then
        DEVICE_ROM_VER="MIUI $miui_ver"
    elif [[ "$hyper_ver" =~ OS[0-9] ]] || [[ "$miui_ver" =~ OS ]]; then
        DEVICE_ROM_VER="HyperOS"
    elif [[ -n "$oneui_ver" ]]; then
        DEVICE_ROM_VER="One UI"
    elif [[ -n "$coloros_ver" ]]; then
        DEVICE_ROM_VER="ColorOS $coloros_ver"
    fi

    # Read battery
    DEVICE_BATTERY=$(adb -s "$DEVICE_SERIAL" shell dumpsys battery 2>/dev/null | grep "level:" | awk '{print $2}' | tr -d '\r\n')

    # Map manufacturer / brand to profile
    local brand_lower="${DEVICE_BRAND,,} ${DEVICE_MANUFACTURER,,}"
    if [[ "$brand_lower" =~ xiaomi|redmi|poco|blackshark ]]; then
        DETECTED_PROFILE="xiaomi"
    elif [[ "$brand_lower" =~ samsung ]]; then
        DETECTED_PROFILE="samsung"
    elif [[ "$brand_lower" =~ google ]]; then
        DETECTED_PROFILE="google"
    elif [[ "$brand_lower" =~ oneplus ]]; then
        DETECTED_PROFILE="oneplus"
    elif [[ "$brand_lower" =~ realme ]]; then
        DETECTED_PROFILE="realme"
    elif [[ "$brand_lower" =~ oppo ]]; then
        DETECTED_PROFILE="oppo"
    elif [[ "$brand_lower" =~ vivo|iqoo ]]; then
        DETECTED_PROFILE="vivo"
    elif [[ "$brand_lower" =~ huawei|honor ]]; then
        DETECTED_PROFILE="huawei"
    elif [[ "$brand_lower" =~ transsion|tecno|infinix|itel ]]; then
        DETECTED_PROFILE="transsion"
    elif [[ "$brand_lower" =~ motorola|lenovo ]]; then
        DETECTED_PROFILE="motorola"
    else
        DETECTED_PROFILE="generic"
    fi

    CURRENT_PROFILE="$DETECTED_PROFILE"
}

connect_wireless_adb() {
    print_banner
    echo -e "${C_CYAN}${C_BOLD}[ Wireless ADB Connection ]${C_RESET}\n"
    echo "1. On Android 11+: Go to Developer Options -> Wireless Debugging -> Pair with code."
    echo "   Run: adb pair <ip:port> <pairing_code>"
    echo "2. Once paired, enter the connection IP and Port below (e.g. 192.168.1.50:5555):\n"
    read -rp "Enter IP:Port: " wireless_target
    if [[ -n "$wireless_target" ]]; then
        adb connect "$wireless_target"
        echo ""
        read -rp "Press [Enter] to continue..."
    fi
}

show_debugging_guide() {
    print_banner
    echo -e "${C_CYAN}${C_BOLD}[ How to Enable Developer Options & USB Debugging ]${C_RESET}\n"
    echo -e "1. Open ${C_WHITE}${C_BOLD}Settings${C_RESET} on your phone."
    echo -e "2. Go to ${C_WHITE}${C_BOLD}About Phone / About Device${C_RESET}."
    echo -e "3. Tap ${C_WHITE}${C_BOLD}Build Number${C_RESET} (or MIUI/HyperOS Version / Software Version) ${C_YELLOW}${C_BOLD}7 times${C_RESET}."
    echo -e "   -> You will see a toast notification: 'You are now a developer!'."
    echo -e "4. Go back to ${C_WHITE}${C_BOLD}Settings -> System (or Additional Settings) -> Developer Options${C_RESET}."
    echo -e "5. Turn ON ${C_GREEN}${C_BOLD}USB Debugging${C_RESET}."
    echo -e "6. ${C_YELLOW}For Xiaomi / POCO / Redmi users:${C_RESET}"
    echo -e "   • Also turn ON ${C_GREEN}${C_BOLD}USB Debugging (Security settings)${C_RESET} (requires SIM card / Xiaomi account login)."
    echo -e "   • Turn ON ${C_GREEN}${C_BOLD}Install via USB${C_RESET}."
    echo ""
    read -rp "Press [Enter] to return..."
}

# ------------------------------------------------------------------------------
# Feature 3: Bloatware Package Lists Database with Friendly Names
# ------------------------------------------------------------------------------
load_profile_packages() {
    local profile="$1"
    CANDIDATE_PKGS=()
    CANDIDATE_DESCS=()
    CANDIDATE_SELECTED=()

    case "$profile" in
        xiaomi)
            add_pkg "com.miui.analytics" "Xiaomi Analytics & Telemetry"
            add_pkg "com.miui.msa.global" "MIUI System Ads (MSA Service)"
            add_pkg "com.xiaomi.mipicks" "GetApps (Xiaomi App Store)"
            add_pkg "com.mi.globalbrowser" "Mi Browser"
            add_pkg "com.miui.bugreport" "Mi Bug Report"
            add_pkg "com.miui.miservice" "Mi Services & Feedback"
            add_pkg "com.miui.yellowpage" "Yellow Pages Caller ID"
            add_pkg "com.miui.cleaner" "Clean Master Engine (Mi Cleaner)"
            add_pkg "com.mi.android.globalminusscreen" "App Vault (Minus 1 Screen)"
            add_pkg "com.mi.globalTrendNews" "Trend News Feed"
            add_pkg "com.miui.hybrid" "Quick Apps (Hybrid Platform)"
            add_pkg "com.miui.hybrid.accessory" "Quick Apps Accessory"
            add_pkg "com.xiaomi.joyose" "Joyose Ad & Junk Service"
            add_pkg "com.xiaomi.payment" "Mi Pay / Payment Services"
            add_pkg "com.mipay.wallet.in" "Mi Pay Wallet"
            add_pkg "com.micredit.in" "Mi Credit"
            add_pkg "com.miui.videoplayer" "Mi Video Player"
            add_pkg "com.miui.player" "Mi Music Player"
            add_pkg "com.miui.weather2" "Mi Weather App"
            add_pkg "com.miui.compass" "Mi Compass"
            add_pkg "com.miui.notes" "Mi Notes"
            add_pkg "com.xiaomi.midrop" "ShareMe (Mi Drop)"
            add_pkg "com.xiaomi.glgm" "Mi Games"
            add_pkg "com.xiaomi.gamecenter" "Xiaomi Game Center"
            add_pkg "com.mi.global.bbs" "Xiaomi Community"
            add_pkg "com.miui.enbbs" "Xiaomi Forum"
            add_pkg "cn.wps.xiaomi.abroad.lite" "Mi Doc Viewer (WPS Lite)"
            add_pkg "com.miui.virtualsim" "Mi Virtual SIM"
            add_pkg "com.miui.klo.bugreport" "KLO Bug Reporter"
            add_pkg "com.miui.userguide" "User Guide"
            add_pkg "com.miui.translation.kingsoft" "Kingsoft Translation"
            add_pkg "com.miui.huanji" "Mi Mover"
            ;;

        samsung)
            add_pkg "com.samsung.android.bixby.agent" "Bixby Voice Assistant"
            add_pkg "com.samsung.android.bixby.wakeup" "Bixby Wakeup Service"
            add_pkg "com.samsung.android.bixby.service" "Bixby Service"
            add_pkg "com.samsung.android.bixbyvision.framework" "Bixby Vision Framework"
            add_pkg "com.samsung.android.app.spage" "Samsung Free / Daily / News Page"
            add_pkg "com.samsung.android.app.routines" "Bixby Routines"
            add_pkg "com.sec.android.app.sbrowser" "Samsung Internet Browser"
            add_pkg "com.samsung.android.game.gos" "Game Optimizing Service (GOS)"
            add_pkg "com.samsung.android.game.gamehome" "Samsung Gaming Hub (Game Launcher)"
            add_pkg "com.samsung.android.game.gametools" "Game Tools"
            add_pkg "com.samsung.android.gametuner.thin" "Game Tuner"
            add_pkg "com.samsung.android.aremoji" "AR Emoji Studio"
            add_pkg "com.sec.android.mimage.avatarstickers" "AR Emoji Stickers"
            add_pkg "com.samsung.android.emojiupdater" "Emoji Updater"
            add_pkg "com.samsung.android.app.camera.sticker.stamp.preload" "Camera Stickers Preload"
            add_pkg "com.samsung.android.stickercenter" "Sticker Center"
            add_pkg "com.samsung.android.kidsinstaller" "Samsung Kids Installer"
            add_pkg "com.samsung.android.voc" "Samsung Members"
            add_pkg "com.samsung.ecomm.global" "Samsung Shop"
            add_pkg "com.sec.android.app.popupcalculator" "Samsung Calculator"
            add_pkg "com.sec.android.app.voicenote" "Samsung Voice Recorder"
            add_pkg "com.samsung.android.oneconnect" "SmartThings"
            add_pkg "com.samsung.android.service.aircommand" "Air Command (S-Pen)"
            add_pkg "com.samsung.android.drivelink.stub" "Car Mode / DriveLink"
            add_pkg "com.samsung.android.mateagent" "Galaxy Friends (Mate Agent)"
            add_pkg "com.sec.android.easyMover.Agent" "Smart Switch Agent"
            add_pkg "com.samsung.android.app.watchmanagerstub" "Galaxy Wearable Stub"
            add_pkg "com.samsung.android.wellbeing" "Digital Wellbeing (Samsung)"
            add_pkg "com.sec.android.daemonapp" "Samsung Weather Widget"
            add_pkg "flipboard.boxer.app" "Flipboard News Briefing"
            ;;

        google)
            add_pkg "com.google.android.apps.googleassistant" "Google Assistant"
            add_pkg "com.android.hotwordenrollment.okgoogle" "Google OK Google Hotword"
            add_pkg "com.google.android.apps.magazines" "Google News & Magazines"
            add_pkg "com.google.android.apps.docs" "Google Drive / Docs"
            add_pkg "com.google.android.apps.photos" "Google Photos"
            add_pkg "com.google.android.apps.tachyon" "Google Meet / Duo"
            add_pkg "com.google.android.apps.translate" "Google Translate"
            add_pkg "com.google.android.apps.youtube" "YouTube"
            add_pkg "com.google.android.apps.youtube.music" "YouTube Music"
            add_pkg "com.google.android.apps.books" "Google Play Books"
            add_pkg "com.google.android.apps.podcasts" "Google Podcasts"
            add_pkg "com.google.android.music" "Google Play Music"
            add_pkg "com.google.android.videos" "Google TV (Play Movies)"
            add_pkg "com.google.android.apps.walletnfcrel" "Google Wallet"
            add_pkg "com.google.android.projection.gearhead" "Android Auto"
            add_pkg "com.google.ar.lens" "Google Lens"
            add_pkg "com.google.android.apps.wellbeing" "Digital Wellbeing"
            add_pkg "com.google.android.apps.safetyhub" "Personal Safety"
            add_pkg "com.google.android.apps.nbu.paisa.user" "Google Pay (Tez / GPay)"
            add_pkg "com.google.android.feedback" "Google Feedback Reporter"
            add_pkg "com.google.android.inputmethod.pinyin" "Google Pinyin Keyboard"
            add_pkg "com.google.android.inputmethod.japanese" "Google Japanese Keyboard"
            add_pkg "com.google.android.inputmethod.korean" "Google Korean Keyboard"
            ;;

        oneplus)
            add_pkg "com.oneplus.gamespace" "OnePlus Games (Game Space)"
            add_pkg "com.oneplus.membership" "OnePlus Community / Red Cable Club"
            add_pkg "net.oneplus.commonlogtool" "OnePlus Log Tool / Telemetry"
            add_pkg "com.oneplus.brickmode" "OnePlus Zen Mode"
            add_pkg "com.oneplus.account" "OnePlus Account"
            add_pkg "com.oneplus.mall" "OnePlus Store"
            add_pkg "com.heytap.mcs" "HeyTap Messaging / Push Service"
            add_pkg "com.heytap.cloud" "HeyTap Cloud Storage"
            add_pkg "com.heytap.openid" "HeyTap OpenID Tracking"
            add_pkg "com.coloros.gamespace" "ColorOS Game Space"
            add_pkg "com.oneplus.sound.recorder" "OnePlus Sound Recorder"
            add_pkg "com.oneplus.note" "OnePlus Notes"
            add_pkg "com.oneplus.weather" "OnePlus Weather"
            ;;

        realme)
            add_pkg "com.realme.link" "Realme Link (IoT)"
            add_pkg "com.heytap.pictorial" "Lock Screen Magazine / Glance Ads"
            add_pkg "com.heytap.market" "App Market (HeyTap Store)"
            add_pkg "com.heytap.browser" "HeyTap Browser"
            add_pkg "com.heytap.music" "HeyTap Music"
            add_pkg "com.heytap.themestore" "Realme Theme Store"
            add_pkg "com.heytap.usercenter" "HeyTap User Center / Account"
            add_pkg "com.heytap.cloud" "HeyTap Cloud"
            add_pkg "com.heytap.mcs" "HeyTap Push Notifications"
            add_pkg "com.coloros.gamespace" "Game Space (Realme)"
            add_pkg "com.coloros.video" "Realme Video Player"
            add_pkg "com.coloros.weather.service" "Weather Service"
            add_pkg "com.coloros.compass2" "Realme Compass"
            add_pkg "com.oplus.apprecover" "App Recover"
            add_pkg "com.daemon.shelper" "Security Helper Daemon"
            ;;

        oppo)
            add_pkg "com.heytap.market" "Oppo App Market"
            add_pkg "com.heytap.browser" "HeyTap Browser"
            add_pkg "com.heytap.pictorial" "Lock Screen Magazine / Lockscreen Ads"
            add_pkg "com.heytap.themestore" "Oppo Theme Store"
            add_pkg "com.heytap.music" "Oppo Music"
            add_pkg "com.heytap.cloud" "HeyTap Cloud Backup"
            add_pkg "com.heytap.usercenter" "Oppo Account User Center"
            add_pkg "com.coloros.gamespace" "Oppo Game Space"
            add_pkg "com.coloros.video" "Oppo Video"
            add_pkg "com.coloros.compass2" "Oppo Compass"
            add_pkg "com.coloros.weather.service" "Oppo Weather Service"
            add_pkg "com.coloros.smartdrive" "Smart Driving"
            add_pkg "com.oplus.crashbox" "Oplus Crash Reporter"
            add_pkg "com.oplus.cosa" "Oplus Game Acceleration"
            ;;

        vivo)
            add_pkg "com.vivo.appstore" "V-Appstore (Vivo App Store)"
            add_pkg "com.vivo.browser" "Vivo Browser"
            add_pkg "com.vivo.game" "Vivo Game Center"
            add_pkg "com.vivo.gamecube" "Ultra Game Mode (Game Cube)"
            add_pkg "com.vivo.magazine" "Lockscreen Poster / Glance Ads"
            add_pkg "com.bbk.theme" "iTheme (Vivo Theme Store)"
            add_pkg "com.bbk.cloud" "vivo Cloud"
            add_pkg "com.bbk.account" "vivo Account"
            add_pkg "com.vivo.easyshare" "EasyShare (File Sharing)"
            add_pkg "com.vivo.compass" "Vivo Compass"
            add_pkg "com.vivo.weather" "Vivo Weather"
            add_pkg "com.vivo.videoeditor" "Video Editor"
            add_pkg "com.iqoo.engineermode" "iQOO Engineer Mode"
            add_pkg "com.vivo.pushservice" "Vivo Push Notification Service"
            ;;

        huawei)
            add_pkg "com.huawei.appmarket" "Huawei AppGallery"
            add_pkg "com.huawei.browser" "Huawei Browser"
            add_pkg "com.huawei.hwid" "Huawei Mobile Services (HMS Core)"
            add_pkg "com.huawei.himovie.overseas" "Huawei Video"
            add_pkg "com.huawei.music" "Huawei Music"
            add_pkg "com.huawei.hicloud" "Huawei Cloud"
            add_pkg "com.huawei.hifolder" "Huawei Games / App Folder"
            add_pkg "com.huawei.compass" "Huawei Compass"
            add_pkg "com.huawei.magazine" "Magazine Unlock / Lockscreen Ads"
            add_pkg "com.huawei.gamebox" "GameCenter"
            add_pkg "com.huawei.android.karaoke" "Huawei Karaoke"
            ;;

        transsion)
            add_pkg "com.transsion.hilauncher" "HiOS / XOS Launcher Ads"
            add_pkg "com.transsion.palmpay" "PalmPay App"
            add_pkg "com.transsion.phoenix" "Phoenix Browser"
            add_pkg "com.transsion.carlcare" "Carlcare Service"
            add_pkg "com.transsion.videoplayer" "Transsion Video Player"
            add_pkg "com.transsion.magicshow" "Magic Show / Theme"
            add_pkg "com.transsion.mol" "MOL Game Store"
            add_pkg "com.transsion.tecnospot" "Tecno Spot Forum"
            add_pkg "com.transsion.infinix.xclub" "Infinix XClub"
            ;;

        motorola)
            add_pkg "com.motorola.ccc.notification" "Motorola Notifications"
            add_pkg "com.motorola.help" "Moto Help"
            add_pkg "com.motorola.gamemode" "Moto Gametime"
            add_pkg "com.motorola.fmplayer" "Motorola FM Radio"
            add_pkg "com.motorola.demo" "Moto Retail Demo Mode"
            add_pkg "com.motorola.brapps" "Motorola Suggested Apps"
            ;;

        *) # Generic / Fallback
            ;;
    esac

    # Common Third-Party & Carrier Bloatware (Included in all profiles)
    add_pkg "com.amazon.mShop.android.shopping" "Amazon Shopping"
    add_pkg "com.amazon.appmanager" "Amazon App Manager / Bloat Provider"
    add_pkg "com.facebook.katana" "Facebook Main App"
    add_pkg "com.facebook.system" "Facebook App Installer"
    add_pkg "com.facebook.appmanager" "Facebook App Manager"
    add_pkg "com.facebook.services" "Facebook Services"
    add_pkg "com.netflix.partner.activation" "Netflix Partner Activation"
    add_pkg "com.netflix.mediaclient" "Netflix Media Client"
    add_pkg "com.ebay.mobile" "eBay Shopping"
    add_pkg "com.ebay.carrier" "eBay Carrier Service"
    add_pkg "com.alibaba.aliexpresshd" "AliExpress"
    add_pkg "sg.bigo.live" "Bigo Live"
    add_pkg "ru.yandex.searchplugin" "Yandex Search Plugin"
    add_pkg "com.booking" "Booking.com Preload"
    add_pkg "com.opera.browser" "Opera Browser Preload"
    add_pkg "com.opera.preinstall" "Opera Preinstall Partner"
    add_pkg "com.glance.internet" "Glance Lockscreen Content / Ads"
}

add_pkg() {
    local pkg="$1"
    local desc="$2"
    # Prevent duplicates
    for existing in "${CANDIDATE_PKGS[@]}"; do
        [[ "$existing" == "$pkg" ]] && return 0
    done
    CANDIDATE_PKGS+=("$pkg")
    CANDIDATE_DESCS+=("$desc")
    CANDIDATE_SELECTED+=(1) # Default selected: 1 (true)
}

# ------------------------------------------------------------------------------
# Feature 4: Core Execution Engine (Live Status Badges & Summary)
# ------------------------------------------------------------------------------
execute_debloat() {
    local -a pkgs_to_remove=()
    local -a descs_to_remove=()

    for idx in "${!CANDIDATE_PKGS[@]}"; do
        if [[ "${CANDIDATE_SELECTED[$idx]}" -eq 1 ]]; then
            pkgs_to_remove+=("${CANDIDATE_PKGS[$idx]}")
            descs_to_remove+=("${CANDIDATE_DESCS[$idx]}")
        fi
    done

    if [[ ${#pkgs_to_remove[@]} -eq 0 ]]; then
        echo -e "\n${C_YELLOW}[!] No packages selected for uninstallation.${C_RESET}"
        sleep 2
        return 0
    fi

    print_banner
    print_device_header
    echo -e "${C_WHITE}${C_BOLD}[ UNINSTALLATION CANDIDATES PREVIEW (${#pkgs_to_remove[@]} APPS) ]${C_RESET}\n"

    for i in "${!pkgs_to_remove[@]}"; do
        printf "  %2d. %-35s %s(%s)%s\n" "$((i+1))" "${descs_to_remove[$i]}" "${C_DIM}" "${pkgs_to_remove[$i]}" "${C_RESET}"
    done
    echo ""

    echo -e "${C_YELLOW}${C_BOLD}NOTE:${C_RESET} System packages are uninstalled for the current user (${C_WHITE}--user 0${C_RESET})."
    echo -e "Your system partition remains untouched and apps can be restored anytime using Option [4].\n"

    read -rp "Proceed with uninstallation? [Y/n]: " confirm
    confirm=${confirm:-Y}
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "\n${C_YELLOW}[*] Operation cancelled by user.${C_RESET}"
        sleep 1.5
        return 0
    fi

    echo -e "\n${C_CYAN}${C_BOLD}┌─[ RUNNING UNINSTALLATION ]───────────────────────────────────────────────────┐${C_RESET}"

    local count_success=0
    local count_not_installed=0
    local count_failed=0
    local total=${#pkgs_to_remove[@]}

    for i in "${!pkgs_to_remove[@]}"; do
        local pkg="${pkgs_to_remove[$i]}"
        local desc="${descs_to_remove[$i]}"
        local num="$((i+1))"

        printf "│ %s[%2d/%2d]%s %-32s " "${C_DIM}" "$num" "$total" "${C_RESET}" "${desc:0:32}"

        # Execute ADB command
        local output
        output=$(adb -s "$DEVICE_SERIAL" shell pm uninstall --user 0 "$pkg" 2>&1 | tr -d '\r\n')

        if [[ "$output" == *"Success"* ]]; then
            echo -e "${C_GREEN}${C_BOLD}[✔ UNINSTALLED]${C_RESET}"
            ((count_success++))
        elif [[ "$output" == *"not installed for 0"* ]] || [[ "$output" == *"Failure [not installed"* ]]; then
            echo -e "${C_DIM}[– NOT INSTALLED]${C_RESET}"
            ((count_not_installed++))
        else
            echo -e "${C_RED}${C_BOLD}[✖ FAILED: ${output}]${C_RESET}"
            ((count_failed++))
        fi
    done

    echo -e "${C_CYAN}${C_BOLD}└──────────────────────────────────────────────────────────────────────────────┘${C_RESET}\n"

    # End-of-Run Summary Report
    echo -e "${C_WHITE}${C_BOLD}===============================[ SUMMARY REPORT ]===============================${C_RESET}"
    echo -e "  • Total Apps Processed:     ${C_BOLD}$total${C_RESET}"
    echo -e "  • Successfully Uninstalled: ${C_GREEN}${C_BOLD}$count_success${C_RESET}"
    echo -e "  • Already Absent / Skipped: ${C_DIM}$count_not_installed${C_RESET}"
    if [[ $count_failed -gt 0 ]]; then
        echo -e "  • Errors / Failed:          ${C_RED}${C_BOLD}$count_failed${C_RESET}"
    fi
    echo -e "${C_WHITE}${C_BOLD}================================================================================${C_RESET}\n"

    read -rp "Press [Enter] to return to main menu..."
}

# ------------------------------------------------------------------------------
# Feature 5: Interactive App Checklist Multi-Select
# ------------------------------------------------------------------------------
interactive_checklist() {
    while true; do
        print_banner
        print_device_header
        echo -e "${C_WHITE}${C_BOLD}[ INTERACTIVE APP CHECKLIST - Profile: ${CURRENT_PROFILE^^} ]${C_RESET}"
        echo -e "${C_DIM}Toggle individual apps ON or OFF before running uninstallation.${C_RESET}\n"

        local selected_count=0
        for idx in "${!CANDIDATE_PKGS[@]}"; do
            local mark="${C_RED}[ ]${C_RESET}"
            if [[ "${CANDIDATE_SELECTED[$idx]}" -eq 1 ]]; then
                mark="${C_GREEN}[X]${C_RESET}"
                ((selected_count++))
            fi
            printf "  %s %2d. %-32s %s(%s)%s\n" "$mark" "$((idx+1))" "${CANDIDATE_DESCS[$idx]:0:32}" "${C_DIM}" "${CANDIDATE_PKGS[$idx]}" "${C_RESET}"
        done

        echo ""
        echo -e "Selected: ${C_GREEN}${C_BOLD}${selected_count}/${#CANDIDATE_PKGS[@]} apps${C_RESET}\n"
        echo -e "Commands:"
        echo -e "  • Enter number(s) (e.g. ${C_WHITE}1${C_RESET} or ${C_WHITE}1 3 5${C_RESET} or ${C_WHITE}1-10${C_RESET}) to toggle"
        echo -e "  • Type ${C_WHITE}'all'${C_RESET} to select all • ${C_WHITE}'none'${C_RESET} to clear all"
        echo -e "  • Type ${C_GREEN}${C_BOLD}'c'${C_RESET} to Confirm and Uninstall"
        echo -e "  • Type ${C_RED}'b'${C_RESET} to go Back to Main Menu\n"

        read -rp "Input command: " cmd
        cmd=$(echo "$cmd" | tr -d '[:punct:]' || echo "$cmd")

        case "${cmd,,}" in
            b|back|q) return 0 ;;
            c|confirm|run)
                execute_debloat
                return 0
                ;;
            all)
                for i in "${!CANDIDATE_SELECTED[@]}"; do CANDIDATE_SELECTED[$i]=1; done
                ;;
            none|clear)
                for i in "${!CANDIDATE_SELECTED[@]}"; do CANDIDATE_SELECTED[$i]=0; done
                ;;
            *)
                for token in $cmd; do
                    if [[ "$token" =~ ^[0-9]+$ ]] && [[ "$token" -ge 1 ]] && [[ "$token" -le "${#CANDIDATE_PKGS[@]}" ]]; then
                        local target_idx=$((token-1))
                        if [[ "${CANDIDATE_SELECTED[$target_idx]}" -eq 1 ]]; then
                            CANDIDATE_SELECTED[$target_idx]=0
                        else
                            CANDIDATE_SELECTED[$target_idx]=1
                        fi
                    fi
                done
                ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# Feature 6: Interactive Search & Keyword Debloat
# ------------------------------------------------------------------------------
interactive_search_debloat() {
    print_banner
    print_device_header
    echo -e "${C_WHITE}${C_BOLD}[ SEARCH & DEBLOAT BY KEYWORD ]${C_RESET}\n"
    echo "Enter a package or app name keyword (e.g. bixby, facebook, analytics, chrome, youtube):"
    read -rp "Search keyword: " query

    if [[ -z "$query" ]]; then
        return 0
    fi

    echo -e "\n${C_CYAN}[*] Searching installed packages matching '${query}'...${C_RESET}"
    local search_results
    search_results=$(adb -s "$DEVICE_SERIAL" shell pm list packages | grep -i "$query" | sed 's/package://g' | tr -d '\r' || true)

    if [[ -z "$search_results" ]]; then
        echo -e "${C_YELLOW}[!] No installed packages found matching '${query}'.${C_RESET}\n"
        read -rp "Press [Enter] to return..."
        return 0
    fi

    # Build temporary candidate list
    CANDIDATE_PKGS=()
    CANDIDATE_DESCS=()
    CANDIDATE_SELECTED=()

    while IFS= read -r match_pkg; do
        [[ -z "$match_pkg" ]] && continue
        add_pkg "$match_pkg" "Custom Match: $match_pkg"
    done <<< "$search_results"

    interactive_checklist
    # Restore standard profile packages afterwards
    load_profile_packages "$CURRENT_PROFILE"
}

# ------------------------------------------------------------------------------
# Feature 7: Interactive Restore Engine (pm install-existing)
# ------------------------------------------------------------------------------
interactive_restore_tool() {
    print_banner
    print_device_header
    echo -e "${C_WHITE}${C_BOLD}[ INTERACTIVE PACKAGE RESTORE TOOL ]${C_RESET}"
    echo -e "${C_CYAN}[*] Scanning device for uninstalled system packages...${C_RESET}\n"

    # Get all packages including uninstalled (-u) and currently installed
    local all_pkgs
    all_pkgs=$(adb -s "$DEVICE_SERIAL" shell pm list packages -u | sed 's/package://g' | tr -d '\r' | sort)
    local installed_pkgs
    installed_pkgs=$(adb -s "$DEVICE_SERIAL" shell pm list packages | sed 's/package://g' | tr -d '\r' | sort)

    # Find uninstalled packages = all_pkgs minus installed_pkgs
    local uninstalled_pkgs=()
    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        if ! echo "$installed_pkgs" | grep -qx "$pkg"; then
            uninstalled_pkgs+=("$pkg")
        fi
    done <<< "$all_pkgs"

    if [[ ${#uninstalled_pkgs[@]} -eq 0 ]]; then
        echo -e "${C_GREEN}${C_BOLD}[✔] No uninstalled system packages found on this device.${C_RESET}\n"
        read -rp "Press [Enter] to return..."
        return 0
    fi

    echo -e "${C_YELLOW}Found ${#uninstalled_pkgs[@]} uninstalled package(s) on your device:${C_RESET}\n"

    for i in "${!uninstalled_pkgs[@]}"; do
        printf "  %2d. %s\n" "$((i+1))" "${uninstalled_pkgs[$i]}"
    done

    echo ""
    echo "Options:"
    echo "  • Enter number(s) to restore (e.g. 1 or 1 2 3)"
    echo "  • Type 'all' to restore ALL uninstalled packages"
    echo "  • Type 'b' to go back"
    echo ""

    read -rp "Enter choice: " r_choice
    case "${r_choice,,}" in
        b|back|q|"") return 0 ;;
        all)
            echo -e "\n${C_CYAN}[*] Restoring all packages...${C_RESET}"
            for pkg in "${uninstalled_pkgs[@]}"; do
                printf "  Restoring %-40s " "$pkg"
                local res
                res=$(adb -s "$DEVICE_SERIAL" shell pm install-existing "$pkg" 2>&1 | tr -d '\r\n')
                if [[ "$res" == *"installed for user"* ]] || [[ "$res" == *"Success"* ]] || [[ "$res" == *"Package"* ]]; then
                    echo -e "${C_GREEN}[✔ RESTORED]${C_RESET}"
                else
                    echo -e "${C_RED}[✖ $res]${C_RESET}"
                fi
            done
            ;;
        *)
            for token in $r_choice; do
                if [[ "$token" =~ ^[0-9]+$ ]] && [[ "$token" -ge 1 ]] && [[ "$token" -le "${#uninstalled_pkgs[@]}" ]]; then
                    local target_pkg="${uninstalled_pkgs[$((token-1))]}"
                    printf "  Restoring %-40s " "$target_pkg"
                    local res
                    res=$(adb -s "$DEVICE_SERIAL" shell pm install-existing "$target_pkg" 2>&1 | tr -d '\r\n')
                    if [[ "$res" == *"installed for user"* ]] || [[ "$res" == *"Success"* ]] || [[ "$res" == *"Package"* ]]; then
                        echo -e "${C_GREEN}[✔ RESTORED]${C_RESET}"
                    else
                        echo -e "${C_RED}[✖ $res]${C_RESET}"
                    fi
                fi
            done
            ;;
    esac

    echo ""
    read -rp "Press [Enter] to return..."
}

# ------------------------------------------------------------------------------
# Feature 8: Manual / Custom Package Input
# ------------------------------------------------------------------------------
custom_package_input() {
    print_banner
    print_device_header
    echo -e "${C_WHITE}${C_BOLD}[ MANUAL / CUSTOM PACKAGE UNINSTALLER ]${C_RESET}\n"
    echo "Enter exact package name(s) to uninstall (separated by space):"
    read -rp "Package Name: " custom_input

    if [[ -z "$custom_input" ]]; then
        return 0
    fi

    CANDIDATE_PKGS=()
    CANDIDATE_DESCS=()
    CANDIDATE_SELECTED=()

    for p in $custom_input; do
        add_pkg "$p" "Custom App ($p)"
    done

    execute_debloat
    load_profile_packages "$CURRENT_PROFILE"
}

# ------------------------------------------------------------------------------
# Feature 9: Diagnostics & Installed Bloatware Scanner
# ------------------------------------------------------------------------------
device_diagnostics() {
    print_banner
    print_device_header
    echo -e "${C_WHITE}${C_BOLD}[ DEVICE DIAGNOSTICS & BLOAT SCANNER ]${C_RESET}\n"

    echo -e "${C_CYAN}── Hardware & System Info ───────────────────────────────────────────────────${C_RESET}"
    echo "  • Manufacturer:      $DEVICE_MANUFACTURER"
    echo "  • Brand:             $DEVICE_BRAND"
    echo "  • Model:             $DEVICE_MODEL"
    echo "  • Android Version:   $DEVICE_ANDROID_VER"
    local sdk_ver
    sdk_ver=$(adb -s "$DEVICE_SERIAL" shell getprop ro.build.version.sdk 2>/dev/null | tr -d '\r\n')
    echo "  • SDK API Level:     $sdk_ver"
    local fingerprint
    fingerprint=$(adb -s "$DEVICE_SERIAL" shell getprop ro.build.fingerprint 2>/dev/null | tr -d '\r\n')
    echo "  • Build Fingerprint: $fingerprint"
    local security_patch
    security_patch=$(adb -s "$DEVICE_SERIAL" shell getprop ro.build.version.security_patch 2>/dev/null | tr -d '\r\n')
    echo "  • Security Patch:    $security_patch"
    echo ""

    echo -e "${C_CYAN}── Installed Bloatware Scan (${CURRENT_PROFILE^^} Profile) ───────────────────────${C_RESET}"
    local installed_count=0
    local total_count=${#CANDIDATE_PKGS[@]}

    for i in "${!CANDIDATE_PKGS[@]}"; do
        local pkg="${CANDIDATE_PKGS[$i]}"
        local desc="${CANDIDATE_DESCS[$i]}"
        local is_inst
        is_inst=$(adb -s "$DEVICE_SERIAL" shell pm list packages "$pkg" 2>/dev/null | tr -d '\r\n')

        if [[ "$is_inst" == *"package:$pkg"* ]]; then
            printf "  ${C_RED}[PRESENT]${C_RESET}     %-35s ${C_DIM}(%s)${C_RESET}\n" "$desc" "$pkg"
            ((installed_count++))
        fi
    done

    echo ""
    echo -e "Scan result: ${C_YELLOW}${C_BOLD}$installed_count of $total_count${C_RESET} bloatware packages currently installed on phone.\n"
    read -rp "Press [Enter] to return..."
}

# ------------------------------------------------------------------------------
# Feature 10: Manual Profile Selector
# ------------------------------------------------------------------------------
select_manual_profile() {
    print_banner
    print_device_header
    echo -e "${C_WHITE}${C_BOLD}[ SELECT OEM DEBLOAT PROFILE ]${C_RESET}\n"
    echo "  [1] Xiaomi / Redmi / POCO (MIUI & HyperOS)"
    echo "  [2] Samsung (One UI 1 - 7)"
    echo "  [3] Google Pixel"
    echo "  [4] OnePlus (OxygenOS)"
    echo "  [5] Realme (Realme UI)"
    echo "  [6] Oppo (ColorOS)"
    echo "  [7] Vivo / iQOO (FuntouchOS & OriginOS)"
    echo "  [8] Huawei / Honor"
    echo "  [9] Transsion (Tecno / Infinix / Itel)"
    echo "  [10] Motorola"
    echo "  [11] Generic / Standard Third-Party Bloat"
    echo "  [B] Back"
    echo ""

    read -rp "Select profile [1-11]: " prof_choice
    case "$prof_choice" in
        1) CURRENT_PROFILE="xiaomi" ;;
        2) CURRENT_PROFILE="samsung" ;;
        3) CURRENT_PROFILE="google" ;;
        4) CURRENT_PROFILE="oneplus" ;;
        5) CURRENT_PROFILE="realme" ;;
        6) CURRENT_PROFILE="oppo" ;;
        7) CURRENT_PROFILE="vivo" ;;
        8) CURRENT_PROFILE="huawei" ;;
        9) CURRENT_PROFILE="transsion" ;;
        10) CURRENT_PROFILE="motorola" ;;
        11) CURRENT_PROFILE="generic" ;;
        *) return 0 ;;
    esac

    load_profile_packages "$CURRENT_PROFILE"
    echo -e "\n${C_GREEN}[✔] Switched profile to: ${CURRENT_PROFILE^^}${C_RESET}"
    sleep 1
}

# ------------------------------------------------------------------------------
# Main Interactive Loop / Dashboard
# ------------------------------------------------------------------------------
main_menu() {
    ensure_adb_installed
    detect_device
    load_profile_packages "$CURRENT_PROFILE"

    while true; do
        print_banner
        print_device_header

        local rec_tag=""
        if [[ "$CURRENT_PROFILE" == "$DETECTED_PROFILE" ]]; then
            rec_tag="${C_GREEN}(Auto-Detected: ${CURRENT_PROFILE^^})${C_RESET}"
        fi

        echo -e "${C_WHITE}${C_BOLD}[ MAIN MENU ]${C_RESET}"
        echo -e "  [${C_CYAN}1${C_RESET}] 🚀 ${C_BOLD}Quick Safe Debloat${C_RESET} ${rec_tag}"
        echo -e "       ${C_DIM}Instantly uninstall all safe bloatware for current profile with live status.${C_RESET}"
        echo -e "  [${C_CYAN}2${C_RESET}] 📋 ${C_BOLD}Interactive App Checklist${C_RESET}"
        echo -e "       ${C_DIM}Hand-pick and toggle specific apps to keep or remove.${C_RESET}"
        echo -e "  [${C_CYAN}3${C_RESET}] 🔍 ${C_BOLD}Search & Debloat by Keyword${C_RESET}"
        echo -e "       ${C_DIM}Find packages matching a search term (e.g. bixby, ads, facebook).${C_RESET}"
        echo -e "  [${C_CYAN}4${C_RESET}] 🔄 ${C_BOLD}Interactive App Restore Tool${C_RESET}"
        echo -e "       ${C_DIM}Reinstall previously uninstalled system apps on demand.${C_RESET}"
        echo -e "  [${C_CYAN}5${C_RESET}] 🏷  ${C_BOLD}Change OEM Profile${C_RESET} ${C_MAGENTA}[Current: ${CURRENT_PROFILE^^}]${C_RESET}"
        echo -e "  [${C_CYAN}6${C_RESET}] ✍  ${C_BOLD}Manual Package Input${C_RESET}"
        echo -e "  [${C_CYAN}7${C_RESET}] ℹ  ${C_BOLD}Device Diagnostics & Bloatware Scanner${C_RESET}"
        echo -e "  [${C_CYAN}R${C_RESET}] 🔄 ${C_BOLD}Re-scan Device Connection${C_RESET}"
        echo -e "  [${C_RED}0${C_RESET}] ❌ ${C_BOLD}Exit${C_RESET}"
        echo ""

        read -rp "Select an option [0-7 / R]: " menu_choice

        case "${menu_choice,,}" in
            1)
                # Reset all to selected and run
                for i in "${!CANDIDATE_SELECTED[@]}"; do CANDIDATE_SELECTED[$i]=1; done
                execute_debloat
                ;;
            2)
                interactive_checklist
                ;;
            3)
                interactive_search_debloat
                ;;
            4)
                interactive_restore_tool
                ;;
            5)
                select_manual_profile
                ;;
            6)
                custom_package_input
                ;;
            7)
                device_diagnostics
                ;;
            r)
                detect_device
                load_profile_packages "$CURRENT_PROFILE"
                ;;
            0|q|exit)
                print_banner
                echo -e "${C_GREEN}Thank you for using Android System App Remover!${C_RESET}\n"
                exit 0
                ;;
            *)
                echo -e "${C_RED}[!] Invalid choice.${C_RESET}"
                sleep 1
                ;;
        esac
    done
}

# Run the interactive dashboard
main_menu
