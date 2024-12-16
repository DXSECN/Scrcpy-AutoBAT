# Scrcpy Script
## 1. Introduction [中文](README.md) | English
For most people, GUI versions like QtScrcpy might be a better choice.\
However, these GUI versions are often updated more slowly than the official version.\
For example, on December 10, 2024, Scrcpy 3.1 was updated to support virtual screen usage, while QtScrcpy is still based on Scrcpy 3.0.2.
Therefore, I hope to use a simple BAT script to ensure that the latest version of Scrcpy can always be used without relying on updates from Scrcpy_GUI versions.
I am not a computer science professional, and this file is intended for non-programmer users who need Scrcpy. If there are any issues with the code, please contact me at Paxsomnium@outlook.com or raise an issue.\
The English version is translated by AI. The Chinese version shall prevail.

## 2. Installation
Download the [latest version of Scrcpy](https://github.com/Genymobile/scrcpy) and extract it.

Copy the BAT files to the Scrcpy directory.

## 3. Usage

Choose the BAT execution mode you need and open the corresponding BAT file.

### Scrcpy_Mode_Selection.bat
Opening this BAT will enter the mode selection mode, where other BAT scripts can be called to run Scrcpy with different parameters. In the future, I plan to optimize this into a single file.

### USB Direct Connection / IP Mode
During the execution of the BAT script, you will be prompted to select the connection mode. \
You can choose between USB direct connection or network IP connection.

If you choose IP mode, it will first attempt to automatically obtain the IP address via USB debugging. \
If this process fails, you will be prompted to manually enter the IP address and port.

### Scrcpy_Audio_Transmission_Mode.bat
This mode only transmits audio. When the Scrcpy window is selected, you can control the device using the keyboard and mouse. Press the Win key to bring up the Start menu and return to the PC.

If you do not want mouse control, you can edit the BAT script and selectively remove letters from `-KMG`:
>-K (keyboard) \
>-M (mouse) \
>-G (gamepad)

### Scrcpy_Screen_Mirroring_Mode.bat
This is the standard screen mirroring mode.

### Scrcpy_Window_Mode.bat
This mode is supported by Scrcpy v3.02+. It creates independent windows on your computer to use apps independently, rather than mirroring the phone screen. In this mode, the content displayed on the phone screen and the content mirrored on the computer are separate.

However, opening the same app in multiple windows simultaneously may cause some windows to fail to run correctly.

Note: This feature may require support from a third-party launcher app. The default is the open-source Android launcher [Fossify](https://github.com/FossifyOrg/Launcher). If you need to change it, you can modify the script parameter.
```bash
--start-app=org.fossify.home
```
Replace the package name after the equals sign with the package name of the desired launcher.

### Shortcuts
For details, refer to the [Scrcpy shortcuts](https://github.com/Genymobile/scrcpy/blob/master/doc/shortcuts.md).

## 4. Configuration

Here is a brief explanation of the default parameters I added for each mode. \
For detailed information, refer to the [Scrcpy documentation](https://github.com/Genymobile/scrcpy/tree/master/doc).

Note that different parameters are set for USB mode and IP mode. \
Typically, higher parameters are set for USB mode.

### Control
```bash
-KMG Enable keyboard, mouse, and gamepad
-K (--keyboard) Enable keyboard
-M (--mouse) Enable mouse
-G (gamepad) Enable gamepad
```

### Video
Set the video bit rate to 20 Mbps. The second format is a shorthand.
```bash
--video-bit-rate=20M
```
```bash
-b 20M
```
Set the maximum resolution to 1920, or maintain the aspect ratio of the device screen.
```bash
--max-size=1920
```
```bash
-m 1920
```
Set the maximum frame rate to 60 FPS.
```bash
--max-fps=60
```
Set the video codec to **h264 | h265 | av1**
```bash
--video-codec=h264
```
Set the video buffer size to 50. A smaller value provides lower latency, while a larger value ensures smoother video.
```bash
--video-buffer=50
```
Disable video.
```bash
--no-video
```

### Audio
Set the audio bit rate to 128 Kbps.
```bash
--audio-bit-rate=128k
```
Set the audio codec to **opus | aac | flac | raw**
```bash
--audio-codec=opus
```
Set the audio buffer size to 50. A smaller value provides lower latency, while a larger value ensures smoother audio.
```bash
--audio-buffer=50
```
Disable audio.
```bash
--no-audio
```

### Window Mode

Use the Fossify launcher.
```bash
--start-app=org.fossify.home
```
Create a new display with a resolution of 864x1920. If no resolution is specified, the device's default resolution is used.
```bash
--new-display=864x1920
--new-display
```
Not showing the native display, which can slightly reduce performance overhead. Optional, disabled by default.
```bash
--no-vd-system-decorations
```

## 5. Acknowledgments
>[Scrcpy](https://github.com/Genymobile/scrcpy) \
>[Fossify](https://github.com/FossifyOrg/Launcher)
