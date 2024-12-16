# Scrcpy 脚本 
## 1. 简介 中文 | [English](README_EN.MD)
对于大部分人来说，QtScrcpy 等其他 GUI 版本的选择可能会是更好的选择。\
但这些 GUI 版本，通常更新慢于官方版本。\
例如2024年12月10号，Scrcpy 3.1 更新了虚拟屏幕使用，而 QtScrcpy 暂时更新至基于 Scrcpy 3.0.2 。
因此，我希望能够用简单的 BAT 来让 Scrcpy 的最新版本也可以随时能够正常使用。不依赖于 Scrcpy_GUI 版本的更新。
本人非计算机专业，文件提供对象，是对有 Scrcpy 需求的非程序员用户。如果代码存在问题，欢迎致电邮箱 Paxsomnium@outlook.com 或在 issue 中提出。

## 2. 安装
下载 [Scrcpy](https://github.com/Genymobile/scrcpy) 最新版，并解压。

将BAT文件复制到scrcpy目录下。


## 3. 使用

选择你需要的BAT执行模式，并打开对应的BAT文件

### Scrcpy_模式选择.bat
打开此BAT后进入模式选择模式，此模式下可以调用其他BAT以进行不同参数状态下的Scrcpy。后续我会考虑优化为一个文件。

### USB 直连 / IP 模式
在 BAT 脚本运行过程中，会提示输入模式选择。 \
可选 USB 直连或者通过网络 IP 进行连接。

如果选择 IP 模式，则会优先自动用 USB 调试获取 IP 地址进行连接。\
如果该过程失败则会提示手动输入 IP 地址及端口。

### Scrcpy_传声模式.bat
只传输声音，选中 Scrcpy 窗口可以通过键鼠控制设备，按win键弹出开始菜单可返回PC。

若不希望鼠标控制，则可以编辑bat脚本，在设置参数后方选择性删除 -KMG 里的字母：
>-K （keyboard）键盘 \
>-M （mouse）鼠标 \
>-G （gamepad）手柄

### Scrcpy_投屏模式.bat

常规镜像投屏模式。

### Scrcpy_窗口模式.bat

此模式由 Scrcpy_v3.02+ 支持。该模式可以在电脑中新建独立窗口以独立使用 APP 应用，而非镜像手机屏幕。该模式下，手机屏幕显示内容与电脑映射的手机内容是分开的。

但如果在不同窗口中同时打开相同的 APP 应用，则可能会导致部分窗口出错无法正常运行。

注意，该功能可能需要依赖于第三方启动器软件的支持。默认为 [Fossify](https://github.com/FossifyOrg/Launcher) 开源安卓启动器。若需要更换，则可以自行修改脚本参数。

>--start-app=org.fossify.home

将等号后面的参数修改为对应启动器的包名。

### 快捷键

详细请参考 [Scrcpy 快捷键](https://github.com/Genymobile/scrcpy/blob/master/doc/shortcuts.md)

## 4. 配置

这里简单解释我在各模式默认添加的默认参数 \
详细内容参考 [Scrcpy 说明文档](https://github.com/Genymobile/scrcpy/tree/master/doc)

需要注意的是，USB模式和IP我设置了不同参数 \
通常情况下USB模式参数设置得会更高

### 控制
```
-KMG 键盘鼠标手柄都接入
-K （--keyboard）键盘
-M （--mouse）鼠标
-G （gamepad）手柄
```

### 视频
传输速率限制为20Mbps，第二种为缩写模式。
```bash
--video-bit-rate=20M
```
```bash
-b 20M
```
最大分辨率限制为1920，另一与设备屏幕等比例。
```bash
--max-size=1920
```
```
-m 1920
```
最大帧率 60FPS
```bash
--max-fps=60
```
视频编码格式，可选 **h264 | h265 | av1**
```bash
--video-codec=h264
```
视频缓存大小限制为50，更小的值可以获得更低的延迟，更高的值则会让画面更稳定
```bash
--video-buffer=50
```
禁用视频。
```bash
--no-video
```

### 音频
音频码率设定为128Kbps。
```
--audio-bit-rate=128k 
```
音频编码格式，可选 **opus | aac | flac | raw**
```
--audio-codec=opus
```
音频缓存大小限制为50，更小的值可以获得更低的延迟，更高的值则会让画面更稳定。
```
--audio-buffer=50
```
禁用音频
```
--no-audio
```

### 窗口模式

启动器为 Fossify
```
--start-app=org.fossify.home
```
新建显示器，分辨率为 864x1920。不填写分辨率则以设备默认分辨率启动。
```
--new-display=864x1920
--new-display
```
不现实原生画面，可以稍微降低一点性能开销。可选项，默认关闭。
```
--no-vd-system-decorations
```

## 5. 鸣谢
>[Scrcpy](https://github.com/Genymobile/scrcpy) \
>[Fossify](https://github.com/FossifyOrg/Launcher)
