@echo off
chcp 65001 >nul
title Scrcpy quick start demonstration
setlocal enabledelayedexpansion

REM 默认参数
REM 1:投屏模式 2:音频模式 3:应用模式
REM 4:ADB服务 5:使用自定义参数 6:退出
set actMode=1

REM 连接模式
REM 1:USB模式 2:IP模式 3:退出
set conMode=2

REM 自定义参数
set customParam=

call .\scrcpy_start_cn.bat

pause
exit /b