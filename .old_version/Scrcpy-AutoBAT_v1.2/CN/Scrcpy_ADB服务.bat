@echo off
chcp 65001 >nul
title Scrcpy 重启服务

:INPUT_MODE
echo 请输入执行模式(1:重启服务, 2:关闭服务, 3:打开服务)
set /p "user_input_mode=MODE "
cls
if "%user_input_mode%"=="1" (
    echo 重启服务中...
    .\adb kill-server
    .\adb start-server
    if errorlevel 1 (
        echo 重启服务失败
        pause
        exit /b
    )
    cls
    echo 重启服务成功
    goto end

) else if "%user_input_mode%"=="2" (
    echo 停止服务中...
    .\adb kill-server
    if errorlevel 1 (
        echo 停止服务失败
        pause
        exit /b
    )
    cls
    echo 服务已停止
    goto end

) else if("%user_input_mode%"=="3" (
    echo 启动服务中...
    .\adb start-server
    if errorlevel 1 (
        echo 启动服务失败
        pause
        exit /b
    )
    cls
    echo 启动服务成功
    goto end

) else if "%user_input_mode%"=="end" (
    exit

) else if "%user_input%"=="END" (
    exit

) else (
    echo 无效输入
    goto INPUT_MODE
)

REM 重启ADB服务
echo 重启ADB服务
.\adb kill-server
.\adb start-server
if errorlevel 1 (
    echo 重启ADB服务失败
    pause
    exit /b
)
cls
echo 重启ADB成功


:end
pause
exit