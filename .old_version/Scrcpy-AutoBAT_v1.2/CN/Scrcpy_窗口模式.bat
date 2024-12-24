@echo off
chcp 65001 >nul
title Scrcpy 窗口模式
setlocal enabledelayedexpansion

:RESTART

REM 模式参数
set com_str_set= --start-app=org.fossify.home -KG --shortcut-mod=lalt --audio-codec=opus --stay-awake --audio-source=playback

REM 可根据网络配置调整参数
set usb_streaming_set= --video-codec=h264 --new-display=864x1920 --video-buffer=50 -b 60M --max-fps=90 --screen-off-timeout=300 --audio-buffer=50 
set ip_streaming_set= --video-codec=h265 --new-display=864x1920 --video-buffer=80 -b 20M --max-fps=60 --screen-off-timeout=300 --audio-buffer=80 

REM 可选参数
:: --no-vd-system-decorations

REM 定义脚本目录变量
set "script_dir=%~dp0"

REM 初始化IP地址
set "device_id="
set "device_ip="
set "device_port="

:INPUT_MODE
echo 请输入执行模式 (1:USB模式, 2:IP模式, end:退出)
set /p "user_input_mode=MODE "
cls
if "%user_input_mode%"=="1" (
    echo 进入USB模式
    cls
    goto MODE_USB
) else if "%user_input_mode%"=="2" (
    echo 进入IP模式
    cls
    goto MODE_TRS
) else if "%user_input_mode%"=="end" (
    exit
) else if "%user_input%"=="END" (
    exit
) else (
    echo 无效输入
    goto INPUT_MODE
)


::------------------------------------------------------------------------------
:MODE_USB
powershell -window minimized -command ""
scrcpy -d %com_str_set% %usb_streaming_set%

::

if errorlevel 1 (
    echo 启动scrcpy失败
    powershell -window normal -command ""
    pause
    exit /b
) else (
    echo scrcpy 已终止...
    
    exit
)

echo 已检测到设备 ID: %device_id%


::------------------------------------------------------------------------------
:MODE_TRS
REM 自动检测设备ID
for /f "skip=1 tokens=1" %%i in ('adb devices') do (
    set device_id=%%i
    REM 如果当前行为空，跳过
    if "!device_id!"=="" (
        goto :end
    )
)

REM 获取设备 IP 地址
echo 正在获取设备 IP 地址...
for /f "tokens=9" %%a in ('adb -s %device_id% shell ip route ^| findstr "wlan0"') do set device_ip=%%a

if "%device_ip%"=="" (
    echo 未找到 WIFI 的 IP 地址
    goto MODE_INI
)

echo 已提取配置文件中的 IP 地址: %device_ip%

REM 设置 TCP/IP 模式
echo 正在设置设备为 TCP/IP 模式...
adb -s %device_id% tcpip 5555
if errorlevel 1 (
    echo TCP/IP 模式设置失败
    goto MODE_INI
)

echo TCP/IP 模式已成功设置, 端口: 5555

REM 连接设备
echo 正在通过 Wi-Fi 连接设备...
adb connect %device_ip%:5555
if errorlevel 1 (
    echo 设备连接 Wi-Fi 调试失败
    goto MODE_INI
)
echo 已成功连接到设备 %device_ip%:5555
set device_port=5555
goto SCRCPY_START


:MODE_INI
set "ip_config=%script_dir%ip_config.ini"
if exist "%ip_config%" (
    echo 检测到IP本地配置
    for /f "tokens=1,2 delims=:" %%a in ('type "%ip_config%"') do (
        set "device_ip=%%a"
        set "device_port=%%b"
    )

    if "%device_ip%"=="" (
        goto INPUT_IP
    )

    call :connect_device %device_ip% %device_port%

    if "!connect_success!"=="true" (
        echo 连接成功, 设备已连接
        goto SCRCPY_START
    ) else (
        goto INPUT_IP
    )
) else (
    echo 未检测到IP本地配置
    goto INPUT_IP
)


:INPUT_IP
echo 请输入设备的IP地址和端口, 输入空白则使用当前地址 %device_ip%:%device_port%
echo 输入usb则会返回USB直连模式, 输入ip则会重新尝试自动获取IP地址, 输入end退出
set /p "user_input=IP: "

REM 特殊命令处理
if "%user_input%"=="usb" (
    echo 重新尝试USB调试
    goto MODE_USB
) else if "%user_input%"=="USB" (
    echo 重新尝试USB调试
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


REM 检测IP地址
if "%user_input%"=="" (
    echo 输入为空, 使用当前地址 %device_ip%:%device_port%
    if "%device_ip%"=="" (
        cls
        echo 当前地址为空, 无法连接设备, 请重新输入
        goto INPUT_IP
    )
    call :connect_device %device_ip% %device_port%
    if "!connect_success!"=="true" (
        cls
        echo 连接成功, 设备已连接
        goto SCRCPY_START
    ) else (
        cls
        echo IP地址有误, 无法连接到设备, 请重新输入
        goto INPUT_IP
    )
)

for /f "tokens=1,2 delims=:" %%a in ("%user_input%") do (
    set "device_ip=%%a"
    set "device_port=%%b"
)
REM 去除 device_ip, device_port 后面的多余空
set "device_ip=%device_ip: =%"
set "device_port=%device_port: =%"

if not defined device_ip (
    echo 无效的IP地址和端口
    pause
    exit /b
)
call :connect_device %device_ip% %device_port%
if "!connect_success!"=="true" (
    echo 设备已连接
    goto SCRCPY_START
) else (
    echo ip地址有误, 无法连接到设备
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
    ) else if "!output!"=="cannot connect to %device_ip%:%device_port%: 由于连接方在一段时间后没有正确答复或连接的主机没有反应, 连接尝试失败。 (10060)" (
        set "connect_success=false"
    )
)
exit /b

:SCRCPY_START
echo 正在保存最新IP与端口到本地配置...
echo %device_ip%:%device_port%>ip_config.ini
powershell -window minimized -command ""
scrcpy -e %com_str_set% %ip_streaming_set%
if errorlevel 1 (
    echo scrcpy 启动失败
    normal -window minimized -command ""
    pause
    exit /b
)
exit