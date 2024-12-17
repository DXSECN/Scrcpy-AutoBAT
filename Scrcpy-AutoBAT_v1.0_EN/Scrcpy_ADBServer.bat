@echo off
chcp 65001 >nul
title Restart Scrcpy ADB-Server

:INPUT_MODE
echo Please enter the execution mode (1: Restart ADB-Server, 2: Stop ADB-Server, 3: Start ADB-Server)
set /p "user_input_mode=MODE "
cls
if "%user_input_mode%"=="1" (
    echo Restarting ADB-Server...
    .\adb kill-server
    .\adb start-server
    if errorlevel 1 (
        echo Failed to restart ADB-Server
        pause
        exit /b
    )
    cls
    echo ADB-Server restarted successfully
    goto end

) else if "%user_input_mode%"=="2" (
    echo Stopping ADB-Server...
    .\adb kill-server
    if errorlevel 1 (
        echo Failed to stop ADB-Server
        pause
        exit /b
    )
    cls
    echo ADB-Server stopped
    goto end

) else if "%user_input_mode%"=="3" (
    echo Starting ADB-Server...
    .\adb start-server
    if errorlevel 1 (
        echo Failed to start ADB-Server
        pause
        exit /b
    )
    cls
    echo ADB-Server started successfully
    goto end

) else if "%user_input_mode%"=="end" (
    exit

) else if "%user_input%"=="END" (
    exit

) else (
    echo Invalid input
    goto INPUT_MODE
)

REM Restart ADB-Server
echo Restarting ADB-Server
.\adb kill-server
.\adb start-server
if errorlevel 1 (
    echo Failed to restart ADB-Server
    pause
    exit /b
)
cls
echo ADB-Server restarted successfully

:end
pause
exit