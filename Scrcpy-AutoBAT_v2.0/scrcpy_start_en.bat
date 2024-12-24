@echo off
title Scrcpy 窗口模式
setlocal enabledelayedexpansion

REM 定义脚本目录
set "script_dir=%~dp0\scrcpy_core"
cd /d "%script_dir%"

REM 检查config.ini是否存在，如果不存在则创建一个默认的config.ini文件
if not exist "%script_dir%\config.ini" (
    call :CONFIG_DEFAULT
)
if not exist "%~dp0scrcpy_core" (
    echo Please put the scrcpy core files into a subfolder scrcpy_core and move them to the current directory
    pause
    exit
)

REM 加载配置文件
call :CONFIG_LOAD
if "resolution"=="" (
    set "new_display=--new-display"
) else (
    set "new_display=--new-display=%resolution%"
)


REM 调用GUI参数
if defined guiMode (set "gui_mode=%guiMode%")
:: actMode conMode


cls
echo Starting scrcpy...


REM 检测或选择启动模式
:ACTION_MODE
if defined actMode (
    set act_mode=%actMode%
    goto :ACTION
)
echo Please enter the execution mode ^(1: Screen projection mode, 2: Audio transmission mode, 3: Window mode, 4: ADB Service, 5: Exit^)
set /p "act_mode=MODE "
cls
:ACTION
if "%act_mode%"=="1" (
    echo Screen projection mode...
    set com_str_set= -KG --shortcut-mod=%shourtcut_mod% --audio-codec=opus
) else if "%act_mode%"=="2" (
    echo Audio transmission mode...
    set com_str_set= --shortcut-mod=lalt --no-window --audio-codec=opus 
) else if "%act_mode%"=="3" (
    echo Application mode...
    set com_str_set= --start-app=org.fossify.home -KG --shortcut-mod=lalt --audio-codec=opus --stay-awake %new_display%
    call :APP_CHOICE
) else if "%act_mode%"=="4" (
    echo ADB Service
    cd /d %~dp0
    call .\scrcpy_adb.bat
    pause
    exit
) else if "%act_mode%"=="5" (
    exit
) else (
    echo Invalid input^!
    goto :ACTION_MODE
)


REM 检测或选择连接模式
:CONNECTION_MODE
if defined conMode (
    set con_mode=%connectMode%
    goto :CONNECTION
)
echo Please enter the connection mode ^(1: USB Mode, 2: IP Mode, 3: Exit^)
set /p "con_mode=MODE "
cls
:CONNECTION
if "%con_mode%"=="1" (
    echo USB Mode
    cls
    goto :MODE_USB
) else if "%con_mode%"=="2" (
    echo IP Mode
    cls
    goto :MODE_TRS
) else if "%con_mode%"=="3" (
    exit
) else (
    echo Invalid input^!
    goto :CONNECTION_MODE
)



::------------------------------------------------------------------------------
:MODE_TRS
REM Automatic Detection of Device ID
for /f "skip=1 tokens=1" %%i in ('adb devices') do (
    set device_id=%%i
    REM 如果当前行为空，跳过
    if "!device_id!"=="" (
        goto :end
    )
)

echo Detected device ID: !device_id!

REM 获取设备 IP 地址
echo Getting device IP address...
for /f "tokens=9" %%a in ('adb -s %device_id% shell ip route ^| findstr "wlan0"') do set device_ip=%%a

if "%device_ip%"=="" (
    echo The IP Address for the WIFI Could Not Be Found.
    goto :MODE_INI
)

echo IP addresses are automatically detected: %device_ip%

REM 设置 TCP/IP 模式
echo Setting device to TCP/IP mode...
adb -s %device_id% tcpip 5555
if errorlevel 1 (
    echo TCP/IP Mode Configuration Failure
    goto :MODE_INI
)

echo TCP/IP mode has been successfully set, port: 5555

REM 连接设备
echo Connecting to the device via Wi-Fi...
adb connect %device_ip%:5555
if errorlevel 1 (
    echo Device connection Wi-Fi debugging failed
    goto :MODE_INI
)
echo Successfully connected to the device %device_ip%:5555
set device_port=5555
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
        echo The connection is successful, and the device is connected
        goto SCRCPY_START
    ) else (
        goto :INPUT_IP
    )
) else (
echo No local IP configuration detected
    goto :INPUT_IP
)



:INPUT_IP
echo Please enter the device's IP address and port, leave blank to use the current address %device_ip%:%device_port%
echo Enter usb to return to USB direct connection mode, enter ip to try to automatically obtain the IP address again, enter end to exit
set /p "user_input=IP: "


REM 特殊命令处理
if "%user_input%"=="usb" (
    echo Reattempt USB Connection
    goto :MODE_USB
) else if "%user_input%"=="USB" (
    echo Reattempt USB Connection
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


REM 检测IP地址
if "%user_input%"=="" (
echo Input is empty, using current address %device_ip%:%device_port%
    if "%device_ip%"=="" (
        cls
        echo Current address is empty, unable to connect to the device, please re-enter
        goto :INPUT_IP
    )
    call :connect_device %device_ip% %device_port%
    if "!connect_success!"=="true" (
        cls
        echo Connection successful, device connected
        goto :SCRCPY_START
    ) else (
        cls
        echo Incorrect IP address, unable to connect to the device, please re-enter
        goto :INPUT_IP
    )
)

REM 将user_input拆分为device_ip和device_port
for /f "tokens=1,2 delims=:" %%a in ("%user_input%") do (
    set "device_ip=%%a"
    set "device_port=%%b"
)
REM 去除 device_ip, device_port 后面的多余空
set "device_ip=%device_ip: =%"
set "device_port=%device_port: =%"

if not defined device_ip (
    echo Incorrect IP address, unable to connect to the device, please re-enter
    goto :INPUT_IP
)
call :connect_device %device_ip% %device_port%
if "!connect_success!"=="true" (
    echo Device connected
    goto :SCRCPY_START
) else (
    echo Incorrect IP address, unable to connect to the device, please re-enter
    goto :INPUT_IP
)


:SCRCPY_START
REM 参数检测

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
scrcpy %com_mode% %com_str_set% %usb_streaming_set% %ip_streaming_set%
if errorlevel 1 (
    echo Failed to start scrcpy
    powershell -window normal -command ""
    pause
    exit /b
)
exit


REM 尝试连接设备
:connect_device
set "connect_success=false"

for /f "delims=" %%a in ('.\adb connect %device_ip%:%device_port% 2^>^&1') do (
    set "output=%%a"
    if "!output!"=="connected to %device_ip%:%device_port%" (
        set "connect_success=true"
    ) else if "!output!"=="already connected to %device_ip%:%device_port%" (
        set "connect_success=true"
    ) else if "!output!"=="cannot connect to %device_ip%:%device_port%: 由于连接方在一段时间后没有正确答复或连接的主机没有反应, 连接尝试失败。 (10060)" (
        set "connect_success=false"
    )
)
exit /b

REM 保存配置文件
:CONFIG_SAVE
set "configFile=%~dp0config.ini"
set "tempFile=%~dp0config_temp.ini"

(
    echo [NORM_SET]
    echo screen_off_timeout=%screen_off_timeout%
    echo shourtcut_mod=%shourtcut_mod%
    echo resolution=%resolution%
    echo app_start_num=%app_start_num%
    
    echo [CONN_SET]
    echo device_ip=%device_ip%
    echo device_port=%device_port%
    
    echo [USB_SET]
    echo usb_video_codec=%usb_video_codec%
    echo usb_video_buffer=%usb_video_buffer%
    echo usb_max_fps=%usb_max_fps%
    echo usb_audio_code=%usb_audio_code%
    echo usb_audio_buffer=%usb_audio_buffer%
    
    echo [IP_SET]
    echo ip_video_codec=%ip_video_codec%
    echo ip_video_buffer=%ip_video_buffer%
    echo ip_max_fps=%ip_max_fps%
    echo ip_audio_code=%ip_audio_code%
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


REM 读取配置文件
:CONFIG_LOAD
set "configFile=%~dp0config.ini"
set "inSection="
set "appCount=0"

REM 遍历配置文件
for /f "tokens=*" %%a in ('type "%configFile%"') do (
    set "line=%%a"

    REM 判断段落
    if "!line!"=="[NORM_SET]" set "inSection=NORM_SET"
    if "!line!"=="[CONN_SET]" set "inSection=CONN_SET"
    if "!line!"=="[USB_SET]" set "inSection=USB_SET"
    if "!line!"=="[IP_SET]" set "inSection=IP_SET"
    if "!line!"=="[APP_List]" set "inSection=APP_List"
    if "!line!"=="[END]" set "inSection="

    REM 动态解析配置项
    if defined inSection (
        for /f "tokens=1,* delims==" %%b in ("!line!") do (
            set "key=%%b"
            set "value=%%c"
            if not "%%c"=="" set "!key!=%%c"
        )
    )

    REM 处理 APP_List
    if "!inSection!"=="APP_List" (
        if not "%%a"=="" (
            set /a appCount+=1
            set "app!appCount!=%%a"
        )
    )
)
REM 将resolution变量拆分为res_width和res_heigth
for /f "tokens=1,2 delimsx:" %%a in ("%resolution%") do (
    set "res_width=%%a"
    set "res_heigth=%%b"
)
exit /b



REM 默认配置文件生成
:CONFIG_DEFAULT
set "configFile=%~dp0config.ini"
set "tempFile=%~dp0config_temp.ini"

(
    echo [NORM_SET]
    echo screen_off_timeout=300
    echo shourtcut_mod=lalt
    echo resolution=1080x1920
    echo max_size=1920
    echo app_start_num=1

    echo [CONN_SET]
    echo device_ip=
    echo device_port=5555

    echo [USB_SET]
    echo usb_video_codec=h264
    echo usb_video_buffer=50
    echo usb_max_fps=90
    echo usb_audio_code=opus
    echo usb_audio_buffer=50

    echo [IP_SET]
    echo ip_video_codec=h265
    echo ip_video_buffer=80
    echo ip_max_fps=60
    echo ip_audio_code=opus
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

REM 清空屏幕
cls

REM 遍历 App_1 到 App_9 和 App_0 并显示非空的应用程序选项
echo List of available applications:
set "app_found=false"
for /L %%i in (1,1,9) do (
    if defined app_%%i (
        if not "!app_%%i!"=="" (
            echo %%i: !app_%%i!
            set "app_found=true"
        )
    )
)

REM 单独处理 App_0 的逻辑
if defined app_0 (
    if not "!app_0!"=="" (
        echo 0: !app_0!
        set "app_found=true"
    )
)

REM 如果没有找到任何应用，显示提示信息
if not "!app_found!"=="true" (
    echo No application options are available.
    pause
    exit /b
)

REM 提示用户输入应用序号
echo Please enter the serial number of the app you want to start (0-9), press enter directly and do not select it, then start the default app %app_start_num%
set /p app_input_choice=

REM 如果用户输入为空，则使用默认值 app_start_num
if "%app_input_choice%"=="" (
    set "app_input_choice=%app_start_num%"
)

REM 验证用户输入是否为有效的数字序号
if "%app_input_choice%" geq "0" if "%app_input_choice%" leq "9" (
    REM 获取用户选择的应用
    set "selected_app=!app_%app_input_choice%!"
    if not "!selected_app!"=="" (
        echo Launching the app soon: !selected_app!
        set app_start_num=%app_input_choice%
        exit /b
    ) else (
        echo invalid selection, no app found
        pause
        goto :APP_CHOICE
    )
) else (
    echo Invalid input. Please enter a number between 0 and 9.
    pause
    goto :APP_CHOICE
)

exit /b


REM ADB服务
:ADB_MODE
if not defined adbMode (
    set adb_mode=%adbMode%
echo Please enter the execution mode (1: Restart ADB-Server, 2: Stop ADB-Server, 3: Start ADB-Server)
set /p "adb_mode=MODE "
)
cls

if "%adb_mode%"=="1" (
    echo Restarting ADB-Server...
    adb kill-server
    adb start-server
    if errorlevel 1 (
        echo Failed to restart ADB-Server
        pause
        exit /b
    )
    cls
    echo ADB-Server restarted successfully
    exit /b

) else if "%adb_mode%"=="2" (
    echo Stopping ADB-Server...
    adb kill-server
    if errorlevel 1 (
        echo Failed to stop ADB-Server
        pause
        exit /b
    )
    cls
    echo ADB-Server stopped
    goto end

) else if "%adb_mode%"=="3" (
    echo Starting ADB-Server...
    adb start-server
    if errorlevel 1 (
        echo Failed to start ADB-Server
        pause
        exit /b
    )
    cls
    echo ADB-Server started successfully
    exit /b

) else if "%adb_mode%"=="4" (
    exit

) else (
    echo Invalid input
    goto ADB_MODE
)

exit /b