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

# 使用 -o pipefail 但不设 -u，避免空数组在 printf 时报 unbound variable
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
# 多重检测机制：
#   1) Frameworks 目录里有没有特征 framework
#   2) Resources 目录里有没有特征 framework
#   3) MacOS/ 下的二进制名是否包含特征关键字
#   4) 【兜底】用 otool -L 查主二进制链接的 framework
detect_engines() {
  local app="$1"
  local fw_dir="$app/Contents/Frameworks"
  local res_dir="$app/Contents/Resources"
  local macos_dir="$app/Contents/MacOS"
  local detected=()

  # 一次性跑 otool，结果复用到所有规则（节省时间）
  local app_name
  app_name=$(basename "$app" .app)
  local main_bin="$macos_dir/$app_name"
  local otool_output=""
  if [[ -f "$main_bin" ]]; then
    otool_output=$(otool -L "$main_bin" 2>/dev/null)
  fi

  for rule in "${ENGINE_RULES[@]}"; do
    IFS='|' read -r engine fw_pat bin_pat <<<"$rule"
    local hit=false

    # 1) Frameworks 目录
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

    # 2) Resources 目录
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

    # 3) 二进制名
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

    # 4) otool 兜底
    if [[ "$hit" == false && -n "$otool_output" ]]; then
      local pat
      IFS='|' read -ra pats <<<"$fw_pat"
      for pat in "${pats[@]}"; do
        if echo "$otool_output" | grep -qi "$pat"; then
          hit=true; break
        fi
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
# 兼容 bash 3.2 (macOS 默认版本不支持 mapfile)
ALL_APPS=()
while IFS= read -r app; do
  ALL_APPS+=("$app")
done < <(collect_apps)
TOTAL=${#ALL_APPS[@]}
echo -e "${GREEN}共找到 $TOTAL 个应用，开始检测浏览器引擎...${NC}"
echo ""

# 兼容 bash 3.2: 使用两个并行数组代替关联数组
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
  local app="$1"
  local engines="$2"
  RESULT_PATHS+=("$app")
  RESULT_ENGINES+=("$engines")
}

# 过滤掉名字明显是 Helper 的 app（这些是 Electron 运行时生成的辅助进程）
# 其他子 app（即使是主 app 的 Contents/ 下子 app）保留显示
is_real_app() {
  local app="$1"
  local name
  name=$(basename "$app" .app)
  # 跳过名字以 “ Helper” 结尾的 app
  case "$name" in
    *" Helper") return 1 ;;
  esac
  return 0
}

i=0
for app in "${ALL_APPS[@]}"; do
  i=$((i+1))
  printf "\r${GRAY}  进度: %d / %d${NC}" "$i" "$TOTAL"
  is_real_app "$app" || continue
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
SORTED_INDICES=()
for idx in "${!RESULT_PATHS[@]}"; do
  SORTED_INDICES+=("$idx")
done
TMP_SORT=$(mktemp)
for idx in "${SORTED_INDICES[@]}"; do
  printf '%s\t%s\n' "$(basename "${RESULT_PATHS[$idx]}" .app)" "$idx" >> "$TMP_SORT"
done
SORTED_IDX=()
while IFS=$'\t' read -r _ idx; do
  SORTED_IDX+=("$idx")
done < <(sort -f "$TMP_SORT")
rm -f "$TMP_SORT"

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
