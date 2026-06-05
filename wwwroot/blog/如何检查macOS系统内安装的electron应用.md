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

**只看应用名（用 awk 简化路径）：**

```bash
find /Applications -name "Electron Framework.framework" -type d 2>/dev/null \
  | awk -F'/' '{print $2".app"}'
```

**一键汇总所有 Chromium 系应用（Electron + CEF + QtWebEngine）：**

```bash
find /Applications \( \
  -name "Electron Framework.framework" -o \
  -name "Chromium Embedded Framework.framework" -o \
  -iname "QtWebEngine*" \
  \) -type d 2>/dev/null \
  | awk -F'/' '{print $2".app"}' | sort -u
```

### 进阶：查看应用详细信息

找到应用后，可以用 `mdls`、`du`、`PlistBuddy` 等命令查看更多信息：

```bash
# 查看版本
mdls -name kMDItemVersion "/Applications/Visual Studio Code.app"

# 查看占用空间
du -sh "/Applications/Visual Studio Code.app"

# 查看 bundle id
/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" \
  "/Applications/Visual Studio Code.app/Contents/Info.plist"
```

## 找出所有内置浏览器的应用

如果想把"内置了浏览器"的应用一网打尽，思路和上面完全一样——挨个 `find` 各种 framework 即可。

**一份命令，覆盖 90% 的内置浏览器应用：**

```bash
for fw in "Electron Framework.framework" \
          "Chromium Embedded Framework.framework" \
          "Google Chrome Framework.framework" \
          "Chromium Framework.framework" \
          "QtWebEngineCore.framework" \
          "QtWebEngine.framework" \
          "WebKit.framework" \
          "WebKit2.framework" \
          "MozillaFirefox.framework" \
          "nwjs.framework"; do
  find /Applications -name "$fw" -type d 2>/dev/null \
    | awk -F'/' '{print $2".app"}'
done | sort -u
```

> **小贴士**：也可以扫 `~/Applications`、`/System/Applications` 等目录，把 `/Applications` 替换即可。

## 深度排查：用 `otool` 看单个应用

`otool` 是 macOS 自带的工具，可以看应用到底链接了哪些 framework。当你不确定某个应用是不是"套壳浏览器"时，用它最准确：

```bash
# 看 Spotify 链接了哪些浏览器相关的 framework
otool -L "/Applications/Spotify.app/Contents/MacOS/Spotify" | grep -iE "chromium|webkit|cef"
```

如果有输出，就说明这个应用内置了浏览器引擎。

## 常见问题

### Q: 怎么判断一个 App 是不是 Electron 写的？

看它的 `Contents/Frameworks` 目录下有没有 `Electron Framework.framework` 文件夹。或者直接用上面的 `find` 命令扫一遍。

### Q: 为什么 Electron 应用普遍都很大？

因为每个 Electron 应用都要把 **Chromium** 和 **Node.js** 打包进去，光 Chromium 内核就接近 100MB。所以你装 10 个 Electron 应用，相当于装了 10 个浏览器。

### Q: 我想"彻底卸载"一个 Electron 应用，除了删 .app 还要做什么？

每个 Electron 应用都会在 `~/Library` 下生成数据目录，建议顺手清理：

- `~/Library/Application Support/<AppName>` - 用户配置、登录信息
- `~/Library/Caches/<AppName>` - 缓存文件
- `~/Library/Logs/<AppName>` - 日志文件

或者用 **AppCleaner**（免费）这类工具一键清理。

## 附录：完整可运行的扫描脚本

如果你懒得一行一行敲命令，可以直接用下面这个**完整脚本**。它会自动扫描常见位置、检测 18 种浏览器引擎，并输出应用名、版本、占用空间、bundle id 等详细信息。

### 使用方法

```bash
chmod +x detect_browser_apps.sh
./detect_browser_apps.sh              # 标准扫描
./detect_browser_apps.sh --full       # 深度扫描
./detect_browser_apps.sh --deep       # 全用户主目录扫描
./detect_browser_apps.sh --json > out.json   # 导出 JSON
./detect_browser_apps.sh --csv > out.csv     # 导出 CSV
```

### 完整脚本

```bash
#!/usr/bin/env bash
# ==============================================================================
#  detect_browser_apps.sh
#  扫描 macOS 系统内所有内置了浏览器引擎的应用程序
# ==============================================================================
#  支持检测的引擎：
#    - Electron / CEF / Chrome / Chromium
#    - QtWebEngine / WebKit / WebKit2 / WebKitLegacy
#    - Gecko / Firefox / NW.js / V8 / Blink
#    - JavaScriptCore / Edge / Servo
#
#  用法：
#    ./detect_browser_apps.sh              # 标准扫描
#    ./detect_browser_apps.sh --full       # 额外扫 /Library、/usr/local 等
#    ./detect_browser_apps.sh --deep       # 扫全用户主目录
#    ./detect_browser_apps.sh --json       # 输出 JSON
#    ./detect_browser_apps.sh --csv        # 输出 CSV
# ==============================================================================
#  兼容说明：本脚本在 macOS 默认的 bash 3.2 上可以运行。
#  未使用 bash 4+ 专有的 mapfile、关联数组等语法。
# ==============================================================================

set -o pipefail

# ---------- 颜色 ----------
if [[ -t 1 ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'
  GRAY='\033[0;90m'; BOLD='\033[1m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; PURPLE=''
  CYAN=''; GRAY=''; BOLD=''; NC=''
fi

# ---------- 引擎检测表 ----------
# 格式: "引擎名|framework 名(可多个，用 | 分隔)|二进制特征(可多个，用 | 分隔)"
ENGINE_RULES=(
  "Electron|Electron Framework.framework|Electron Helper|Electron"
  "CEF|Chromium Embedded Framework.framework|CEF Helper|Chromium Embedded"
  "Chrome|Google Chrome Framework.framework|Chrome Helper|Google Chrome"
  "Chromium|Chromium Framework.framework|Chromium Helper|Chromium"
  "QtWebEngine|QtWebEngineCore.framework|QtWebEngine.framework|QtWebEngine"
  "WebKit|WebKit.framework|WebKit Helper"
  "WebKit2|WebKit2.framework|WebKit2 Helper"
  "WebKitLegacy|WebKitLegacy.framework|WebKitLegacy Helper"
  "WebKitGTK|WebKitGTK.framework|WebKitGTK"
  "Gecko|Gecko.framework|XUL.framework|Gecko"
  "Firefox|Firefox.framework|Mozilla Firefox|firefox"
  "NW.js|nwjs.framework|nwjs Helper|nwjs"
  "V8|V8.framework|v8"
  "Blink|Blink.framework|blink"
  "JavaScriptCore|JavaScriptCore.framework|JavaScriptCore"
  "Edge|EdgeFramework.framework|Microsoft Edge|msedge"
  "Servo|Servo.framework|servo"
  "HeadlessChrome|Headless Chrome|headless_shell|chrome-headless"
)

# ---------- 扫描路径 ----------
DEFAULT_PATHS=(
  "/Applications"
  "/Applications/Utilities"
  "$HOME/Applications"
  "/System/Applications"
  "/System/Applications/Utilities"
)

EXTENDED_PATHS=(
  "/Library"
  "/usr/local"
  "/opt"
  "/private/var/db/receipts"
  "$HOME/Library/Application Support"
)

# ---------- 参数解析 ----------
OUTPUT_FORMAT="text"
DO_FULL=false
DO_DEEP=false
for arg in "$@"; do
  case "$arg" in
    --full) DO_FULL=true ;;
    --deep) DO_DEEP=true ;;
    --json) OUTPUT_FORMAT="json" ;;
    --csv)  OUTPUT_FORMAT="csv"  ;;
    -h|--help)
      echo "用法: $0 [--full] [--deep] [--json] [--csv]"
      exit 0 ;;
    *) echo "未知参数: $arg"; exit 1 ;;
  esac
done

# ---------- 组装扫描路径 ----------
SCAN_PATHS=("${DEFAULT_PATHS[@]}")
if [[ "$DO_FULL" == true || "$DO_DEEP" == true ]]; then
  SCAN_PATHS+=("${EXTENDED_PATHS[@]}")
fi
if [[ "$DO_DEEP" == true ]]; then
  while IFS= read -r d; do
    SCAN_PATHS+=("$d")
  done < <(find /Users -maxdepth 4 -type d -name "Applications" 2>/dev/null)
fi

# ---------- 收集所有 .app ----------
collect_apps() {
  local p app out=()
  for p in "${SCAN_PATHS[@]}"; do
    [[ -d "$p" ]] || continue
    while IFS= read -r app; do
      out+=("$app")
    done < <(find "$p" -name "*.app" -type d -maxdepth 5 2>/dev/null)
  done
  printf '%s\n' "${out[@]}" | sort -u
}

# ---------- 检测单个 app 的引擎 ----------
detect_engines() {
  local app="$1"
  local fw_dir="$app/Contents/Frameworks"
  local res_dir="$app/Contents/Resources"
  local macos_dir="$app/Contents/MacOS"
  local detected=()

  for rule in "${ENGINE_RULES[@]}"; do
    IFS='|' read -r engine fw_pat bin_pat <<<"$rule"
    local hit=false

    # 检查 Frameworks 目录
    if [[ -d "$fw_dir" ]]; then
      local fw_name
      while IFS= read -r fw_name; do
        [[ -z "$fw_name" ]] && continue
        local pat
        IFS='|' read -ra pats <<<"$fw_pat"
        for pat in "${pats[@]}"; do
          if [[ "$fw_name" == "$pat" ]]; then
            hit=true; break 2
          fi
        done
      done < <(ls -1 "$fw_dir" 2>/dev/null)
    fi

    # 检查 Resources 目录
    if [[ "$hit" == false && -d "$res_dir" ]]; then
      local r_name
      while IFS= read -r r_name; do
        [[ -z "$r_name" ]] && continue
        local pat
        IFS='|' read -ra pats <<<"$fw_pat"
        for pat in "${pats[@]}"; do
          if [[ "$r_name" == "$pat" ]]; then
            hit=true; break 2
          fi
        done
      done < <(ls -1 "$res_dir" 2>/dev/null)
    fi

    # 检查二进制名
    if [[ "$hit" == false && -d "$macos_dir" ]]; then
      local b
      for b in "$macos_dir"/*; do
        [[ -f "$b" ]] || continue
        local bname
        bname=$(basename "$b")
        local pat
        IFS='|' read -ra pats <<<"$bin_pat"
        for pat in "${pats[@]}"; do
          if [[ "$bname" == *"$pat"* ]]; then
            hit=true; break 2
          fi
        done
      done
    fi

    if [[ "$hit" == true ]]; then
      detected+=("$engine")
    fi
  done

  printf '%s\n' "${detected[@]}"
}

# ---------- 工具函数 ----------
get_bundle_id() {
  /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$1/Contents/Info.plist" 2>/dev/null || echo ""
}
get_version() {
  mdls -name kMDItemVersion "$1" 2>/dev/null \
    | awk -F'"' '/= "/ {gsub(/"/,"",$2); print $2; exit}' \
    || /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$1/Contents/Info.plist" 2>/dev/null \
    || echo ""
}
get_size() {
  du -sh "$1" 2>/dev/null | cut -f1
}

# ---------- 主流程 ----------
echo -e "${BOLD}${CYAN}====================================================${NC}"
echo -e "${BOLD}${CYAN}  macOS 内置浏览器应用扫描工具${NC}"
echo -e "${BOLD}${CYAN}====================================================${NC}"
echo ""

echo -e "${GRAY}扫描目录：${NC}"
for p in "${SCAN_PATHS[@]}"; do
  if [[ -d "$p" ]]; then
    echo -e "  ${GREEN}✓${NC} $p"
  else
    echo -e "  ${GRAY}✗ $p (不存在)${NC}"
  fi
done
echo ""

echo -e "${YELLOW}正在收集所有 .app ...${NC}"
# 兼容 bash 3.2: 用 while 循环代替 mapfile
ALL_APPS=()
while IFS= read -r app; do
  ALL_APPS+=("$app")
done < <(collect_apps)
TOTAL=${#ALL_APPS[@]}
echo -e "${GREEN}共找到 $TOTAL 个应用，开始检测浏览器引擎...${NC}"
echo ""

# 兼容 bash 3.2: 用并行数组代替关联数组
RESULT_PATHS=()
RESULT_ENGINES=()
ENG_NAMES=()
ENG_COUNTS=()

record_engine() {
  local eng="$1"
  local i
  for i in "${!ENG_NAMES[@]}"; do
    if [[ "${ENG_NAMES[$i]}" == "$eng" ]]; then
      ENG_COUNTS[$i]=$(( ${ENG_COUNTS[$i]} + 1 ))
      return
    fi
  done
  ENG_NAMES+=("$eng")
  ENG_COUNTS+=(1)
}

record_result() {
  RESULT_PATHS+=("$1")
  RESULT_ENGINES+=("$2")
}

i=0
for app in "${ALL_APPS[@]}"; do
  i=$((i+1))
  printf "\r${GRAY}  进度: %d / %d${NC}" "$i" "$TOTAL"
  engines=$(detect_engines "$app")
  if [[ -n "$engines" ]]; then
    record_result "$app" "$engines"
    while IFS= read -r e; do
      [[ -z "$e" ]] && continue
      record_engine "$e"
    done <<<"$engines"
  fi
done
echo ""
echo ""

FOUND=${#RESULT_PATHS[@]}

# 按应用名排序
SORTED_IDX=()
TMP_SORT=$(mktemp)
for idx in "${!RESULT_PATHS[@]}"; do
  printf '%s\t%s\n' "$(basename "${RESULT_PATHS[$idx]}" .app)" "$idx" >> "$TMP_SORT"
done
while IFS=$'\t' read -r _ idx; do
  SORTED_IDX+=("$idx")
done < <(sort -f "$TMP_SORT")
rm -f "$TMP_SORT"

# ---------- 输出 ----------
if [[ "$OUTPUT_FORMAT" == "json" ]]; then
  echo "{"
  echo "  \"scan_time\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
  echo "  \"total_apps_scanned\": $TOTAL,"
  echo "  \"browser_apps_found\": $FOUND,"
  echo "  \"apps\": ["
  first=true
  for idx in "${SORTED_IDX[@]}"; do
    app="${RESULT_PATHS[$idx]}"
    engines_str="${RESULT_ENGINES[$idx]}"
    $first || echo ","
    first=false
    name=$(basename "$app" .app)
    version=$(get_version "$app")
    bundle=$(get_bundle_id "$app")
    size=$(get_size "$app")
    engines_json=$(echo "$engines_str" | awk '{printf "\"%s\",", $0}' | sed 's/,$//')
    printf '    {"name": "%s", "path": "%s", "bundle_id": "%s", "version": "%s", "size": "%s", "engines": [%s]}' \
      "$name" "$app" "$bundle" "$version" "$size" "$engines_json"
  done
  echo ""
  echo "  ]"
  echo "}"
elif [[ "$OUTPUT_FORMAT" == "csv" ]]; then
  echo "name,path,bundle_id,version,size,engines"
  for idx in "${SORTED_IDX[@]}"; do
    app="${RESULT_PATHS[$idx]}"
    engines_str="${RESULT_ENGINES[$idx]}"
    name=$(basename "$app" .app)
    version=$(get_version "$app")
    bundle=$(get_bundle_id "$app")
    size=$(get_size "$app")
    engines_csv=$(echo "$engines_str" | tr '\n' ';')
    printf '"%s","%s","%s","%s","%s","%s"\n' \
      "$name" "$app" "$bundle" "$version" "$size" "$engines_csv"
  done
else
  echo -e "${BOLD}${PURPLE}━━━━ 扫描结果 ━━━━${NC}"
  echo ""

  echo -e "${BOLD}引擎统计：${NC}"
  for i in "${!ENG_NAMES[@]}"; do
    printf "  ${CYAN}%-20s${NC} %s 个应用\n" "${ENG_NAMES[$i]}" "${ENG_COUNTS[$i]}"
  done
  echo ""

  echo -e "${BOLD}详细列表（按应用名排序）：${NC}"
  echo ""
  for idx in "${SORTED_IDX[@]}"; do
    app="${RESULT_PATHS[$idx]}"
    engines_str="${RESULT_ENGINES[$idx]}"
    name=$(basename "$app" .app)
    version=$(get_version "$app")
    bundle=$(get_bundle_id "$app")
    size=$(get_size "$app")
    engines=$(echo "$engines_str" | tr '\n' ',' | sed 's/,$//')

    echo -e "${BOLD}${GREEN}▸ $name${NC} ${YELLOW}[v${version:-?}]${NC} ${GRAY}($size)${NC}"
    echo -e "  ${GRAY}路径:    $app${NC}"
    [[ -n "$bundle" ]] && echo -e "  ${GRAY}Bundle:  $bundle${NC}"
    echo -e "  ${GRAY}引擎:    ${BLUE}$engines${NC}"
    echo ""
  done
fi

echo -e "${BOLD}${CYAN}====================================================${NC}"
echo -e "${BOLD}扫描完成：共发现 $FOUND 个内置浏览器的应用 (扫描总数 $TOTAL)${NC}"
echo -e "${BOLD}${CYAN}====================================================${NC}"
```

### 小贴士

- 在 **`--deep`** 模式下会扫 `users/` 下的所有用户目录，可能需要 1-3 分钟
- 脚本不会修改系统任何文件，**完全只读**，可以放心运行

到这里，本文就结束了。希望对你有帮助！
