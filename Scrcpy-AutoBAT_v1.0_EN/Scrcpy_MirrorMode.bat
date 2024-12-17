@echo off
chcp 65001 >nul
title Scrcpy Mirror Mode
setlocal enabledelayedexpansion

:RESTART

REM Mode parameters
set com_str_set= -KG --shortcut-mod=lalt --audio-source=playback --audio-codec=opus

set usb_streaming_set= --video-codec=h264 -m 1920 --video-buffer=50 -b 60M --max-fps=90 --screen-off-timeout=300 --audio-buffer=50 
set ip_streaming_set= --video-codec=h265 -m 1920 --video-buffer=50 -b 20M --max-fps=60 --screen-off-timeout=300 --audio-buffer=80 

REM Define script directory variable
set "script_dir=%~dp0"

REM Initialize IP address
set "device_id="
set "device_ip="
set "device_port="

:INPUT_MODE
echo Please enter the execution mode (1: USB Mode, 2: IP Mode, end: Exit)
set /p "user_input_mode=MODE "
cls
if "%user_input_mode%"=="1" (
    echo Entering USB Mode
    cls
    goto MODE_USB
) else if "%user_input_mode%"=="2" (
    echo Entering IP Mode
    cls
    goto MODE_TRS
) else if "%user_input_mode%"=="end" (
    exit
) else if "%user_input%"=="END" (
    exit
) else (
    echo Invalid input
    goto INPUT_MODE
)


::------------------------------------------------------------------------------
:MODE_USB
powershell -window minimized -command ""
scrcpy -d %com_str_set% %usb_streaming_set%

::

if errorlevel 1 (
    echo Failed to start scrcpy
    powershell -window normal -command ""
    pause
    exit /b
) else (
    echo scrcpy has terminated...
    
    exit
)

echo Detected device ID: %device_id%


::------------------------------------------------------------------------------
:MODE_TRS
REM Automatically detect device ID
for /f "skip=1 tokens=1" %%i in ('adb devices') do (
    set device_id=%%i
    REM If the current line is empty, skip
    if "!device_id!"=="" (
        goto :end
    )
)

REM Get device IP address
echo Getting device IP address...
for /f "tokens=9" %%a in ('adb -s %device_id% shell ip route ^| findstr "wlan0"') do set device_ip=%%a

if "%device_ip%"=="" (
    echo IP address of WIFI not found
    goto MODE_INI
)

echo Extracted IP address from configuration file: %device_ip%

REM Set TCP/IP mode
echo Setting device to TCP/IP mode...
adb -s %device_id% tcpip 5555
if errorlevel 1 (
    echo Failed to set TCP/IP mode
    goto MODE_INI
)

echo TCP/IP mode set successfully, port: 5555

REM Connect to device
echo Connecting to device via Wi-Fi...
adb connect %device_ip%:5555
if errorlevel 1 (
    echo Device failed to connect to Wi-Fi debugging
    goto MODE_INI
)
echo Successfully connected to device %device_ip%:5555
set device_port=5555
goto SCRCPY_START


:MODE_INI
set "ip_config=%script_dir%ip_config.ini"
if exist "%ip_config%" (
    echo Local IP configuration detected
    for /f "tokens=1,2 delims=:" %%a in ('type "%ip_config%"') do (
        set "device_ip=%%a"
        set "device_port=%%b"
    )

    if "%device_ip%"=="" (
        goto INPUT_IP
    )

    call :connect_device %device_ip% %device_port%

    if "!connect_success!"=="true" (
        echo Connection successful, device connected
        goto SCRCPY_START
    ) else (
        goto INPUT_IP
    )
) else (
    echo No local IP configuration detected
    goto INPUT_IP
)


:INPUT_IP
echo Please enter the device's IP address and port, leave blank to use current address %device_ip%:%device_port%
echo Enter usb to return to USB direct connection mode, enter ip to retry automatic IP detection, enter end to exit
set /p "user_input=IP: "

REM Special command handling
if "%user_input%"=="usb" (
    echo Retrying USB debugging
    goto MODE_USB
) else if "%user_input%"=="USB" (
    echo Retrying USB debugging
    goto MODE_USB
) else if "%user_input%"=="ip" (
    goto MODE_TRS
) else if "%user_input%"=="IP" (
    goto MODE_TRS
) else if "%user_input%"=="end" (
    exit
) else if "%user_input%"=="END" (
    exit
)


REM Detect IP address
if "%user_input%"=="" (
    echo Input is empty, using current address %device_ip%:%device_port%
    if "%device_ip%"=="" (
        cls
        echo Current address is empty, unable to connect to device, please re-enter
        goto INPUT_IP
    )
    call :connect_device %device_ip% %device_port%
    if "!connect_success!"=="true" (
        cls
        echo Connection successful, device connected
        goto SCRCPY_START
    ) else (
        cls
        echo Incorrect IP address, unable to connect to device, please re-enter
        goto INPUT_IP
    )
)

for /f "tokens=1,2 delims=:" %%a in ("%user_input%") do (
    set "device_ip=%%a"
    set "device_port=%%b"
)
REM Remove extra spaces from device_ip, device_port
set "device_ip=%device_ip: =%"
set "device_port=%device_port: =%"

if not defined device_ip (
    echo Invalid IP address and port
    pause
    exit /b
)
call :connect_device %device_ip% %device_port%
if "!connect_success!"=="true" (
    echo Device connected
    goto SCRCPY_START
) else (
    echo Incorrect IP address, unable to connect to device
    goto INPUT_IP
)

:connect_device
set "device_ip=%~1"
set "device_port=%~2"
set "connect_success=false"

for /f "delims=" %%a in ('.\adb connect %device_ip%:%device_port% 2^>^&1') do (
    set "output=%%a"
    if "!output!"=="connected to %device_ip%:%device_port%" (
        set "connect_success=true"
    ) else if "!output!"=="already connected to %device_ip%:%device_port%" (
        set "connect_success=true"
    ) else if "!output!"=="cannot connect to %device_ip%:%device_port%: A connection attempt failed because the connected party did not properly respond after a period of time, or established connection failed because connected host has failed to respond. (10060)" (
        set "connect_success=false"
    )
)
exit /b

:SCRCPY_START
echo Saving latest IP and port to local configuration...
echo -e %device_ip%:%device_port%>ip_config.ini
powershell -window minimized -command ""
scrcpy %com_str_set% %ip_streaming_set%
if errorlevel 1 (
    echo Failed to start scrcpy
    normal -window minimized -command ""
    pause
    exit /b
)
exit