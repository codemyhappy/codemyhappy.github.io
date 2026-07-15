---
title: 什么是 macOS 的沙盒 App，开发时和非沙盒 App 有什么区别
---

# 什么是 macOS 的沙盒 App，开发时和非沙盒 App 有什么区别

最近在写 macOS 小工具时，被 App Store 的审核卡了一道——原因就是"没有开启沙盒（Sandbox）"。这让我重新梳理了一遍 macOS 沙盒机制，发现很多刚入坑 macOS 开发的朋友对"沙盒"这个概念其实很模糊：它到底是什么？为什么 Apple 强制要求？沙盒 App 和非沙盒 App 在开发时到底差在哪？

这篇文章就一次性讲清楚。

---

## 一、什么是 macOS 沙盒（App Sandbox）？

**App Sandbox（应用沙盒）** 是 Apple 从 macOS 10.7（Lion）引入的一套**安全隔离机制**。它的核心思想是：

> 每个 App 都被关在一个"沙盒"里，只能访问自己被明确授权的资源，默认情况下不能碰系统其他部分、其他 App 的数据、用户的敏感文件。

你可以把它理解成给 App 发了一张**"有限通行证"**——没在通行证上写明的权限，系统一律拒绝。

### 为什么要搞沙盒？

- **安全**：即使 App 被黑客攻破（比如解析了一个恶意文件），攻击者也只能在沙盒内搞破坏，拿不到你相册里的照片、拿不到钥匙串里的密码。
- **隐私**：用户能清楚知道"这个 App 要访问我的通讯录/摄像头/下载文件夹"，并且可以单独关掉。
- **App Store 强制要求**：从 2012 年起，**所有上架 Mac App Store 的 App 必须开启沙盒**，否则无法审核通过。

### 沙盒长什么样？

开启沙盒后，Xcode 会在你的 `.entitlements` 文件里加上这一行：

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
```

这个文件通常叫 `YourApp.entitlements`，位于 Xcode 工程的 `Signing & Capabilities` 里。所有沙盒权限都是在这个文件里声明的。

---

## 二、沙盒 App 能访问什么？（默认 vs 授权后）

沙盒 App 的权限分两类：**默认就有** 和 **需要显式申请**。

### 默认就有的能力

- 自己的 `Container` 目录（`~/Library/Containers/<bundle-id>/`）—— 相当于 App 的"私人房间"
- 自己的偏好设置、缓存
- 通过用户**主动拖拽/打开**的文件（这就是下面要讲的"临时授权"）

### 需要申请（entitlements）的能力

| 权限（Entitlement） | 作用 | 对应系统弹窗 |
|----------------------|------|--------------|
| `com.apple.security.files.user-selected.read-only` | 读用户选中的文件 | "XXX 想访问文件？" |
| `com.apple.security.files.user-selected.read-write` | 读写用户选中的文件 | 同上 |
| `com.apple.security.files.downloads.read-only` | 读下载文件夹 | 同上 |
| `com.apple.security.personal-information.addressbook` | 访问通讯录 | "想访问通讯录？" |
| `com.apple.security.device.camera` | 使用摄像头 | "想使用摄像头？" |
| `com.apple.security.device.microphone` | 使用麦克风 | "想使用麦克风？" |
| `com.apple.security.network.client` | 发起网络请求 | 无弹窗（默认允许出网） |
| `com.apple.security.network.server` | 监听端口（做服务器） | 无弹窗 |
| `com.apple.security.automation.apple-events` | 发送 Apple 事件控制其他 App | "想控制 XXX？" |

> 注意：**网络出访默认是允许的**，不需要申请；但监听本地端口做服务器需要 `network.server`。

### 临时授权（Power Box / Security-Scoped Bookmarks）

这是沙盒里一个很关键的概念。当用户在**打开/保存对话框**里选了一个文件，系统会临时给这个文件发一个"访问令牌"。但 App 重启后令牌就失效了——如果想长期记住这个文件，需要用 **Security-Scoped Bookmark** 把它" bookmark" 下来，下次启动时再 `startAccessingSecurityScopedResource()` 重新激活。

```objc
// 用户选了文件后，保存 bookmark 以便下次启动还能访问
NSURL *fileURL = ...; // 用户通过 NSOpenPanel 选的
NSData *bookmark = [fileURL bookmarkDataWithOptions:NSURLBookmarkCreationSecurityScoped
                            includingResourceValuesForKeys:nil
                                             relativeToURL:nil
                                                     error:nil];
// 存到 UserDefaults / 数据库
[[NSUserDefaults standardUserDefaults] setObject:bookmark forKey:@"myFileBookmark"];

// 下次启动重新激活访问
NSData *saved = [[NSUserDefaults standardUserDefaults] objectForKey:@"myFileBookmark"];
NSURL *url = [NSURL URLByResolvingBookmarkData:saved
                                          options:NSURLBookmarkResolutionWithSecurityScope
                                    relativeToURL:nil
                              bookmarkDataIsStale:nil
                                              error:nil];
[url startAccessingSecurityScopedResource];
// ... 使用 url ...
[url stopAccessingSecurityScopedResource];
```

---

## 三、如何区分一个 App 是不是沙盒 App？

不管是自己开发的还是别人装的，判断"它是不是沙盒 App"有几种可靠方法。

### 方法 1：开发期直接看 entitlements 文件

沙盒的开关就是一个 entitlement 键值。打开你工程里的 `*.entitlements` 文件（Tauri v2 默认在 `src-tauri/entitlements.plist`，v1 在 `tauri.conf.json` 的 `bundle.macOS.entitlements` 指向的文件），搜索 `app-sandbox`：

- 有 `<key>com.apple.security.app-sandbox</key>` 且值为 `<true/>` → **沙盒**
- 没有这一行，或值为 `<false/>` → **非沙盒**

> Tauri 默认的 entitlements 通常只有 `com.apple.security.cs.allow-jit`、`cs.allow-unsigned-executable-memory`、`cs.disable-library-validation` 这类**代码签名加固项**，并不包含 `app-sandbox`。所以 Tauri 打包出来的 App **默认就是非沙盒**。

### 方法 2：对已打包/已安装的 App 用 codesign 查（最准）

不需要源码，直接查系统里已经签好名的 App：

```bash
# 把路径换成你的 App
codesign -d --entitlements - /Applications/你的App.app
```

输出里如果出现 `com.apple.security.app-sandbox` 且为 `true`，就是沙盒；**完全没有这一行**就是非沙盒。

### 方法 3：看 Container 目录

沙盒 App 会被系统分配一个独立的"房间"目录：

```bash
ls ~/Library/Containers/ | grep 你的bundle-id
```

- 有对应目录 → **沙盒**
- 没有 → **非沙盒**

### 方法 4：行为验证法（运行时判断）

在 App 里尝试访问一个用户敏感目录（如 `~/Documents`、`~/Desktop`、`~/Downloads`），或者尝试执行系统命令（如 `system("ls /")`）：

- 被系统拒绝 / 拿不到数据 → 很可能是**沙盒**
- 畅通无阻 → **非沙盒**

> 注意：从 macOS 10.14 起，即使是非沙盒 App，访问通讯录、相册、桌面等也受 TCC 隐私框架管控可能弹窗，所以"弹窗"不等于"沙盒"，要以 entitlements 为准。

### 方法 5：Tauri 开发者特别说明（重要）

很多 Tauri 开发者会混淆两套"权限"：

| 概念 | 是什么 | 和 macOS 沙盒的关系 |
|------|--------|---------------------|
| **Tauri capabilities / permissions**（v2 的 `capabilities/*.json`、v1 的 `allowlist`） | 控制前端 JS 能通过 IPC 调用哪些 Rust 命令（能不能读文件、能不能执行 shell） | ❌ 完全无关，这是 Tauri 自己的"前端能力白名单" |
| **macOS App Sandbox**（`com.apple.security.app-sandbox`） | 操作系统级的隔离，限制 App 能碰哪些文件/硬件/网络 | ✅ 这才是真正的"沙盒" |

**结论**：即使你配了 Tauri 的 `permissions`，只要没在 entitlements 里开 `app-sandbox`，你的 App 在系统层面依然是**非沙盒**。想上 Mac App Store 就必须开沙盒，届时 Tauri 的 `permissions` 里涉及文件系统/网络/子进程的能力还会被沙盒进一步限制（比如不能随便 `Command::new("bash")` 调系统命令、不能扫整个磁盘）。

---

## 四、沙盒 vs 非沙盒：开发时到底差在哪？

这是本文的重点。下面从**文件系统、进程/命令行、网络、硬件/隐私、签名分发、具体 API** 六个维度对比。

### 1. 文件系统访问

| 场景 | 沙盒 App | 非沙盒 App |
|------|-----------|-------------|
| 读写自己 Container 目录 | ✅ 默认 | ✅ 默认 |
| 读写用户主动打开的文件 | ✅ 临时授权 | ✅ 任意 |
| 直接读 `~/Documents`、`~/Desktop` | ❌ 需逐项申请或用户选 | ✅ 随便读 |
| 读其他 App 的数据（如 `/Users/x/Library/...`） | ❌ 完全禁止 | ✅ 只要文件权限允许 |

**开发影响**：如果你的 App 需要"扫描整个磁盘找某种文件"（比如我之前写的检测 Electron 应用的脚本思路），沙盒 App 基本做不到，必须引导用户用打开对话框逐个选目录，或者改用非沙盒 + 不上架 App Store。

### 2. 执行外部命令 / 子进程

| 场景 | 沙盒 App | 非沙盒 App |
|------|-----------|-------------|
| 执行自己包内的辅助程序（Helper） | ✅ 允许 | ✅ 允许 |
| 执行系统命令（如 `/bin/bash`、`/usr/bin/sqlite3`） | ❌ 默认禁止，需 `com.apple.security.temporary-exception` 例外（已不推荐） | ✅ 任意 `NSTask` / `posix_spawn` |
| 调用 `system()` | ❌ 禁止 | ✅ 可用 |

**开发影响**：沙盒 App 不能随便 `system("rm -rf ...")` 或调用系统二进制。所有外部能力要么自己打包进 `.app`，要么通过 XPC 服务与授权过的 Helper 通信。

### 3. 网络

| 场景 | 沙盒 App | 非沙盒 App |
|------|-----------|-------------|
| 发起网络请求（HTTP/HTTPS） | ✅ 默认允许 | ✅ 默认允许 |
| 监听本地端口（本地服务器） | ⚠️ 需 `network.server` | ✅ 任意 |
| 访问局域网设备 | ✅ 允许（出网） | ✅ 允许 |

**开发影响**：大多数联网 App 不受影响。但如果你要做"本地 HTTP 服务 + 浏览器访问 localhost"（比如很多开发工具的做法），记得勾上 `network.server`。

### 4. 硬件与隐私（摄像头/麦克风/通讯录等）

| 场景 | 沙盒 App | 非沙盒 App |
|------|-----------|-------------|
| 访问摄像头/麦克风 | ✅ 需申请 + 用户授权弹窗 | ✅ 直接可用（无系统弹窗，但 TCC 仍可能拦） |
| 访问通讯录/日历/照片 | ✅ 需申请 + 用户授权 | ⚠️ 受 TCC 隐私框架限制，仍可能弹窗 |

> 注意：从 macOS 10.14（Mojave）起，即使是非沙盒 App，访问通讯录、相册、桌面等也受 **TCC（Transparency, Consent, and Control）** 隐私框架管控，会在 `系统设置 → 隐私与安全性` 里出现。沙盒只是把这套机制"标准化"了。

### 5. 签名与分发方式

| 维度 | 沙盒 App | 非沙盒 App |
|------|-----------|-------------|
| 上架 Mac App Store | ✅ **必须沙盒** | ❌ 无法上架 |
| 自己官网分发（Developer ID） | ✅ 可以（仍建议沙盒） | ✅ 可以 |
| 公证（Notarization） | ✅ 需要 | ✅ 需要 |
| 用户首次打开 | 可能弹隐私授权 | 同样可能弹 TCC 授权 |

**开发影响**：想进 App Store 赚钱/曝光 → 必须沙盒，很多功能要妥协。只想官网分发 → 可以放弃沙盒，功能更自由，但要自己搞定分发、更新、信任问题。

### 6. 典型受限 API 速查

| 你想做的事 | 沙盒下 | 非沙盒下 |
|------------|---------|-----------|
| 开机自启动（Login Item） | ✅ 只能用 `SMLoginItemSetEnabled` + Helper | ✅ 还能用 `LSSharedFileList` |
| 全局快捷键 | ✅ 允许 | ✅ 允许 |
| 屏幕录制 | ⚠️ 需 `screen-capture`（且受 TCC） | ⚠️ 受 TCC |
| 控制其他 App（AppleScript） | ⚠️ 需 `automation.apple-events` + 用户授权 | ✅ 直接发 |
| 访问钥匙串（Keychain） | ✅ 允许（独立机制） | ✅ 允许 |
| 写系统级目录（`/Library`、`/Applications`） | ❌ 禁止 | ⚠️ 需管理员授权 |

---

## 五、一个对比总结表

| 维度 | 沙盒 App | 非沙盒 App |
|------|----------|-------------|
| 安全性 | 高（隔离） | 低（可乱跑） |
| 隐私保护 | 强（逐项授权） | 依赖 TCC |
| 能访问的范围 | 仅授权资源 | 几乎全系统 |
| 能执行外部命令 | 受限 | 自由 |
| 上架 App Store | 必须 | 不行 |
| 开发自由度 | 低，要绕很多弯 | 高 |
| 用户信任度 | 高（Apple 背书） | 需自行建立 |

---

## 六、开发建议：我该怎么选？

1. **目标用户是普通消费者、想上 App Store** → 老老实实做沙盒，设计时就按"最小权限"来：能不申请就不申请，能用"用户主动选择"就不用"全盘访问"。
2. **是开发者工具 / 系统工具（如清理软件、监控软件、自启动管理）** → 这类往往必须碰系统深层资源，沙盒会严重受限。建议**不做沙盒 + 官网分发 + Developer ID 签名 + 公证**。
3. **需要开机自启动** → 沙盒 App 只能用 `SMLoginItemSetEnabled` + Helper（详见我另一篇《macOS 应用自启动开发和自查》）；非沙盒还能用更直接的 `LSSharedFileList`。
4. **调试技巧**：在 Xcode 里临时关掉沙盒（`com.apple.security.app-sandbox` 设为 `false`）可以快速验证"是不是沙盒权限导致功能失效"，确认后再决定是补 entitlement 还是改架构。

---

## 七、相关技术文档

- [App Sandbox 设计指南（Apple 官方）](https://developer.apple.com/documentation/security/app_sandbox)
- [Entitlements 权限键完整列表](https://developer.apple.com/documentation/bundleresources/entitlements)
- [App Sandbox 概念文档（旧但经典）](https://developer.apple.com/library/archive/documentation/Security/Conceptual/AppSandboxDesignGuide/AboutAppSandbox/AboutAppSandbox.html)
- [Security-Scoped Bookmarks 文档](https://developer.apple.com/documentation/foundation/nsurl/1417051-bookmarkdatawithoptions)
- [TCC 隐私框架说明](https://developer.apple.com/documentation/security/user-privacy)
- [Mac App Store 审核指南](https://developer.apple.com/app-store/review/guidelines/)

---

## 八、总结

macOS 沙盒本质上是一套**"默认拒绝、显式授权"**的安全模型。它让上架 App Store 的软件更可控、更隐私友好，但也给开发者戴上了"镣铐"——文件系统、外部命令、跨 App 通信都受到严格限制。

非沙盒 App 则像"裸奔"，能力全开但用户要自己承担风险，且无法进入 App Store。

**一句话记忆**：沙盒 = 安全但受限，适合消费级 App Store 软件；非沙盒 = 自由但需自证清白，适合开发者/系统级工具。开发前先想清楚分发渠道，能省掉一大半返工。

希望这篇对你有帮助！