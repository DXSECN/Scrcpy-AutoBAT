@echo off
chcp 65001 >nul
title Scrcpy Quick Start Demonstration
setlocal enabledelayedexpansion

REM Default parameters
REM 1: Normal Mode 2: Audio Mode 3: App Mode
REM 4: ADB servicer 5: Only use custom parameters 6: Exit
set actMode=1

REM Connection Mode
REM 1: USB Mode 2: IP Mode 3: Exit
set conMode=2

REM Custom Parameters
set customParam=

call scrcpy_start_cn.bat

pause
exit /b