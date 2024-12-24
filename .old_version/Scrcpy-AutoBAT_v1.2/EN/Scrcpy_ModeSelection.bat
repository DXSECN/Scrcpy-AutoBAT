@echo off
chcp 65001 >nul
title Scrcpy Mode Selection
cd /d %~dp0

:INPUT_MODE
echo Please enter the execution mode (1: Mirror Mode, 2: Audio Mode, 3: Window Mode, 4: ADB Service, 5: Exit)
set /p "user_input_mode=MODE "
cls
if "%user_input_mode%"=="1" (
    echo Mirror Mode
    call .\Scrcpy_MirrorMode.bat
) else if "%user_input_mode%"=="2" (
    echo Audio Mode
    call .\Scrcpy_AudioMode.bat
) else if "%user_input_mode%"=="3" (
    echo Window Mode
    call .\Scrcpy_WindowMode.bat
) else if "%user_input_mode%"=="4" (
    echo ADB Service
    call .\Scrcpy_ADBServer.bat
) else if "%user_input_mode%"=="5" (
    exit
) else (
    echo Invalid input
    goto INPUT_MODE
)
pause
exit