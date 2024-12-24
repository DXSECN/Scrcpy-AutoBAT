@echo off
title Scrcpy-AutoBAT-v2.1 based on scrcpy v3.1
setlocal enabledelayedexpansion

REM Define script directory
set "script_dir=%~dp0\scrcpy_core"
cd /d "%script_dir%"

:RESTART

REM Check if config.ini exists, if not, create a default config.ini file
if not exist "%script_dir%\config.ini" (
    call :CONFIG_DEFAULT
)
if not exist "%~dp0\scrcpy_core" (
    echo Press any key to attempt downloading scrcpy_core
    call :SCRCPY_DOWNLOAD
    pause
    cls
    exit
)

REM Load configuration file
call :CONFIG_LOAD
if "resolution"=="" (
    set "new_display=--new-display"
) else (
    set "new_display=--new-display=%resolution%"
)

REM Call GUI parameters
if defined guiMode (set "gui_mode=%guiMode%")
:: actMode conMode

cls

REM Detect or select startup mode
:ACTION_MODE
if defined actMode (
    set act_mode=%actMode%
    echo act_mode=%act_mode%
    goto :ACTION
)
:ACTION_INPUT
echo Please select the execution mode:
echo -----------------------------------------------------
echo 1:Normal Mode, 2:Audio Mode, 3:Application Mode 
echo 4:ADB Servicer, 5:Only Use Custom Parameters, 6:Exit
echo -----------------------------------------------------
set /p "act_mode=MODE "
:ACTION
cls
if "%act_mode%"=="1" (
    echo Selected: Normal Mode
    set com_str_set= -KG --shortcut-mod=%shortcut_mod% --audio-codec=opus
) else if "%act_mode%"=="2" (
    echo Selected: Audio Mode
    set com_str_set= --shortcut-mod=lalt --no-window --audio-codec=opus 
) else if "%act_mode%"=="3" (
    echo Selected: Application Mode
    set com_str_set= --start-app=org.fossify.home -KG --shortcut-mod=lalt --audio-codec=opus --stay-awake %new_display%
    call :APP_CHOICE
) else if "%act_mode%"=="4" (
    cd /d %~dp0
    goto :ADB_MODE
    pause
    exit
) else if "%act_mode%"=="5" (
    echo Selected: Only Use Custom Parameters
    set com_str_set=""
) else if "%act_mode%"=="6" (
    exit
) else (
    echo Invalid input
    goto :ACTION_INPUT
)

REM Detect or select connection mode
:CONNECTION_MODE
if defined conMode (
    set con_mode=%connectMode%
    goto :CONNECTION
)
echo Please select the connection mode:
echo -----------------------------------
echo 1:USB Mode, 2:IP Mode, 3:Exit
echo -----------------------------------
set /p "con_mode=MODE "
cls
:CONNECTION
if "%con_mode%"=="1" (
    echo Entering USB mode
    cls
    goto :MODE_USB
) else if "%con_mode%"=="2" (
    echo Entering IP mode
    cls
    goto :MODE_TRS
) else if "%con_mode%"=="3" (
    exit
) else (
    echo Invalid input
    goto :CONNECTION_MODE
)

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

echo Detected device ID: !device_id!

REM Get device IP address
echo Obtaining device IP address...
for /f "tokens=9" %%a in ('adb -s %device_id% shell ip route ^| findstr "wlan0"') do set device_ip=%%a

if "%device_ip%"=="" (
    echo Failed to find the Wi-Fi IP address
    goto :MODE_INI
)

echo Automatically detected IP address: %device_ip%

REM Set TCP/IP mode
echo Setting device to TCP/IP mode...
adb -s %device_id% tcpip 5555
if errorlevel 1 (
    echo Failed to set TCP/IP mode
    goto :MODE_INI
)

echo TCP/IP mode successfully set, port: 5555

REM Connect device
echo Connecting to device via Wi-Fi...
adb connect %device_ip%:5555
if errorlevel 1 (
    echo Failed to connect device using Wi-Fi debugging
    goto :MODE_INI
) else (
echo Successfully connected to device %device_ip%:5555
set device_port=5555
)
goto :SCRCPY_START

:MODE_INI
if defined deviceIP (
    echo Detected local IP configuration
    set "device_ip=%deviceIP%"
    set "device_port=%devicePort%"
    if "%device_ip%"=="" (
        goto :INPUT_IP
    )

    call :connect_device %device_ip% %device_port%

    if "!connect_success!"=="true" (
        echo Connection successful, device is connected
        goto SCRCPY_START
    ) else (
        goto :INPUT_IP
    )
) else (
    echo No local IP configuration detected
    goto :INPUT_IP
)

:INPUT_IP
echo Please enter the device's IP address and port. Leave blank to use the current address %device_ip%:%device_port%
echo Enter usb to return to USB connection mode, enter ip to reattempt automatic IP detection, enter end to exit
set /p "user_input=IP: "

REM Special command processing
if "%user_input%"=="usb" (
    echo Retrying USB debugging
    goto :MODE_USB
) else if "%user_input%"=="USB" (
    echo Retrying USB debugging
    goto :MODE_USB
) else if "%user_input%"=="ip" (
    goto :MODE_TRS
) else if "%user_input%"=="IP" (
    goto :MODE_TRS
) else if "%user_input%"=="end" (
    exit
) else if "%user_input%"=="END" (
    exit
)

REM Check IP address
if "%user_input%"=="" (
    echo Input is empty, using current address %device_ip%:%device_port%
    if "%device_ip%"=="" (
        cls
        echo Current address is empty, unable to connect device, please re-enter
        goto :INPUT_IP
    )
    call :connect_device %device_ip% %device_port%
    if "!connect_success!"=="true" (
        cls
        echo Connection successful, device is connected
        goto :SCRCPY_START
    ) else (
        cls
        echo Invalid IP address, unable to connect to device, please re-enter
        goto :INPUT_IP
    )
)

REM Split user_input into device_ip and device_port
for /f "tokens=1,2 delims=:" %%a in ("%user_input%") do (
    set "device_ip=%%a"
    set "device_port=%%b"
)
REM Remove extra spaces from device_ip and device_port
set "device_ip=%device_ip: =%"
set "device_port=%device_port: =%"

if not defined device_ip (
    echo Invalid IP address and port
    goto :INPUT_IP
)
call :connect_device %device_ip% %device_port%
if "!connect_success!"=="true" (
    echo Device connected
    goto :SCRCPY_START
) else (
    echo Invalid IP address, unable to connect to device
    goto :INPUT_IP
)

:SCRCPY_START
REM Combine parameters
set com_str_set= --screen-off-timeout=%screen_off_timeout%  --max-size=%max_size% --shortcut-mod=%shortcut_mod%

set usb_streaming_set= --video-codec=%usb_video_codec% --video-buffer=%usb_video_buffer% --max-fps=%usb_max_fps% --audio-codec=%usb_audio_codec% --audio-buffer=%usb_audio_buffer%

set ip_streaming_set= --video-codec=%usb_video_codec% --video-buffer=%usb_video_buffer% --max-fps=%usb_max_fps% --audio-codec=%usb_audio_codec% --audio-buffer=%usb_audio_buffer%

echo Saving configuration file...
call :CONFIG_SAVE
echo IP: %device_ip%:%device_port%
if "%con_mode%"=="1" (
    set com_mode= -d
) else if "%con_mode%"=="2" (
    set com_mode= --serial=%device_ip%:%device_port%
) else (
    echo Invalid connection mode
    pause
    exit /b
)
echo ------------------------------------------------------------------------
echo scrcpy%com_mode%%com_str_set%%usb_streaming_set%%ip_streaming_set%
echo ------------------------------------------------------------------------
powershell -window minimized -command ""
scrcpy%com_mode%%com_str_set%%usb_streaming_set%%ip_streaming_set%%custom_param%
if errorlevel 1 (
    echo Failed to launch scrcpy
    powershell -window normal -command ""
    pause
    exit /b
)
exit

REM Attempt to connect the device
:connect_device
set "connect_success=false"

for /f "delims=" %%a in ('.\adb connect %device_ip%:%device_port% 2^>^&1') do (
    set "output=%%a"
    if "!output!"=="connected to %device_ip%:%device_port%" (
        set "connect_success=true"
    ) else if "!output!"=="already connected to %device_ip%:%device_port%" (
        set "connect_success=true"
    ) else if "!output!"=="cannot connect to %device_ip%:%device_port%: Connection timed out or no response from the host (10060)" (
        set "connect_success=false"
    )
)
exit /b

REM Save configuration file
:CONFIG_SAVE
set "configFile=%~dp0config.ini"
set "tempFile=%~dp0config_temp.ini"

(
    echo [NORM_SET]
    echo screen_off_timeout=%screen_off_timeout%
    echo shortcut_mod=%shortcut_mod%
    echo resolution=%resolution%
    echo app_start_num=%app_start_num%
    echo custom_param=%custom_param%
    
    echo [CONN_SET]
    echo device_ip=%device_ip%
    echo device_port=%device_port%
    
    echo [USB_SET]
    echo usb_video_codec=%usb_video_codec%
    echo usb_video_buffer=%usb_video_buffer%
    echo usb_max_fps=%usb_max_fps%
    echo usb_audio_codec=%usb_audio_codec%
    echo usb_audio_buffer=%usb_audio_buffer%
    
    echo [IP_SET]
    echo ip_video_codec=%ip_video_codec%
    echo ip_video_buffer=%ip_video_buffer%
    echo ip_max_fps=%ip_max_fps%
    echo ip_audio_codec=%ip_audio_codec%
    echo ip_audio_buffer=%ip_audio_buffer%
    
    echo [APP_List]
    for /L %%i in (1,1,9) do (
        if defined app%%i (
            echo app_%%i=!app%%i!
        ) else (
            echo app_%%i=
        )
    )
    echo app_0=
    echo [END]
) > "%tempFile%"
move /y "%tempFile%" "%configFile%" >nul
exit /b

REM Load configuration file
:CONFIG_LOAD
set "configFile=%~dp0config.ini"
set "inSection="
set "appCount=0"

REM Iterate through configuration file
for /f "tokens=*" %%a in ('type "%configFile%"') do (
    set "line=%%a"

    REM Check sections
    if "!line!"=="[NORM_SET]" set "inSection=NORM_SET"
    if "!line!"=="[CONN_SET]" set "inSection=CONN_SET"
    if "!line!"=="[USB_SET]" set "inSection=USB_SET"
    if "!line!"=="[IP_SET]" set "inSection=IP_SET"
    if "!line!"=="[APP_List]" set "inSection=APP_List"
    if "!line!"=="[END]" set "inSection="

    REM Dynamically parse configuration items
    if defined inSection (
        for /f "tokens=1,* delims==" %%b in ("!line!") do (
            set "key=%%b"
            set "value=%%c"
            if not "%%c"=="" set "!key!=%%c"
        )
    )

    REM Process APP_List
    if "!inSection!"=="APP_List" (
        if not "%%a"=="" (
            set /a appCount+=1
            set "app!appCount!=%%a"
        )
    )
)
REM Split the resolution variable into res_width and res_height
for /f "tokens=1,2 delims=x:" %%a in ("%resolution%") do (
    set "res_width=%%a"
    set "res_height=%%b"
)
exit /b

REM Generate default configuration file
:CONFIG_DEFAULT
set "configFile=%~dp0config.ini"
set "tempFile=%~dp0config_temp.ini"

(
    echo [NORM_SET]
    echo screen_off_timeout=300
    echo shortcut_mod=lalt
    echo resolution=864x1920
    echo max_size=1920
    echo app_start_num=1
    echo custom_param=

    echo [CONN_SET]
    echo device_ip=
    echo device_port=5555

    echo [USB_SET]
    echo usb_video_codec=h264
    echo usb_video_buffer=50
    echo usb_max_fps=90
    echo usb_audio_codec=opus
    echo usb_audio_buffer=50

    echo [IP_SET]
    echo ip_video_codec=h265
    echo ip_video_buffer=80
    echo ip_max_fps=60
    echo ip_audio_codec=opus
    echo ip_audio_buffer=80

    echo [APP_List]
    echo app_1=org.fossify.home
    echo app_2=
    echo app_3=
    echo app_4=
    echo app_5=
    echo app_6=
    echo app_7=
    echo app_8=
    echo app_9=
    echo app_0=
    echo [END]
) > "%tempFile%"
move /y "%tempFile%" "%configFile%" >nul
exit /b

:APP_CHOICE
REM Clear screen
cls

REM Iterate through App_1 to App_9 and App_0 to display non-empty application options
echo Available application list:
set "app_found=false"
for /L %%i in (1,1,9) do (
    if defined app_%%i (
        if not "!app_%%i!"=="" (
            echo %%i: !app_%%i!
            set "app_found=true"
        )
    )
)

REM Handle App_0 logic separately
if defined app_0 (
    if not "!app_0!"=="" (
        echo 0: !app_0!
        set "app_found=true"
    )
)

REM If no application is found, show a message
if not "!app_found!"=="true" (
    echo No available application options.
    pause
    exit /b
)

REM Prompt the user to enter an application number
echo Please enter the application number to start (0-9). Press Enter to skip and launch the default application %app_start_num%.
set /p app_input_choice=

REM If the user input is empty, use the default app_start_num
if "%app_input_choice%"=="" (
    set "app_input_choice=%app_start_num%"
)

REM Validate if the user input is a valid numerical option
if "%app_input_choice%" geq "0" if "%app_input_choice%" leq "9" (
    REM Get the selected application
    set "selected_app=!app_%app_input_choice%!"
    if not "!selected_app!"=="" (
        echo Launching application: !selected_app!
        set app_start_num=%app_input_choice%
        exit /b
    ) else (
        echo Invalid selection, no application found.
        pause
        goto :APP_CHOICE
    )
) else (
    echo Invalid input, please enter a number between 0-9.
    pause
    goto :APP_CHOICE
)

exit /b

REM ADB Service
:ADB_MODE
cd /d %script_dir%
if not defined adbMode (
    set adb_mode=%adbMode%
echo Please select the execution mode
echo --------------------------------------------------------------------
echo 1:Restart ADB Server, 2:Stop ADB Server, 3:Start ADB Server, 4:Exit
echo --------------------------------------------------------------------
set /p "adb_mode=MODE "
)
cls

if "%adb_mode%"=="1" (
    echo Restarting service...
    adb kill-server
    adb start-server
    if errorlevel 1 (
        echo Failed to restart service
        pause
        exit /b
    )
    cls
    echo Service restarted successfully
    goto :RESTART

) else if "%adb_mode%"=="2" (
    echo Stopping service...
    adb kill-server
    if errorlevel 1 (
        echo Failed to stop service
        pause
        exit /b
    )
    cls
    echo Service stopped
    pause
    exit

) else if "%adb_mode%"=="3" (
    echo Starting service...
    adb start-server
    if errorlevel 1 (
        echo Failed to start service
        pause
        exit /b
    )
    cls
    echo Service started successfully
    goto :RESTART

) else if "%adb_mode%"=="4" (
    exit

) else (
    echo Invalid input
    goto ADB_MODE
)

exit /b

REM Download scrcpy_core
:SCRCPY_DOWNLOAD
if exist scrcpy_core (exit /b)
if not exist scrcpy-win64-v3.1.zip (
REM Download scrcpy-win64-v3.1.zip
powershell wget -Uri https://github.com/Genymobile/scrcpy/releases/download/v3.1/scrcpy-win64-v3.1.zip -OutFile "scrcpy-win64-v3.1.zip"
)

REM Check if download was successful
if exist "scrcpy-win64-v3.1.zip" (
    echo Archive downloaded successfully
) else (
    echo Failed to download archive
    pause
    exit /b
)

REM Extract files to the current directory
powershell -command "Expand-Archive -Path 'scrcpy-win64-v3.1.zip' -DestinationPath '.'"

REM Check if extraction was successful
if exist "scrcpy-win64-v3.1.zip" (

    REM Rename the extracted directory to scrcpy_core
    ren scrcpy-win64-v3.1 scrcpy_core

    REM Delete the archive
    del scrcpy-win64-v3.1.zip

    echo Extraction and renaming successful, archive deleted
    timeout /t 3
    exit /b
) else (
    echo Extraction failed
    pause
    exit /b
)
pause
exit /b