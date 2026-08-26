@echo off
setlocal EnableDelayedExpansion
title Android System App Remover & Debloater v2.0
color 0B

:: ============================================================================
:: Android System App Remover & Debloater v2.0
:: All-in-One Automated & Interactive Debloater for Windows
:: Auto-Installs ADB • Auto-Detects Phone Brand • Safe & Reversible
:: ============================================================================

:CHECK_ADB
cls
where adb >nul 2>&1
if %errorlevel% neq 0 (
    echo ================================================================================
    echo           [!] ADB (Android Debug Bridge) is not found in PATH
    echo ================================================================================
    echo.
    echo Would you like this script to download Google Platform-Tools automatically?
    echo  [1] Yes - Download and setup platform-tools locally via PowerShell
    echo  [2] No  - Exit and install manually
    echo.
    set /p adb_choice="Choose option [1-2]: "
    if "!adb_choice!"=="1" (
        echo.
        echo [*] Downloading official Google Android platform-tools...
        powershell -Command "Invoke-WebRequest -Uri 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip' -OutFile '%~dp0platform-tools.zip'"
        echo [*] Extracting platform-tools...
        powershell -Command "Expand-Archive -Path '%~dp0platform-tools.zip' -DestinationPath '%~dp0' -Force"
        del "%~dp0platform-tools.zip" >nul 2>&1
        set "PATH=%~dp0platform-tools;%PATH%"
        echo [✔] ADB setup complete!
        timeout /t 2 >nul
    ) else (
        echo.
        echo Please download ADB from: https://developer.android.com/studio/releases/platform-tools
        pause
        exit /b 1
    )
)

:DEVICE_DETECTION
cls
echo ================================================================================
echo           📱  ANDROID SYSTEM APP REMOVER & DEBLOATER (v2.0)
echo               Safe • No Root Required • Fully Reversible
echo ================================================================================
echo.
echo [*] Checking connected Android devices...

adb start-server >nul 2>&1

:WAIT_FOR_DEVICE
for /f "tokens=1,2" %%A in ('adb devices ^| findstr /v "List of devices"') do (
    if "%%B"=="device" (
        set "DEVICE_SERIAL=%%A"
        goto DEVICE_FOUND
    )
    if "%%B"=="unauthorized" (
        echo.
        echo [!] Device %%A is UNAUTHORIZED!
        echo Check your phone screen and tap "Always allow from this computer" -^> "Allow".
        echo.
        pause
        goto WAIT_FOR_DEVICE
    )
)

echo.
echo [!] No authorized device detected.
echo Ensure USB Debugging is turned ON in Developer Options on your phone.
echo.
echo [R] Retry connection
echo [Q] Quit
echo.
set /p retry_choice="Choice [R/Q]: "
if /i "!retry_choice!"=="Q" exit /b 0
goto WAIT_FOR_DEVICE

:DEVICE_FOUND
:: Fetch Device Properties
for /f "delims=" %%i in ('adb -s %DEVICE_SERIAL% shell getprop ro.product.manufacturer 2^>nul') do set "DEVICE_MANUF=%%i"
for /f "delims=" %%i in ('adb -s %DEVICE_SERIAL% shell getprop ro.product.brand 2^>nul') do set "DEVICE_BRAND=%%i"
for /f "delims=" %%i in ('adb -s %DEVICE_SERIAL% shell getprop ro.product.model 2^>nul') do set "DEVICE_MODEL=%%i"
for /f "delims=" %%i in ('adb -s %DEVICE_SERIAL% shell getprop ro.build.version.release 2^>nul') do set "DEVICE_ANDR_VER=%%i"

:: Clean trailing carriage returns
set "DEVICE_MANUF=!DEVICE_MANUF:~0,-1!" 2>nul
set "DEVICE_BRAND=!DEVICE_BRAND:~0,-1!" 2>nul
set "DEVICE_MODEL=!DEVICE_MODEL:~0,-1!" 2>nul
set "DEVICE_ANDR_VER=!DEVICE_ANDR_VER:~0,-1!" 2>nul

:: Identify target profile
set "TARGET_PROFILE=generic"
echo %DEVICE_BRAND% %DEVICE_MANUF% | findstr /i "xiaomi redmi poco blackshark" >nul && set "TARGET_PROFILE=xiaomi"
echo %DEVICE_BRAND% %DEVICE_MANUF% | findstr /i "samsung" >nul && set "TARGET_PROFILE=samsung"
echo %DEVICE_BRAND% %DEVICE_MANUF% | findstr /i "google pixel" >nul && set "TARGET_PROFILE=google"
echo %DEVICE_BRAND% %DEVICE_MANUF% | findstr /i "oneplus" >nul && set "TARGET_PROFILE=oneplus"
echo %DEVICE_BRAND% %DEVICE_MANUF% | findstr /i "realme" >nul && set "TARGET_PROFILE=realme"
echo %DEVICE_BRAND% %DEVICE_MANUF% | findstr /i "oppo" >nul && set "TARGET_PROFILE=oppo"
echo %DEVICE_BRAND% %DEVICE_MANUF% | findstr /i "vivo iqoo" >nul && set "TARGET_PROFILE=vivo"
echo %DEVICE_BRAND% %DEVICE_MANUF% | findstr /i "huawei honor" >nul && set "TARGET_PROFILE=huawei"
echo %DEVICE_BRAND% %DEVICE_MANUF% | findstr /i "transsion tecno infinix itel" >nul && set "TARGET_PROFILE=transsion"
echo %DEVICE_BRAND% %DEVICE_MANUF% | findstr /i "motorola lenovo" >nul && set "TARGET_PROFILE=motorola"

:MAIN_MENU
cls
echo ================================================================================
echo           📱  ANDROID SYSTEM APP REMOVER & DEBLOATER (v2.0)
echo ================================================================================
echo  Device: %DEVICE_BRAND% %DEVICE_MODEL% (Android %DEVICE_ANDR_VER%)
echo  Serial: %DEVICE_SERIAL% ^| Auto-Detected Profile: %TARGET_PROFILE%
echo ================================================================================
echo.
echo  [1] 🚀 Quick Safe Debloat (Auto-matched for %TARGET_PROFILE%)
echo  [2] 🔍 Search ^& Debloat by Keyword
echo  [3] 🔄 Restore Uninstalled System Package (pm install-existing)
echo  [4] 🏷  Change Debloat Profile Manually
echo  [5] ✍  Manual Package Name Input
echo  [6] ℹ  Device Information ^& Diagnostics
echo  [R] 🔄 Re-scan Device Connection
echo  [0] ❌ Exit
echo.
set /p menu_sel="Select an option [0-6 / R]: "

if "!menu_sel!"=="1" goto RUN_DEBLOAT
if "!menu_sel!"=="2" goto KEYWORD_SEARCH
if "!menu_sel!"=="3" goto RESTORE_TOOL
if "!menu_sel!"=="4" goto CHANGE_PROFILE
if "!menu_sel!"=="5" goto MANUAL_PKG
if "!menu_sel!"=="6" goto DEVICE_INFO
if /i "!menu_sel!"=="R" goto DEVICE_DETECTION
if "!menu_sel!"=="0" goto EXIT_APP
goto MAIN_MENU

:CHANGE_PROFILE
cls
echo ================================================================================
echo                         SELECT OEM DEBLOAT PROFILE
echo ================================================================================
echo.
echo  [1] Xiaomi / Redmi / POCO (MIUI ^& HyperOS)
echo  [2] Samsung (One UI)
echo  [3] Google Pixel
echo  [4] OnePlus (OxygenOS)
echo  [5] Realme (Realme UI)
echo  [6] Oppo (ColorOS)
echo  [7] Vivo / iQOO (FuntouchOS ^& OriginOS)
echo  [8] Huawei / Honor
echo  [9] Transsion (Tecno / Infinix)
echo  [10] Motorola
echo  [11] Generic Bloat
echo  [B] Back
echo.
set /p prof_choice="Select profile [1-11 / B]: "
if "!prof_choice!"=="1" set "TARGET_PROFILE=xiaomi"
if "!prof_choice!"=="2" set "TARGET_PROFILE=samsung"
if "!prof_choice!"=="3" set "TARGET_PROFILE=google"
if "!prof_choice!"=="4" set "TARGET_PROFILE=oneplus"
if "!prof_choice!"=="5" set "TARGET_PROFILE=realme"
if "!prof_choice!"=="6" set "TARGET_PROFILE=oppo"
if "!prof_choice!"=="7" set "TARGET_PROFILE=vivo"
if "!prof_choice!"=="8" set "TARGET_PROFILE=huawei"
if "!prof_choice!"=="9" set "TARGET_PROFILE=transsion"
if "!prof_choice!"=="10" set "TARGET_PROFILE=motorola"
if "!prof_choice!"=="11" set "TARGET_PROFILE=generic"
goto MAIN_MENU

:RUN_DEBLOAT
cls
echo ================================================================================
echo    RUNNING DEBLOAT FOR PROFILE: %TARGET_PROFILE%
echo ================================================================================
echo.
echo All debloating runs safely for user 0 without touching system partitions.
echo.
set /p confirm_run="Proceed? [Y/N]: "
if /i "!confirm_run!" neq "Y" goto MAIN_MENU

echo.
echo [*] Processing packages...

:: Execute based on profile
if "%TARGET_PROFILE%"=="xiaomi" (
    for %%X in (
        "com.miui.analytics" "com.miui.msa.global" "com.xiaomi.joyose" "com.miui.bugreport"
        "com.miui.klo.bugreport" "com.miui.miservice" "com.miui.daemon" "com.xiaomi.mipicks"
        "com.mi.globalbrowser" "com.miui.cleaner" "com.mi.android.globalminusscreen"
        "com.mi.globalTrendNews" "com.miui.hybrid" "com.miui.hybrid.accessory"
        "com.miui.yellowpage" "com.mi.global.bbs" "com.miui.enbbs" "com.xiaomi.midrop"
        "com.xiaomi.glgm" "com.xiaomi.gamecenter" "com.miui.virtualsim" "com.miui.userguide"
        "com.miui.translation.kingsoft" "com.miui.huanji" "cn.wps.xiaomi.abroad.lite"
        "cn.wps.moffice_eng" "com.xiaomi.payment" "com.mipay.wallet.in" "com.micredit.in"
        "com.miui.nextpay" "com.miui.videoplayer" "com.miui.player" "com.miui.weather2"
        "com.miui.weather" "com.miui.notes" "com.miui.compass" "com.xiaomi.hm.health"
        "com.xiaomi.shop" "com.xiaomi.shop2"
    ) do (
        echo  Uninstalling: %%X
        adb -s %DEVICE_SERIAL% shell pm uninstall --user 0 %%X
    )
)

if "%TARGET_PROFILE%"=="samsung" (
    for %%X in (
        "com.samsung.android.bixby.agent" "com.samsung.android.bixby.wakeup"
        "com.samsung.android.bixby.service" "com.samsung.android.bixbyvision.framework"
        "com.samsung.android.visionintelligence" "com.samsung.android.app.spage"
        "com.samsung.android.app.routines" "com.samsung.android.aremoji"
        "com.sec.android.mimage.avatarstickers" "com.samsung.android.emojiupdater"
        "com.samsung.android.app.camera.sticker.stamp.preload" "com.samsung.android.stickercenter"
        "com.samsung.android.service.livedrawing" "com.samsung.android.game.gos"
        "com.samsung.android.game.gamehome" "com.samsung.android.game.gametools"
        "com.samsung.android.gametuner.thin" "com.sec.android.app.sbrowser"
        "com.samsung.android.kidsinstaller" "com.samsung.android.voc"
        "com.samsung.ecomm.global" "com.sec.android.app.popupcalculator"
        "com.sec.android.app.voicenote" "com.samsung.android.oneconnect"
        "com.samsung.android.service.aircommand" "com.samsung.android.drivelink.stub"
        "com.samsung.android.mateagent" "com.sec.android.easyMover.Agent"
        "com.samsung.android.app.watchmanagerstub" "com.samsung.android.wellbeing"
        "com.sec.android.daemonapp" "com.sec.android.easyonehand" "flipboard.boxer.app"
    ) do (
        echo  Uninstalling: %%X
        adb -s %DEVICE_SERIAL% shell pm uninstall --user 0 %%X
    )
)

if "%TARGET_PROFILE%"=="google" (
    for %%X in (
        "com.google.android.apps.googleassistant" "com.android.hotwordenrollment.okgoogle"
        "com.android.hotwordenrollment.xgoogle" "com.google.android.apps.magazines"
        "com.google.android.apps.docs" "com.google.android.apps.photos"
        "com.google.android.apps.tachyon" "com.google.android.apps.translate"
        "com.google.android.apps.youtube" "com.google.android.apps.youtube.music"
        "com.google.android.apps.books" "com.google.android.apps.podcasts"
        "com.google.android.music" "com.google.android.videos" "com.google.ar.lens"
        "com.google.android.apps.wellbeing" "com.google.android.apps.safetyhub"
        "com.google.android.apps.walletnfcrel" "com.google.android.apps.wallet"
        "com.google.android.apps.nbu.paisa.user" "com.google.android.projection.gearhead"
        "com.google.android.feedback"
    ) do (
        echo  Uninstalling: %%X
        adb -s %DEVICE_SERIAL% shell pm uninstall --user 0 %%X
    )
)

if "%TARGET_PROFILE%"=="oneplus" (
    for %%X in (
        "com.oneplus.gamespace" "com.oneplus.membership" "net.oneplus.commonlogtool"
        "com.oneplus.brickmode" "com.oneplus.account" "com.oneplus.mall"
        "com.oneplus.sound.recorder" "com.oneplus.note" "com.oneplus.weather"
        "com.heytap.mcs" "com.heytap.cloud" "com.heytap.openid" "com.coloros.gamespace"
    ) do (
        echo  Uninstalling: %%X
        adb -s %DEVICE_SERIAL% shell pm uninstall --user 0 %%X
    )
)

if "%TARGET_PROFILE%"=="realme" (
    for %%X in (
        "com.realme.link" "com.heytap.pictorial" "com.heytap.market"
        "com.heytap.browser" "com.heytap.music" "com.heytap.themestore"
        "com.heytap.usercenter" "com.heytap.cloud" "com.heytap.mcs"
        "com.coloros.gamespace" "com.coloros.video" "com.coloros.weather.service"
        "com.coloros.compass2" "com.oplus.apprecover" "com.daemon.shelper"
    ) do (
        echo  Uninstalling: %%X
        adb -s %DEVICE_SERIAL% shell pm uninstall --user 0 %%X
    )
)

if "%TARGET_PROFILE%"=="oppo" (
    for %%X in (
        "com.heytap.market" "com.heytap.browser" "com.heytap.pictorial"
        "com.heytap.themestore" "com.heytap.music" "com.heytap.cloud"
        "com.heytap.usercenter" "com.coloros.gamespace" "com.coloros.video"
        "com.coloros.compass2" "com.coloros.weather.service" "com.coloros.smartdrive"
        "com.oplus.crashbox" "com.oplus.cosa"
    ) do (
        echo  Uninstalling: %%X
        adb -s %DEVICE_SERIAL% shell pm uninstall --user 0 %%X
    )
)

if "%TARGET_PROFILE%"=="vivo" (
    for %%X in (
        "com.vivo.appstore" "com.vivo.browser" "com.vivo.game" "com.vivo.gamecube"
        "com.vivo.magazine" "com.bbk.theme" "com.bbk.cloud" "com.bbk.account"
        "com.vivo.easyshare" "com.vivo.compass" "com.vivo.weather"
        "com.vivo.videoeditor" "com.vivo.pushservice" "com.iqoo.engineermode"
    ) do (
        echo  Uninstalling: %%X
        adb -s %DEVICE_SERIAL% shell pm uninstall --user 0 %%X
    )
)

if "%TARGET_PROFILE%"=="huawei" (
    for %%X in (
        "com.huawei.appmarket" "com.huawei.browser" "com.huawei.hwid"
        "com.huawei.himovie.overseas" "com.huawei.music" "com.huawei.hicloud"
        "com.huawei.hifolder" "com.huawei.compass" "com.huawei.magazine"
        "com.huawei.gamebox" "com.huawei.android.karaoke" "com.huawei.health"
        "com.huawei.skytone" "com.huawei.wallet"
    ) do (
        echo  Uninstalling: %%X
        adb -s %DEVICE_SERIAL% shell pm uninstall --user 0 %%X
    )
)

if "%TARGET_PROFILE%"=="transsion" (
    for %%X in (
        "com.transsion.hilauncher" "com.transsion.palmpay" "com.transsion.phoenix"
        "com.transsion.carlcare" "com.transsion.videoplayer" "com.transsion.magicshow"
        "com.transsion.mol" "com.transsion.tecnospot" "com.transsion.infinix.xclub"
    ) do (
        echo  Uninstalling: %%X
        adb -s %DEVICE_SERIAL% shell pm uninstall --user 0 %%X
    )
)

if "%TARGET_PROFILE%"=="motorola" (
    for %%X in (
        "com.motorola.ccc.notification" "com.motorola.help" "com.motorola.gamemode"
        "com.motorola.fmplayer" "com.motorola.demo" "com.motorola.brapps"
    ) do (
        echo  Uninstalling: %%X
        adb -s %DEVICE_SERIAL% shell pm uninstall --user 0 %%X
    )
)

:: Common Third Party & Carrier Bloat
for %%X in (
    "com.amazon.mShop.android.shopping" "com.amazon.appmanager"
    "com.facebook.katana" "com.facebook.system" "com.facebook.appmanager" "com.facebook.services"
    "com.netflix.partner.activation" "com.netflix.mediaclient"
    "com.ebay.mobile" "com.ebay.carrier" "com.alibaba.aliexpresshd"
    "sg.bigo.live" "ru.yandex.searchplugin" "com.glance.internet"
) do (
    echo  Uninstalling: %%X
    adb -s %DEVICE_SERIAL% shell pm uninstall --user 0 %%X
)

echo.
echo ================================================================================
echo Debloat process completed!
echo ================================================================================
pause
goto MAIN_MENU

:KEYWORD_SEARCH
cls
echo ================================================================================
echo                     SEARCH ^& DEBLOAT BY KEYWORD
echo ================================================================================
echo.
set /p search_term="Enter keyword to search (e.g. bixby, facebook, analytics): "
if "%search_term%"=="" goto MAIN_MENU

echo.
echo [*] Searching installed packages matching '%search_term%'...
for /f "tokens=2 delims=:" %%P in ('adb -s %DEVICE_SERIAL% shell pm list packages ^| findstr /i "%search_term%"') do (
    echo Found: %%P
    set /p confirm_del="Uninstall %%P? [y/N]: "
    if /i "!confirm_del!"=="y" (
        adb -s %DEVICE_SERIAL% shell pm uninstall --user 0 %%P
    )
)
echo.
pause
goto MAIN_MENU

:RESTORE_TOOL
cls
echo ================================================================================
echo                   RESTORE UNINSTALLED SYSTEM PACKAGES
echo ================================================================================
echo.
echo Enter the exact package name to restore (e.g. com.google.android.youtube):
set /p restore_pkg="Package Name: "
if "%restore_pkg%"=="" goto MAIN_MENU

echo.
echo [*] Restoring %restore_pkg%...
adb -s %DEVICE_SERIAL% shell pm install-existing %restore_pkg%
echo.
pause
goto MAIN_MENU

:MANUAL_PKG
cls
echo ================================================================================
echo                      MANUAL PACKAGE UNINSTALLER
echo ================================================================================
echo.
set /p manual_pkg="Enter package name to uninstall: "
if "%manual_pkg%"=="" goto MAIN_MENU

echo.
echo [*] Uninstalling %manual_pkg% for current user...
adb -s %DEVICE_SERIAL% shell pm uninstall --user 0 %manual_pkg%
echo.
pause
goto MAIN_MENU

:DEVICE_INFO
cls
echo ================================================================================
echo                      DEVICE INFORMATION ^& DIAGNOSTICS
echo ================================================================================
echo.
echo  • Manufacturer:     %DEVICE_MANUF%
echo  • Brand:            %DEVICE_BRAND%
echo  • Model:            %DEVICE_MODEL%
echo  • Android Version:  %DEVICE_ANDR_VER%
echo  • Serial Number:    %DEVICE_SERIAL%
echo.
echo  • Battery Level:
adb -s %DEVICE_SERIAL% shell dumpsys battery | findstr "level"
echo.
pause
goto MAIN_MENU

:EXIT_APP
cls
echo Thank you for using Android System App Remover!
timeout /t 2 >nul
exit /b 0
