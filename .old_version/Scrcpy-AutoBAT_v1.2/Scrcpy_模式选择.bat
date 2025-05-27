@echo off
chcp 65001 >nul
title Scrcpy 模式选择
cd /d %~dp0

:INPUT_MODE
echo 请输入执行模式 (1:投屏模式, 2:传声模式, 3:窗口模式, 4: ADB服务, 5:退出)
set /p "user_input_mode=MODE "
cls
if "%user_input_mode%"=="1" (
    echo 投屏模式
    call .\Scrcpy_投屏模式.bat
) else if "%user_input_mode%"=="2" (
    echo 传声模式
    call .\Scrcpy_传声模式.bat
) else if "%user_input_mode%"=="3" (
    echo 窗口模式
    call .\Scrcpy_窗口模式.bat
) else if "%user_input_mode%"=="4" (
    echo 窗口模式
    call .\Scrcpy_ADB服务.bat
) else if "%user_input_mode%"=="5" (
    exit
) else (
    echo 无效输入
    goto INPUT_MODE
)
pause
exit