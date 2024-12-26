@echo off
chcp 65001 >nul
title Scrcpy-AutoBAT-v2.1 based on scrcpy v3.1
setlocal enabledelayedexpansion

REM 定义脚本目录
set "script_dir=%~dp0\scrcpy_core"
cd /d "%script_dir%"

:RESTART

REM 定义初始参数
REM [NORM_SET]
set screen_off_timeout=300
set shortcut_mod=lalt
set resolution=864x1920
set max_size=1920
set app_start_num=1
set custom_param=
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

REM 检查scrcpy_core文件夹是否存在，如果不存在则尝试下载
if not exist "%~dp0\scrcpy_core" (
    echo 按键任意键后开始尝试下载scrcpy_core
    call :SCRCPY_DOWNLOAD
    pause
    cls
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

REM 检测或选择启动模式
:ACTION_MODE
if defined actMode (
    set act_mode=%actMode%
    goto :ACTION
)


:ACTION_INPUT
echo 请输入执行模式:
echo -----------------------------------
echo 1:投屏模式 2:传声模式 3:窗口模式 
echo 4:ADB服务 5:使用自定义参数 6:退出
echo -----------------------------------
set /p "act_mode=MODE "
:ACTION
cls
if "%act_mode%"=="1" (
    echo 已选择: 投屏模式
    set com_mode= -KG --stay-awake
) else if "%act_mode%"=="2" (
    echo 已选择: 音频模式
    set com_mode= --no-window
) else if "%act_mode%"=="3" (
    echo 已选择: 应用模式
    set com_mode= -KG --stay-awake
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
    echo 无效输入
    goto :ACTION_INPUT
)


REM 检测或选择连接模式
:CONNECTION_MODE
if defined conMode (
    set con_mode=%conMode%
    goto :CONNECTION
)
:CONNECTION_INPUT
echo 请输入执行模式:
echo -----------------------------------
echo 1:USB模式, 2:IP模式, 3:返回, 4:退出
echo -----------------------------------
set /p "con_mode=MODE "
cls
:CONNECTION
if "%con_mode%"=="1" (
    echo 进入USB模式
    cls
    goto :MODE_USB
) else if "%con_mode%"=="2" (
    echo 进入IP模式
    cls
    goto :MODE_TRS
) else if "%con_mode%"=="3" (
    goto :ACTION_MODE
) else if "%con_mode%"=="4" (
    exit
) else (
    echo 无效输入
    goto :CONNECTION_INPUT
)


::------------------------------------------------------------------------------
:MODE_TRS
REM 自动检测设备ID
for /f "skip=1 tokens=1" %%i in ('adb devices') do (
    set device_id=%%i
    REM 如果当前行为空，跳过
    if "!device_id!"=="" (
        goto :MODE_INI
    )
)

echo 检测到设备ID: !device_id!

REM 获取设备 IP 地址
echo 正在获取设备 IP 地址...
for /f "tokens=9" %%a in ('adb -s %device_id% shell ip route ^| findstr "wlan0"') do set device_ip=%%a

if "%device_ip%"=="" (
    echo 未找到 WIFI 的 IP 地址
    goto :MODE_INI
)

echo 自动检测到 IP 地址: %device_ip%

REM 设置 TCP/IP 模式
echo 正在设置设备为 TCP/IP 模式...
adb -s %device_id% tcpip 5555
if errorlevel 1 (
    echo TCP/IP 模式设置失败
    goto :MODE_INI
)

echo TCP/IP 模式已成功设置, 端口: 5555

REM 连接设备
echo 正在通过 Wi-Fi 连接设备...
adb connect %device_ip%:5555
if errorlevel 1 (
    echo 设备连接 Wi-Fi 调试失败
    goto :MODE_INI
) else (
echo 已成功连接到设备 %device_ip%:5555
if not "%device_ip%"=="" (set device_ip=%device_ip%)
set device_port=5555
)
goto :SCRCPY_START


:MODE_INI
if defined deviceIP (
    echo 检测到IP本地配置
    if defined deviceIP (set "device_ip=%deviceIP%")
    if defined devicePort (set "device_port=%devicePort%")
    if "%device_ip%"=="" (
        goto :INPUT_IP
    )

    call :connect_device %device_ip% %device_port%

    if "!connect_success!"=="true" (
        echo 连接成功, 设备已连接
        goto SCRCPY_START
    ) else (
        goto :INPUT_IP
    )
) else (
    echo 未检测到IP本地配置
    goto :INPUT_IP
)



:INPUT_IP
echo 请输入设备的IP地址和端口:
echo ----------------------------------------------------------------
echo 输入usb返回USB直连, 输入ip则会重新尝试自动获取IP地址, 输入end退出,
echo 不输入直接回车, 则使用已保存的IP地址: %device_ip%:%device_port%
echo ----------------------------------------------------------------
set /p "user_input=IP: "


REM 特殊命令处理
if "%user_input%"=="usb" (
    echo 重新尝试USB调试
    goto :MODE_USB
) else if "%user_input%"=="USB" (
    echo 重新尝试USB调试
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
    echo 正在使用当前地址: %device_ip%:%device_port%
    echo 加载中。。。
    if "%device_ip%"=="" (
        cls
        echo 当前地址为空, 无法连接设备, 请重新输入
        goto :INPUT_IP
    )
    call :connect_device %device_ip% %device_port%
    if "!connect_success!"=="true" (
        cls
        echo 连接成功, 设备已连接
        goto :SCRCPY_START
    ) else (
        cls
        echo IP地址有误, 无法连接到设备, 请重新输入
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
    echo 无效的IP地址和端口
    goto :INPUT_IP
)
call :connect_device %device_ip% %device_port%
if "!connect_success!"=="true" (
    echo 设备已连接
    goto :SCRCPY_START
) else (
    echo ip地址有误, 无法连接到设备
    goto :INPUT_IP
)


:SCRCPY_START
REM 参数合成
echo 保存配置文件中...
call :CONFIG_SAVE

if "%act_mode%"=="1" (
set "com_str_set= --screen-off-timeout=%screen_off_timeout%  --max-size=%max_size% --shortcut-mod=%shortcut_mod%"
) else if "%act_mode%"=="2" (
    set "com_str_set= --screen-off-timeout=%screen_off_timeout%  --max-size=%max_size% --shortcut-mod=%shortcut_mod%"
) else if "%act_mode%"=="3" (
    set "com_str_set= --screen-off-timeout=%screen_off_timeout%  --max-size=%max_size% --shortcut-mod=%shortcut_mod%" --start-app=%selected_app% %new_display%
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




echo IP: %device_ip%:%device_port%
if "%connect_mode%"=="1" (
    set connect_mode= -d
) else if "%con_mode%"=="2" (
    set connect_mode= --serial=%device_ip%:%device_port%
) else (
    echo 无效的连接模式
    pause
    exit /b
)
echo ------------------------------------------------------------------------
echo scrcpy%com_mode%%connect_mode%%com_str_set%%str_set%%custom_param%
echo ------------------------------------------------------------------------
powershell -window minimized -command ""
scrcpy%com_mode%%connect_mode%%com_str_set%%str_set%%custom_param%
if errorlevel 1 (
    echo scrcpy 启动失败
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


REM ---------------------------------------------------------------------
:CONFIG_SAVE
REM 设置输出 ini 文件路径（覆盖原文件）
set "output_ini=%~dp0config.ini"

REM 备份原始 config.ini 文件
copy /y "%ini_file%" %~dp0"config_bak" >nul
if errorlevel 1 (
    echo 警告: 无法备份 %ini_file%
) else (
    echo 已创建配置文件备份为 config_backup.ini
)

REM 开始写入新的 config.ini 文件
REM 使用括号组确保一次性重定向所有输出
(
    REM 写入 [NORM_SET] 部分
    echo [NORM_SET]
    echo screen_off_timeout=%screen_off_timeout%
    echo shortcut_mod=%shortcut_mod%
    echo resolution=%resolution%
    echo max_size=%max_size%
    echo app_start_num=%app_start_num%
    echo custom_param=%custom_param%

    REM 写入 [CONN_SET] 部分
    echo [CONN_SET]
    echo device_ip=%device_ip%
    echo device_port=%device_port%

    REM 写入 [USB_SET] 部分
    echo [USB_SET]
    echo usb_video_codec=%usb_video_codec%
    echo usb_video_buffer=%usb_video_buffer%
    echo usb_max_fps=%usb_max_fps%
    echo usb_audio_codec=%usb_audio_codec%
    echo usb_audio_buffer=%usb_audio_buffer%

    REM 写入 [IP_SET] 部分
    echo [IP_SET]
    echo ip_video_codec=%ip_video_codec%
    echo ip_video_buffer=%ip_video_buffer%
    echo ip_max_fps=%ip_max_fps%
    echo ip_audio_codec=%ip_audio_codec%
    echo ip_audio_buffer=%ip_audio_buffer%

    REM 写入 [APP_List] 部分
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

    REM 写入 [END] 部分（如果需要）
    echo [END]
) > "%output_ini%"

echo 配置文件保存成功...
endlocal
exit /b


REM -------------------------------------------------------------
:CONFIG_LOAD
REM 设置 ini 文件路径
set "ini_file=%~dp0config.ini"

REM 逐行读取 ini 文件
for /f "usebackq tokens=* delims=" %%a in ("%ini_file%") do (
    set "line=%%a"
    
    REM 去除行首和行尾的空格
    call :trim line line_trimmed
    
    REM 跳过空行和注释
    if not "!line_trimmed!"=="" (
        set "first_char=!line_trimmed:~0,1!"
        if not "!first_char!"=="[" (
            if not "!first_char!"==";" (
                REM 检查是否包含等号 =
                echo "!line_trimmed!" | find "=" >nul
                if not errorlevel 1 (
                    REM 分割成键和值
                    for /f "tokens=1,* delims==" %%b in ("!line_trimmed!") do (
                        set "key=%%b"
                        set "value=%%c"
                        
                        REM 去除键和值前后的空格
                        call :trim key key_trimmed
                        call :trim value value_trimmed
                        
                        REM 设置变量，变量名为键
                        set "!key_trimmed!=!value_trimmed!"
                    )
                )
            )
        )
    )
)

exit /b


REM 子程序：修剪变量中前后的空格
:trim
    set "string=!%1!"
    REM 去除左边空格
    for /f "tokens=* delims= " %%x in ("!string!") do set "string=%%x"
    REM 去除右边空格
    :loop
    if "!string:~-1!"==" " (
        set "string=!string:~0,-1!"
        goto loop
    )
    set "%2=!string!"

exit /b


REM ---------------------------------------------------------------------------
:APP_CHOICE
REM 清空屏幕
cls

REM 遍历 App_1 到 App_9 和 App_0 并显示非空的应用程序选项
echo 可用的应用程序列表：
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
    echo 没有可用的应用程序选项。
    pause
    exit /b
)

REM 提示用户输入应用序号
echo 请输入要启动的应用序号(0-9)，直接按回车不选，则启动默认应用 %app_start_num%
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
        echo 即将启动应用：!selected_app!
        set app_start_num=%app_input_choice%
        exit /b
    ) else (
        echo 无效的选择，没有找到对应的应用。
        pause
        goto :APP_CHOICE
    )
) else (
    echo 输入无效，请输入 0-9 的数字。
    pause
    goto :APP_CHOICE
)

exit /b


REM --------------------------------------------------------------------------
REM ADB服务
:ADB_MODE
cd /d %script_dir%
if not defined adbMode (
    set adb_mode=%adbMode%
echo 请输入需要的ADB命令
echo ----------------------------------------------------
echo 1:重启ADB服务, 2:关闭ADB服务, 3:打开ADB服务, 4:退出
echo ----------------------------------------------------
set /p "adb_mode=MODE "
)
cls

if "%adb_mode%"=="1" (
    echo 重启服务中...
    adb kill-server
    adb start-server
    if errorlevel 1 (
        echo 重启服务失败
        pause
        exit /b
    )
    cls
    echo 重启服务成功
    goto :RESTART

) else if "%adb_mode%"=="2" (
    echo 停止服务中...
    adb kill-server
    if errorlevel 1 (
        echo 停止服务失败
        pause
        exit /b
    )
    cls
    echo 服务已停止
    pause
    exit

) else if "%adb_mode%"=="3" (
    echo 启动服务中...
    adb start-server
    if errorlevel 1 (
        echo 启动服务失败
        pause
        exit /b
    )
    cls
    echo 启动服务成功
    goto :RESTART

) else if "%adb_mode%"=="4" (
    exit

) else (
    echo 无效输入
    goto ADB_MODE
)

exit /b


:SCRCPY_DOWNLOAD
if exist scrcpy_core (exit /b)
if not exist scrcpy-win64-v3.1.zip (
REM 下载scrcpy-win64-v3.1.zip
powershell wget -Uri https://github.com/Genymobile/scrcpy/releases/download/v3.1/scrcpy-win64-v3.1.zip -OutFile "scrcpy-win64-v3.1.zip"
)

REM 检查下载是否成功
if exist "scrcpy-win64-v3.1.zip" (
    echo 压缩包下载成功
) else (
    echo 压缩包下载失败
    pause
    exit /b
)

REM 解压缩文件到当前目录
powershell -command "Expand-Archive -Path 'scrcpy-win64-v3.1.zip' -DestinationPath '.'"

REM 检查解压缩是否成功
if exist "scrcpy-win64-v3.1.zip" (

    REM 将解压后的目录重命名为 scrcpy_core
    ren scrcpy-win64-v3.1 scrcpy_core

    REM 删除压缩包
    del scrcpy-win64-v3.1.zip

    echo 解压缩并重命名成功，压缩包已删除
    timeout /t 3
    exit /b
) else (
    echo 解压缩失败
    pause
    exit /b
)
pause
exit /b
