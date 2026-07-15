---
title: macOS 应用自启动开发和自查
---

# macOS 应用自启动开发和自查

最近在写一个常驻后台的小工具，需要让它在用户登录后自动启动。研究了一圈才发现，macOS 上的"自启动"远不止"拖进登录项"这么简单——它有一整套分层的启动机制，而且不同方法适用的场景、权限、沙盒限制完全不同。

这篇文章分两部分：

1. **开发篇**：覆盖 macOS 上所有能让 App 自启动的开发方法，并附上官方技术文档链接。
2. **自查篇**：针对每一种方法，告诉你如何把系统里所有"偷偷自启动"的 App 揪出来。

---

## 一、macOS 自启动机制总览

macOS 的启动项按"运行时机"和"运行身份"可以分成几大类：

| 机制 | 运行时机 | 运行身份 | 典型用途 | 是否推荐 |
|------|----------|----------|----------|----------|
| **Launch Agent / Daemon**（launchd plist） | 登录后 / 开机后 | 用户 / root | 后台服务、常驻进程 | ✅ 官方主推 |
| **Login Items（登录项）** | 用户登录时 | 当前用户 | 普通 App 随登录启动 | ✅ 推荐 |
| **Background Items（后台项，Ventura+）** | 登录后 | 当前用户 | 需要后台运行但不弹窗的 App | ✅ 新标准 |
| **Login Hook（登录钩子）** | 登录时（shell 脚本） | root | 登录时执行脚本 | ❌ 已废弃 |
| **cron / periodic** | 定时 | 用户 / root | 定时任务脚本 | ⚠️ 脚本级 |

> 简单记忆：**App 想随登录启动 → 用 Login Items / Background Items；想开机就跑（或要 root 权限）→ 用 Launch Daemon；想定时跑 → 用 cron。**

下面逐个展开。

---

## 二、开发篇：让 App 自启动的所有方法

### 方法 1：Launch Agent / Launch Daemon（launchd plist）

这是 macOS 最底层、最正统的启动机制，由系统守护进程 `launchd` 统一管理。几乎所有系统服务、第三方后台工具（Docker、Homebrew 服务、Node 守护进程等）都靠它。

**核心概念：**

- **Launch Agent**：以**当前用户**身份运行，用户登录后才启动。位置：
  - `~/Library/LaunchAgents/` —— 单用户（推荐，无需管理员权限）
  - `/Library/LaunchAgents/` —— 所有用户登录时都启动
- **Launch Daemon**：以 **root** 身份运行，**开机即启动**（不依赖登录）。位置：
  - `/Library/LaunchDaemons/`
  - `/System/Library/LaunchDaemons/`（系统自带，勿动）

**如何开发：**

写一个 `.plist` 配置文件放到对应目录，然后用 `launchctl` 加载即可。

示例 `~/Library/LaunchAgents/com.example.myapp.plist`：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.example.myapp</string>

    <!-- 要启动的可执行文件 -->
    <key>ProgramArguments</key>
    <array>
        <string>/Applications/MyApp.app/Contents/MacOS/MyApp</string>
        <string>--background</string>
    </array>

    <!-- 用户登录后自动加载并启动 -->
    <key>RunAtLoad</key>
    <true/>

    <!-- 进程挂了自动重启 -->
    <key>KeepAlive</key>
    <true/>

    <!-- 标准输出/错误日志 -->
    <key>StandardOutPath</key>
    <string>/tmp/myapp.out.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/myapp.err.log</string>
</dict>
</plist>
```

加载与卸载命令：

```bash
launchctl load ~/Library/LaunchAgents/com.example.myapp.plist   # 旧版
launchctl unload ~/Library/LaunchAgents/com.example.myapp.plist

# macOS 10.10+ 推荐用 bootstrap / enable
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.example.myapp.plist
launchctl bootout   gui/$(id -u)/com.example.myapp
```

> ⚠️ 注意：从 macOS 10.10 起 `load`/`unload` 被标记为废弃，新代码建议用 `bootstrap`/`bootout` 或 `launchctl enable/disable`。但 `load` 在多数版本仍可用。

**技术文档：**

- [Creating Launch Daemons and Agents（Apple 官方）](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)
- [launchd.plist 手册页](https://developer.apple.com/library/archive/documentation/Darwin/Reference/ManPages/man5/launchd.plist.5.html)
- [launchctl 手册页](https://ss64.com/osx/launchctl.html)

---

### 方法 2：Login Items（登录项）

这是给**普通 GUI App** 用的"随登录启动"方式，用户也能在「系统设置 → 通用 → 登录项」里看到并手动增删。

根据 App 是否**沙盒（Sandbox）**，有两种 API：

#### 2.1 沙盒 App：`SMLoginItemSetEnabled`（推荐）

沙盒应用不能直接操作登录项列表，必须借助一个 **Helper（辅助）App**（打包在主 App 的 `Contents/Library/LoginItems/` 里），通过 `ServiceManagement` 框架启用。

```objc
#import <ServiceManagement/ServiceManagement.h>

- (BOOL)enableLoginItem {
    // helper 的 bundle identifier，注意是辅助 App 的 id
    NSString *helperId = @"com.example.myapp.loginhelper";
    if (!SMLoginItemSetEnabled((__bridge CFStringRef)helperId, YES)) {
        NSLog(@"启用登录项失败");
        return NO;
    }
    return YES;
}
```

辅助 App 是一个独立的 `.app`，它唯一的工作就是启动主 App（通常是一个很小的 `NSApplication` + 一段启动主程序的代码）。系统会在用户登录时自动拉起这个 helper，helper 再拉起主 App。

**技术文档：**

- [ServiceManagement 框架（SMLoginItemSetEnabled）](https://developer.apple.com/documentation/servicemanagement/1431087-smloginitemsetenabled)
- [Adding Login Items（Apple 官方指南）](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/LoginItems.html)

#### 2.2 非沙盒 App：`LSSharedFileList`（已废弃但仍可用）

非沙盒应用可以直接往登录项列表里加自己：

```objc
#import <CoreServices/CoreServices.h>

- (void)addLoginItem {
    LSSharedFileListRef loginItems =
        LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    NSURL *appURL = [NSBundle mainBundle].bundleURL;
    LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(
        loginItems, kLSSharedFileListItemLast, NULL, NULL,
        (__bridge CFURLRef)appURL, NULL, NULL);
    if (item) CFRelease(item);
    CFRelease(loginItems);
}
```

> ⚠️ `LSSharedFileList` 在 macOS 10.11 后被标记为 **deprecated**，且对沙盒 App 无效。新项目请优先用 `SMLoginItemSetEnabled`。

**技术文档：**

- [LSSharedFileList 参考（已废弃）](https://developer.apple.com/documentation/coreservices/launch_services?language=objc)

---

### 方法 3：Background Items（后台项，macOS 13 Ventura+）

从 **Ventura (13.0)** 开始，Apple 把"后台运行"单独拎出来做成了隐私权限。任何通过 Launch Agent（`RunAtLoad` 或 `KeepAlive`）在后台运行、且不显示 Dock 图标的 App，都会出现在「系统设置 → 通用 → 登录项」下方的 **"允许在后台"** 列表里，用户可随时关闭。

**开发方式：** 本质上还是写一个 Launch Agent plist（见方法 1），但加上后台运行特征（无 `LSBackgroundOnly` 冲突、不显示 UI）。系统会自动把它归类为 Background Item，并弹窗请求用户授权。

```xml
<!-- 在 Launch Agent 基础上，确保不弹主窗口即可被识别为后台项 -->
<key>RunAtLoad</key>
<true/>
```

**技术文档：**

- [Apple 新闻稿：Ventura 后台项说明](https://developer.apple.com/news/?id=3d2u1x2o)
- [WWDC22：What's new in privacy（后台项部分）](https://developer.apple.com/videos/play/wwdc2022/10033/)
- [Registering a Login Item（含后台项说明）](https://developer.apple.com/documentation/appkit/nsapplication/2967172-registeruserdefaults?language=objc)

---

### 方法 4：Login Hook（登录钩子，已废弃）

这是最古老的方式：在用户登录时让系统执行一个 shell 脚本（以 **root** 身份）。虽然官方已废弃，但在一些老系统或运维脚本里仍能见到。

```bash
# 设置登录钩子（需管理员）
sudo defaults write com.apple.loginwindow LoginHook /path/to/script.sh

# 查看当前登录钩子
sudo defaults read com.apple.loginwindow LoginHook

# 清除
sudo defaults delete com.apple.loginwindow LoginHook
```

> ❌ 不推荐新项目使用，仅作"自查"时排查老机器用。

**技术文档：**

- [Mac OS X Login Hooks（Apple 旧文档）](https://developer.apple.com/library/archive/technotes/tn2228/_index.html)

---

### 方法 5：cron / periodic（脚本级定时自启动）

如果你的"自启动"其实是"定时执行某段逻辑"，`cron` 和 `periodic` 是轻量选择。

**cron（用户级定时任务）：**

```bash
crontab -e          # 编辑当前用户的定时任务
crontab -l          # 列出
# 例如：每天 9 点启动某脚本
# 0 9 * * * /usr/bin/open -a /Applications/MyApp.app
```

**periodic（系统级日/周/月任务）：** 把脚本放到 `/etc/periodic/daily|weekly|monthly/` 即可被系统自动调用。

**技术文档：**

- [crontab 手册页](https://ss64.com/osx/crontab.html)
- [periodic 手册页](https://ss64.com/osx/periodic.html)

---

## 三、自查篇：如何找出系统里所有自启动的 App

开发完，反过来——**你的 Mac 上到底有哪些东西在自启动？** 下面按上面的方法逐一排查。建议全部跑一遍，因为很多流氓软件会同时用多种方式。

### 自查 1：Launch Agent / Daemon（最该查的地方）

```bash
# 当前用户的 Agent
ls ~/Library/LaunchAgents/

# 所有用户的 Agent / Daemon（需管理员）
ls /Library/LaunchAgents/
ls /Library/LaunchDaemons/

# 查看当前已加载的 job（含系统级），重点看 Label 和状态
launchctl list

# 查看某个 job 的详细配置（是否 RunAtLoad / KeepAlive）
launchctl print gui/$(id -u)/com.example.foo
```

> 小技巧：用 `grep -l "RunAtLoad" ~/Library/LaunchAgents/*.plist` 可快速筛出"登录即启动"的项。

### 自查 2：Login Items（登录项）

**图形界面（最直观）：** 打开「系统设置 → 通用 → 登录项」，列表里就是所有随你登录启动的 App，可一键移除。

**命令行（适合脚本/远程排查）：**

```bash
# 非沙盒登录项（LSSharedFileList 写入的）
sfltool dumpbtm | grep -i "login"     # 查看启动数据库
defaults read ~/Library/Preferences/com.apple.loginitems.plist 2>/dev/null

# 沙盒 App 的 helper（在 LoginItems 目录里）
ls /Applications/*/Contents/Library/LoginItems/
```

### 自查 3：Background Items（后台项，Ventura+）

**图形界面：** 「系统设置 → 通用 → 登录项」页面下方 **"允许在后台"** 区域，列出所有后台自启动项。

**命令行：** 后台项本质还是 Launch Agent，用自查 1 的命令即可，重点看那些 `RunAtLoad=true` 且无 UI 的 job。也可以直接看启动数据库：

```bash
sfltool dumpbtm
```

### 自查 4：Login Hook（老机器）

```bash
# 有输出说明存在登录钩子脚本
defaults read com.apple.loginwindow LoginHook
sudo defaults read com.apple.loginwindow LoginHook
```

### 自查 5：cron / periodic

```bash
# 当前用户定时任务
crontab -l

# 系统级
sudo cat /etc/crontab 2>/dev/null
ls /var/at/tabs/ 2>/dev/null          # at 任务
ls /etc/periodic/*/ 2>/dev/null       # 日/周/月脚本
```

### 一键自查脚本（推荐）

把上面这些命令整合一下，跑一遍就能对系统自启动情况心里有数：

```bash
#!/bin/bash
echo "===== 1. Launch Agents (用户) ====="
ls ~/Library/LaunchAgents/ 2>/dev/null

echo "===== 2. Launch Agents / Daemons (系统) ====="
ls /Library/LaunchAgents/ /Library/LaunchDaemons/ 2>/dev/null

echo "===== 3. 已加载的 launchctl job ====="
launchctl list

echo "===== 4. 沙盒登录项 Helper ====="
find /Applications -path "*/Contents/Library/LoginItems/*" -maxdepth 6 2>/dev/null

echo "===== 5. Login Hook ====="
defaults read com.apple.loginwindow LoginHook 2>/dev/null || echo "(无)"

echo "===== 6. cron 任务 ====="
crontab -l 2>/dev/null || echo "(无)"

echo "===== 7. 后台项数据库 ====="
sfltool dumpbtm 2>/dev/null | head -50
```

> 保存为 `check_autostart.sh`，`chmod +x` 后运行即可。脚本**只读**，不会改动任何系统配置。

---

## 四、总结与建议

- **普通 GUI App 随登录启动**：优先用 `SMLoginItemSetEnabled`（沙盒）或 `LSSharedFileList`（非沙盒，已废弃）。
- **后台常驻服务**：用 Launch Agent（`~/Library/LaunchAgents/` + `RunAtLoad`），macOS 13+ 会自动归类为 Background Item。
- **需要 root / 开机即跑**：用 Launch Daemon（`/Library/LaunchDaemons/`）。
- **定时任务**：用 cron / periodic。
- **自查**：图形界面看「系统设置 → 登录项」最省事；命令行用 `launchctl list` + 扫 plist 目录 + `sfltool dumpbtm` 最全面。

定期自查自启动项，既能清理流氓软件、加快开机速度，也能在开发时确认自己的 App 是否真的"自启动成功"。希望这篇对你有帮助！