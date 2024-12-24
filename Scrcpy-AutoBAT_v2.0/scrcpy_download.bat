chcp 65001 >nul
@echo off
setlocal

if not exist scrcpy-win64-v3.1 (
REM 下载scrcpy-win64-v3.1.zip
powershell wget -Uri https://github.com/Genymobile/scrcpy/releases/download/v3.1/scrcpy-win64-v3.1.zip -OutFile "scrcpy-win64-v3.1.zip"
)

REM 检查下载是否成功
if exist "scrcpy-win64-v3.1.zip" (
    echo 下载成功
) else (
    echo 下载失败
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