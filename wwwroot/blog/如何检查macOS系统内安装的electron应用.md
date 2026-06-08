---
title: 如何检查 macOS 系统内安装的 Electron 应用
---

# 如何检查 macOS 系统内安装的 Electron 应用

最近清理电脑时，我突然好奇：我的 macOS 里到底装了多少个 Electron 应用？比如 VSCode、Slack、Notion 这些看起来"不一样"的软件，背后其实都是 Electron 写的。

这篇文章就教大家如何找出系统中所有由 Electron 构建的应用程序，顺便也能查出所有"内置了浏览器"的应用（CEF、Chrome、QtWebEngine 等）。

## 什么是 Electron / 内置浏览器的应用？

简单来说，**Electron** 是一个用 Web 技术开发桌面应用的框架。它把 Chromium 和 Node.js 打包在一起，外面看是个原生 App，骨子里其实是个浏览器。

类似的"内置浏览器"技术还有：

| 技术 | 引擎 | 典型应用 |
|------|------|----------|
| Electron | Chromium | VSCode、Slack、Notion、Discord |
| CEF（Chromium Embedded Framework） | Chromium | 剪映专业版、Spotify、Steam |
| Qt WebEngine | Chromium | WPS、OBS 等跨平台应用 |
| WebKit | WebKit | 各种带"在线预览"的小工具 |

> **共同点**：都把一个完整的浏览器引擎塞进了自己的 `.app` 包里。

## 核心检测方法：`find -name`

这些应用有个共同特征——它们的 `.app` 包里都会带一个**特征 framework**。所以检测的核心思路就是：

```bash
find /Applications -name "<特征 framework 名>" -type d 2>/dev/null
```

> macOS 绝大多数应用都装在 `/Applications` 下，找到 framework 就能反推出应用。

下面是常见的 framework 名和对应的引擎：

| Framework 名 | 引擎 |
|--------------|------|
| `Electron Framework.framework` | Electron |
| `Chromium Embedded Framework.framework` | CEF |
| `Google Chrome Framework.framework` | Chrome |
| `Chromium Framework.framework` | Chromium |
| `QtWebEngineCore.framework` / `QtWebEngine.framework` | Qt WebEngine |
| `WebKit.framework` / `WebKit2.framework` | WebKit |
| `MozillaFirefox.framework` / `Gecko.framework` | Firefox |
| `nwjs.framework` | NW.js |

### 几个常用示例

**找出所有 Electron 应用：**

```bash
find /Applications -name "Electron Framework.framework" -type d 2>/dev/null
```

**找出所有 Chromium 应用：**

```bash
find /Applications -name "Chromium Framework.framework" -type d 2>/dev/null
```

## 深度排查：用 `otool` 看单个应用

`otool` 是 macOS 自带的工具，可以看应用到底链接了哪些 framework。当你不确定某个应用是不是"套壳浏览器"时，用它最准确。


## 使用otool实现的完整可运行的扫描脚本

如果你懒得一行一行敲命令，可以直接用下面这个**完整脚本**。它会自动扫描常见位置、检测 18 种浏览器引擎，并输出应用名、版本、占用空间、bundle id 等详细信息。

脚本地址：
[https://codemyhappy.github.io/static/macshell/detect_browser_apps.sh](https://codemyhappy.github.io/static/macshell/detect_browser_apps.sh)


### 使用方法

```bash
chmod +x detect_browser_apps.sh
./detect_browser_apps.sh              # 标准扫描
./detect_browser_apps.sh --full       # 深度扫描
./detect_browser_apps.sh --deep       # 全用户主目录扫描
./detect_browser_apps.sh --json > out.json   # 导出 JSON
./detect_browser_apps.sh --csv > out.csv     # 导出 CSV
```

### 小贴士

- 在 **`--deep`** 模式下会扫 `users/` 下的所有用户目录，可能需要 1-3 分钟
- 脚本不会修改系统任何文件，**完全只读**，可以放心运行

到这里，本文就结束了。希望对你有帮助！
