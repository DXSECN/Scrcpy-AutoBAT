@echo off
chcp 65001 >nul
title Scrcpy-AutoBAT-v2.1 based on scrcpy v3.1
setlocal enabledelayedexpansion

REM Define script directory
set "script_dir=%~dp0\scrcpy_core"
cd /d "%script_dir%"

:RESTART

REM Define default parameters
REM [NORM_SET]
set screen_off_timeout=300
set shortcut_mod=lalt
set resolution=
set max_size=
set app_start_num=1
set custom_param=-KMG
REM [CONN_SET]
set device_ip=
set device_port=5555
REM [USB_SET]
set usb_video_codec=h264
set usb_video_buffer=50
set usb_max_fps=90
set usb_audio_codec=opus
set usb_audio_buffer=50
REM [IP_SET]
set ip_video_codec=h265
set ip_video_buffer=80
set ip_max_fps=60
set ip_audio_codec=opus
set ip_audio_buffer=80
REM [APP_List]
set app_1=org.fossify.home
set app_2=
set app_3=
set app_4=
set app_5=
set app_6=
set app_7=
set app_8=
set app_9=
set app_0=
REM [END]

REM Check if scrcpy_core folder exists, if not, try to download
if not exist "%~dp0\scrcpy_core" (
    echo Press any key to start downloading scrcpy_core
    call :SCRCPY_DOWNLOAD
    pause
    cls
    exit
)

REM Load configuration file
call :CONFIG_LOAD
if "%resolution%"=="" (
    set "new_display=--new-display"
) else (
    set "new_display=--new-display=%resolution%"
)
if "%max_size%"=="" (
    set "max_size_use="
) else (
    set "max_size_use=--max-size=%max_size%"
)
if defined customParam (
    if not "%customParam%"=="" (
        set "custom_param=%customParam%"
    )
)

REM Call parameters
if defined guiMode (set "gui_mode=%guiMode%")
:: actMode conMode

cls

REM Detect or select startup mode
:ACTION_MODE
if defined actMode (
    set "act_mode=%actMode%"
    goto :ACTION
)


:ACTION_INPUT
echo Please enter execution mode:
echo --------------------------------------
echo 1:Screen Mode 2:Audio Mode 3:App Mode 
echo 4:ADB Service 5:Custom Mode 6:Exit
echo --------------------------------------
set /p "act_mode=MODE "
:ACTION
cls
if "%act_mode%"=="1" (
    echo Selected: Screen Mode
) else if "%act_mode%"=="2" (
    echo Selected: Audio Mode
) else if "%act_mode%"=="3" (
    echo Selected: App Mode
    call :APP_CHOICE
) else if "%act_mode%"=="4" (
    cd /d %~dp0
    goto :ADB_MODE
    pause
    exit
) else if "%act_mode%"=="5" (
    set com_mode=""
) else if "%act_mode%"=="6" (
    exit
) else (
    echo Invalid input
    goto :ACTION_INPUT
)


REM Detect or select connection mode
:CONNECTION_MODE
if defined conMode (
    set "con_mode=%conMode%"
    goto :CONNECTION
)
:CONNECTION_INPUT
echo Please enter connection mode:
echo --------------------------------------
echo 1:USB Mode, 2:IP Mode, 3:Back, 4:Exit
echo --------------------------------------
set /p "con_mode=MODE "
cls
:CONNECTION
if "%con_mode%"=="1" (
    echo Entering USB Mode
    cls
    goto :MODE_USB
) else if "%con_mode%"=="2" (
    echo Entering IP Mode
    cls
    goto :MODE_TRS
) else if "%con_mode%"=="3" (
    goto :ACTION_MODE
) else if "%con_mode%"=="4" (
    exit
) else (
    echo Invalid input
    goto :CONNECTION_INPUT
)


::------------------------------------------------------------------------------
:MODE_TRS
REM Auto-detect device ID
for /f "skip=1 tokens=1" %%i in ('adb devices') do (
    set device_id=%%i
    REM Skip if current line is empty
    if "!device_id!"=="" (
        goto :MODE_INI
    )
)

echo Detected device ID: !device_id!

REM Get device IP address
echo Getting device IP address...
for /f "tokens=9" %%a in ('adb -s %device_id% shell ip route ^| findstr "wlan0"') do set device_ip=%%a

if "%device_ip%"=="" (
    echo No WIFI IP address found
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
    echo Failed to connect device via Wi-Fi debugging
    goto :MODE_INI
) else (
echo Successfully connected to device %device_ip%:5555
if not "%device_ip%"=="" (set device_ip=%device_ip%)
set device_port=5555
)
goto :SCRCPY_START


:MODE_INI
if defined deviceIP (
    echo Detected local IP configuration
    if defined deviceIP (set "device_ip=%deviceIP%")
    if defined devicePort (set "device_port=%devicePort%")
    if "%device_ip%"=="" (
        goto :INPUT_IP
    )

    call :connect_device %device_ip% %device_port%

    if "!connect_success!"=="true" (
        echo Connection successful, device connected
        goto SCRCPY_START
    ) else (
        goto :INPUT_IP
    )
) else (
    echo No local IP configuration detected
    goto :INPUT_IP
)


:INPUT_IP
echo Please enter device IP address and port:
echo --------------------------------------------------------------------------
echo Enter 'usb' to return to USB connection, 'ip' to retry auto IP detection,
echo 'end' to exit, or press Enter to use saved IP: %device_ip%:%device_port%
echo --------------------------------------------------------------------------
set /p "user_input=IP: "


REM Special command handling
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
    echo Using current address: %device_ip%:%device_port%
    echo Loading...
    if "%device_ip%"=="" (
        cls
        echo Current address is empty, cannot connect to device, please enter again
        goto :INPUT_IP
    )
    call :connect_device %device_ip% %device_port%
    if "!connect_success!"=="true" (
        cls
        echo Connection successful, device connected
        goto :SCRCPY_START
    ) else (
        cls
        echo Invalid IP address, cannot connect to device, please try again
        goto :INPUT_IP
    )
)

REM Split user_input into device_ip and device_port
for /f "tokens=1,2 delims=:" %%a in ("%user_input%") do (
    set "device_ip=%%a"
    set "device_port=%%b"
)
REM Remove trailing spaces from device_ip and device_port
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
    echo Invalid IP address, cannot connect to device
    goto :INPUT_IP
)


:SCRCPY_START
REM Parameter composition
echo Saving configuration file...
call :CONFIG_SAVE
:MODE_USB
if "%act_mode%"=="1" (
set "com_str_set= --screen-off-timeout=%screen_off_timeout% %max_size_use% --shortcut-mod=%shortcut_mod%"
) else if "%act_mode%"=="2" (
    set "com_str_set= --screen-off-timeout=%screen_off_timeout% %max_size_use% --shortcut-mod=%shortcut_mod%" --no-window
) else if "%act_mode%"=="3" (
    set "com_str_set= --screen-off-timeout=%screen_off_timeout% %max_size_use% --shortcut-mod=%shortcut_mod% --start-app=%selected_app% %new_display%
) else if "%act_mode%"=="4" (
    set "com_str_set="
)

if con_mode=="1" (
set video_codec=%usb_video_codec%
set video_buffer=%usb_video_buffer%
set max_fps=%usb_max_fps%
set audio_codec=%usb_audio_codec%
set audio_buffer=%usb_audio_buffer%
) else (
set video_codec=%ip_video_codec%
set video_buffer=%ip_video_buffer%
set max_fps=%ip_max_fps%
set audio_codec=%ip_audio_codec%
set audio_buffer=%ip_audio_buffer%
)

set str_set= --video-codec=%video_codec% --video-buffer=%video_buffer%  --audio-codec=%audio_codec% --audio-buffer=%audio_buffer% --max-fps=%max_fps%

if "%connect_mode%"=="1" (
    set connect_mode= -d
) else if "%con_mode%"=="2" (
    set connect_mode= --serial=%device_ip%:%device_port%
) else (
    echo Invalid connection mode
    pause
    exit /b
)
echo ------------------------------------------------------------------------
echo scrcpy%com_mode%%connect_mode%%com_str_set%%str_set% %custom_param%
echo ------------------------------------------------------------------------
powershell -window minimized -command ""
scrcpy%com_mode%%connect_mode%%com_str_set%%str_set% %custom_param%
if errorlevel 1 (
    echo Failed to start scrcpy
    powershell -window normal -command ""
    pause
    exit /b
)
exit


REM Try to connect to device
:connect_device
set "connect_success=false"

for /f "delims=" %%a in ('.\adb connect %device_ip%:%device_port% 2^>^&1') do (
    set "output=%%a"
    if "!output!"=="connected to %device_ip%:%device_port%" (
        set "connect_success=true"
    ) else if "!output!"=="already connected to %device_ip%:%device_port%" (
        set "connect_success=true"
    ) else if "!output!"=="cannot connect to %device_ip%:%device_port%: Connection attempt failed because the connected party did not properly respond after a period of time, or the established connection failed because the connected host failed to respond. (10060)" (
        set "connect_success=false"
    )
)
exit /b


REM ---------------------------------------------------------------------
:CONFIG_SAVE
REM Set output ini file path (overwrite original file)
set "output_ini=%~dp0config.ini"

REM Backup original config.ini file
copy /y "%ini_file%" %~dp0"config_bak" >nul
if errorlevel 1 (
    echo Warning: Cannot backup %ini_file%
) else (
    echo Configuration file backed up as config.bak
)

REM Start writing new config.ini file
REM Use bracket group to ensure all output is redirected at once
(
    REM Write [NORM_SET] section
    echo [NORM_SET]
    echo screen_off_timeout=%screen_off_timeout%
    echo shortcut_mod=%shortcut_mod%
    echo resolution=%resolution%
    echo max_size=%max_size%
    echo app_start_num=%app_start_num%
    echo custom_param=%custom_param%

    REM Write [CONN_SET] section
    echo [CONN_SET]
    echo device_ip=%device_ip%
    echo device_port=%device_port%

    REM Write [USB_SET] section
    echo [USB_SET]
    echo usb_video_codec=%usb_video_codec%
    echo usb_video_buffer=%usb_video_buffer%
    echo usb_max_fps=%usb_max_fps%
    echo usb_audio_codec=%usb_audio_codec%
    echo usb_audio_buffer=%usb_audio_buffer%

    REM Write [IP_SET] section
    echo [IP_SET]
    echo ip_video_codec=%ip_video_codec%
    echo ip_video_buffer=%ip_video_buffer%
    echo ip_max_fps=%ip_max_fps%
    echo ip_audio_codec=%ip_audio_codec%
    echo ip_audio_buffer=%ip_audio_buffer%

    REM Write [APP_List] section
    echo [APP_List]
    echo app_1=%app_1%
    echo app_2=%app_2%
    echo app_3=%app_3%
    echo app_4=%app_4%
    echo app_5=%app_5%
    echo app_6=%app_6%
    echo app_7=%app_7%
    echo app_8=%app_8%
    echo app_9=%app_9%
    echo app_0=%app_0%

    REM Write [END] section (if needed)
    echo [END]
) > "%output_ini%"

echo Configuration file saved successfully...
endlocal
exit /b

REM -------------------------------------------------------------
:CONFIG_LOAD
REM Set ini file path
set "ini_file=%~dp0config.ini"

REM Read ini file line by line
for /f "usebackq tokens=* delims=" %%a in ("%ini_file%") do (
    set "line=%%a"
    
    REM Remove leading and trailing spaces
    call :trim line line_trimmed
    
    REM Skip empty lines and comments
    if not "!line_trimmed!"=="" (
        set "first_char=!line_trimmed:~0,1!"
        if not "!first_char!"=="[" (
            if not "!first_char!"==";" (
                REM Check if contains equals sign =
                echo "!line_trimmed!" | find "=" >nul
                if not errorlevel 1 (
                    REM Split into key and value
                    for /f "tokens=1,* delims==" %%b in ("!line_trimmed!") do (
                        set "key=%%b"
                        set "value=%%c"
                        
                        REM Remove spaces from key and value
                        call :trim key key_trimmed
                        call :trim value value_trimmed
                        
                        REM Set variable with key as name
                        set "!key_trimmed!=!value_trimmed!"
                    )
                )
            )
        )
    )
)

exit /b


REM Subroutine: Trim spaces from variables
:trim
    set "string=!%1!"
    REM Remove left spaces
    for /f "tokens=* delims= " %%x in ("!string!") do set "string=%%x"
    REM Remove right spaces
    :loop
    if "!string:~-1!"==" " (
        set "string=!string:~0,-1!"
        goto loop
    )
    set "%2=!string!"

exit /b


REM ---------------------------------------------------------------------------
:APP_CHOICE
REM Clear screen
cls

REM Loop through App_1 to App_9 and App_0 and display non-empty application options
echo Available applications list:
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

REM If no applications found, display message
if not "!app_found!"=="true" (
    echo No available applications.
    pause
    exit /b
)

REM Prompt user to input application number
echo Please enter application number (0-9), press Enter for default app %app_start_num%
set /p app_input_choice=

REM If user input is empty, use default app_start_num
if "%app_input_choice%"=="" (
    set "app_input_choice=%app_start_num%"
)

REM Validate if user input is valid number
if "%app_input_choice%" geq "0" if "%app_input_choice%" leq "9" (
    REM Get selected application
    set "selected_app=!app_%app_input_choice%!"
    if not "!selected_app!"=="" (
        echo Starting application: !selected_app!
        set app_start_num=%app_input_choice%
        exit /b
    ) else (
        echo Invalid selection, application not found.
        pause
        goto :APP_CHOICE
    )
) else (
    echo Invalid input, please enter a number between 0-9.
    pause
    goto :APP_CHOICE
)

exit /b


REM --------------------------------------------------------------------------
REM ADB Service
:ADB_MODE
cd /d %script_dir%
if not defined adbMode (
    set adb_mode=%adbMode%
echo Please enter required ADB command
echo --------------------------------------------------------------------
echo 1:Restart ADB Service 2:Stop ADB Service 3:Start ADB Service 4:Exit
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


:SCRCPY_DOWNLOAD
if exist scrcpy_core (exit /b)
if not exist scrcpy-win64-v3.1.zip (
REM Download scrcpy-win64-v3.1.zip
powershell wget -Uri https://github.com/Genymobile/scrcpy/releases/download/v3.1/scrcpy-win64-v3.1.zip -OutFile "scrcpy-win64-v3.1.zip"
)

REM Check if download was successful
if exist "scrcpy-win64-v3.1.zip" (
    echo Package downloaded successfully
) else (
    echo Package download failed
    echo Please download scrcpy core files manually and rename the folder to scrcpy_core
    pause
    exit /b
)

REM Extract files to current directory
powershell -command "Expand-Archive -Path 'scrcpy-win64-v3.1.zip' -DestinationPath '.'"

REM Check if extraction was successful
if exist "scrcpy-win64-v3.1.zip" (

    REM Rename extracted directory to scrcpy_core
    ren scrcpy-win64-v3.1 scrcpy_core

    REM Delete zip file
    del scrcpy-win64-v3.1.zip

    echo Extraction and rename successful, package deleted
    timeout /t 3
    goto RESTART
) else (
    echo Extraction failed
    pause
    exit /b
)
pause
exit /b