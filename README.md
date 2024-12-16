# Scrcpy 脚本（等待中）
## 中文 | [English](README_EN.MD)
## 1. 安装
下载 [Scrcpy](https://github.com/Genymobile/scrcpy) 最新版，并解压。

将BAT文件复制到scrcpy目录下。


## 2. 使用

选择你需要的BAT执行模式，并打开对应的BAT文件

### 传声模式
只传输声音，选中 Scrcpy 窗口可以通过键鼠控制设备，按win键弹出开始菜单可返回PC。

若不希望鼠标控制，则可以编辑bat脚本，在设置参数后方选择性删除 -KMG 里的字母：
>-K （keyboard）键盘\
>-M （mouse）鼠标\
>-G （gamepad）手柄

### 投屏模式

常规镜像投屏模式。

### 窗口模式

此模式由新版 Scrcpy 支持。该模式可以在电脑中新建独立窗口以独立使用 APP 应用，而非镜像手机屏幕。该模式下，手机屏幕显示内容与电脑映射的手机内容是分开的。

但如果在不同窗口中同时打开相同的 APP 应用，则可能会导致部分窗口出错无法正常运行。

注意，该功能可能需要依赖于第三方启动器软件的支持。默认为 [Fossify](https://github.com/FossifyOrg/Launcher) 开源安卓启动器。若需要更换，则可以自行修改脚本参数。

>--start-app=org.fossify.home

将等号后面的参数修改为对应启动器的包名。

## 3. 配置

详细内容参考 https://github.com/Genymobile/scrcpy/tree/master/doc

这里简单解释一些常用的参数
