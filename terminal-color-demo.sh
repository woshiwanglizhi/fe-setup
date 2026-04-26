#!/bin/bash
# ============================================================
#  终端配色方案完全演示教程
#  Terminal Color Scheme — Interactive Demo
#  
#  用法：chmod +x terminal-color-demo.sh && ./terminal-color-demo.sh
#  建议：在 iTerm2 / Alacritty / Kitty 中运行（需支持 True Color）
#  字体：推荐 Nerd Font（否则部分图标显示为方块）
# ============================================================

# --- 颜色工具函数 ---
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
ITALIC="\033[3m"
UNDERLINE="\033[4m"

# True Color helpers
tc() { printf "\033[38;2;%d;%d;%dm" "$1" "$2" "$3"; }
tcbg() { printf "\033[48;2;%d;%d;%dm" "$1" "$2" "$3"; }

# 等待用户按键继续
pause() {
  echo ""
  printf "  \033[2m按 Enter 继续 ▸\033[0m"
  read -r
  echo ""
}

# 段落标题
section() {
  local width=60
  echo ""
  printf "  $(tc 203 166 247)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
  printf "  $(tc 203 166 247)${BOLD}  $1${RESET}\n"
  printf "  $(tc 203 166 247)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
  echo ""
}

# 小标题
subsection() {
  echo ""
  printf "  $(tc 137 180 250)${BOLD}▎ $1${RESET}\n"
  echo ""
}

# 正文
body() {
  printf "  $1\n"
}

# 高亮关键词
hl() { printf "$(tc 249 226 175)${BOLD}$1${RESET}"; }
hlg() { printf "$(tc 166 227 161)${BOLD}$1${RESET}"; }
hlr() { printf "$(tc 243 139 168)${BOLD}$1${RESET}"; }
hlb() { printf "$(tc 137 180 250)${BOLD}$1${RESET}"; }
hlp() { printf "$(tc 203 166 247)${BOLD}$1${RESET}"; }
hlpk() { printf "$(tc 245 194 231)${BOLD}$1${RESET}"; }

clear

# ============================================================
#  PART 0: 开场
# ============================================================

echo ""
echo ""
printf "  $(tc 243 139 168)█$(tc 250 179 135)█$(tc 249 226 175)█$(tc 166 227 161)█$(tc 137 180 250)█$(tc 203 166 247)█$(tc 245 194 231)█${RESET}  "
printf "${BOLD}$(tc 205 214 244)终端配色方案完全指南${RESET}\n"
echo ""
printf "  $(tc 166 172 205)Terminal Color Scheme — The Complete Guide${RESET}\n"
printf "  $(tc 108 112 134)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
echo ""
body "本演示将在你的终端里，$(hl "实时展示") 配色方案的工作原理。"
body "你将看到的所有颜色效果，都是 $(hlb "你当前终端") 真实渲染的。"
echo ""
body "$(tc 108 112 134)包含内容：${RESET}"
body "  $(hlp "①") 什么是配色方案（改了什么）"
body "  $(hlp "②") ANSI 16 色槽位演示"
body "  $(hlp "③") True Color 能力"
body "  $(hlp "④") Pastel vs 高饱和 对比"
body "  $(hlp "⑤") Catppuccin 调色板演示"
body "  $(hlp "⑥") Dracula 调色板演示"
body "  $(hlp "⑦") Powerline & Nerd Font 图标"
body "  $(hlp "⑧") 语法高亮 & 语义着色"
body "  $(hlp "⑨") 三层架构总结"

pause

# ============================================================
#  PART 1: 什么是配色方案
# ============================================================

section "① 什么是配色方案？"

body "配色方案 = $(hl "一张 18 个格子的对照表")"
body ""
body "你的终端里，所有颜色都来自 $(hlb "16 个 ANSI 颜色槽位") + $(hlb "背景色") + $(hlb "前景色")。"
body ""
body "当 git / ls / grep 等程序说 \"用红色显示\" 时，"
body "它们并不知道红色具体是什么颜色——"
body "它们只是说：$(hlr "请用槽位 1 的颜色")。"
body ""
body "$(hl "配色方案做的事：重新定义每个槽位填什么颜色。")"

pause

# ============================================================
#  PART 2: ANSI 16 色
# ============================================================

section "② ANSI 16 色槽位"

subsection "标准 8 色（槽位 0-7）"

# 每行格式：槽位号 + 纯色块（背景色）+ 名称（写死在色块外面，白色文字）
printf "  \033[0m 0  \033[48;5;0m          \033[0m  Black\n"
printf "  \033[0m 1  \033[48;5;1m          \033[0m  Red\n"
printf "  \033[0m 2  \033[48;5;2m          \033[0m  Green\n"
printf "  \033[0m 3  \033[48;5;3m          \033[0m  Yellow\n"
printf "  \033[0m 4  \033[48;5;4m          \033[0m  Blue\n"
printf "  \033[0m 5  \033[48;5;5m          \033[0m  Magenta\n"
printf "  \033[0m 6  \033[48;5;6m          \033[0m  Cyan\n"
printf "  \033[0m 7  \033[48;5;7m          \033[0m  White\n"

subsection "明亮 8 色（槽位 8-15）"

printf "  \033[0m 8  \033[48;5;8m          \033[0m  Bright Black\n"
printf "  \033[0m 9  \033[48;5;9m          \033[0m  Bright Red\n"
printf "  \033[0m10  \033[48;5;10m          \033[0m  Bright Green\n"
printf "  \033[0m11  \033[48;5;11m          \033[0m  Bright Yellow\n"
printf "  \033[0m12  \033[48;5;12m          \033[0m  Bright Blue\n"
printf "  \033[0m13  \033[48;5;13m          \033[0m  Bright Magenta\n"
printf "  \033[0m14  \033[48;5;14m          \033[0m  Bright Cyan\n"
printf "  \033[0m15  \033[48;5;15m          \033[0m  Bright White\n"

echo ""
body "⬆️ 这就是你当前终端的 $(hl "16 色配置")。"
body "换一套配色方案，上面每个色块的颜色都会变。"

pause

# ============================================================
#  PART 2.5: 同一个 "Red" 在不同方案里的区别
# ============================================================

section "③ 同一个槽位，不同方案不同颜色"

body "比如「$(hlr "Red / 槽位 1")」这个槽位，在不同方案里的定义："
echo ""

# 默认
printf "  $(tcbg 255 0 0)  默认终端  ${RESET}  #FF0000  纯红 · 刺眼\n"
# Dracula
printf "  $(tcbg 255 85 85)  Dracula   ${RESET}  #FF5555  珊瑚红 · 鲜艳\n"
# Catppuccin
printf "  $(tcbg 243 139 168)  Catppuccin${RESET}  #F38BA8  粉红 · 柔和\n"
# Nord
printf "  $(tcbg 191 97 106)  Nord      ${RESET}  #BF616A  暗玫瑰 · 沉稳\n"
# Solarized
printf "  $(tcbg 220 50 47)  Solarized ${RESET}  #DC322F  砖红 · 经典\n"

echo ""
body "同一个 git 报错信息，五种配色方案渲染出来 $(hl "五种不同的红")。"
body "这就是配色方案在做的事——$(hl "重新填这 18 个格子")。"

pause

# ============================================================
#  PART 3: True Color
# ============================================================

section "④ True Color 演示"

body "现代终端不止 16 色。支持 $(hl "True Color (24-bit)")："
body "可以显示 $(hl "16,777,216") 种颜色（#000000 ~ #FFFFFF）。"
echo ""

subsection "RGB 渐变条"

# Red gradient
printf "  R: "
for i in $(seq 0 4 255); do
  printf "$(tcbg $i 0 0) ${RESET}"
done
echo ""

# Green gradient
printf "  G: "
for i in $(seq 0 4 255); do
  printf "$(tcbg 0 $i 0) ${RESET}"
done
echo ""

# Blue gradient
printf "  B: "
for i in $(seq 0 4 255); do
  printf "$(tcbg 0 0 $i) ${RESET}"
done
echo ""

subsection "彩虹渐变"

printf "  "
for i in $(seq 0 2 179); do
  r=$(printf "%.0f" $(echo "s($i*3.14159/180)*127+128" | bc -l 2>/dev/null || echo 128))
  g=$(printf "%.0f" $(echo "s(($i+60)*3.14159/180)*127+128" | bc -l 2>/dev/null || echo 128))
  b=$(printf "%.0f" $(echo "s(($i+120)*3.14159/180)*127+128" | bc -l 2>/dev/null || echo 128))
  printf "$(tcbg $r $g $b) ${RESET}"
done
echo ""
echo ""

body "如果你看到了平滑的渐变 → 你的终端$(hlg "支持 True Color") ✓"
body "如果看到色块/条纹 → 你的终端只支持 256 色"

pause

# ============================================================
#  PART 4: Pastel vs 高饱和
# ============================================================

section "⑤ Pastel（柔和）vs 高饱和 对比"

body "$(hl "Pastel") = 加了白色的柔和色调，降低饱和度"
body "$(hl "Vivid")  = 高饱和、鲜艳、对比强烈"
echo ""

subsection "同一组颜色的两种风格"

printf "  %-12s" ""
printf "$(tc 108 112 134)%-14s${RESET}" "Pastel (柔和)"
printf "$(tc 108 112 134)%-14s${RESET}" "Vivid (鲜艳)"
echo ""

# Red
printf "  %-12s" "Red"
printf "$(tcbg 243 139 168)              ${RESET} "
printf "$(tcbg 255 0 0)              ${RESET}"
echo ""
# Green
printf "  %-12s" "Green"
printf "$(tcbg 166 227 161)              ${RESET} "
printf "$(tcbg 0 255 0)              ${RESET}"
echo ""
# Blue
printf "  %-12s" "Blue"
printf "$(tcbg 137 180 250)              ${RESET} "
printf "$(tcbg 0 0 255)              ${RESET}"
echo ""
# Yellow
printf "  %-12s" "Yellow"
printf "$(tcbg 249 226 175)              ${RESET} "
printf "$(tcbg 255 255 0)              ${RESET}"
echo ""
# Purple
printf "  %-12s" "Purple"
printf "$(tcbg 203 166 247)              ${RESET} "
printf "$(tcbg 128 0 255)              ${RESET}"
echo ""
# Cyan
printf "  %-12s" "Cyan"
printf "$(tcbg 148 226 213)              ${RESET} "
printf "$(tcbg 0 255 255)              ${RESET}"
echo ""

echo ""
body "左边 Pastel 风 = $(hlp "Catppuccin") 的选择  →  护眼 · 温暖 · 长时间舒适"
body "右边 Vivid 风  = $(hlr "Dracula") 更接近    →  锐利 · 醒目 · 高辨识度"

pause

# ============================================================
#  PART 5: Catppuccin 调色板
# ============================================================

section "⑥ Catppuccin Mocha 完整调色板"

body "26 个语义化命名颜色 · 最受欢迎的暗色口味"
echo ""

subsection "强调色 Accent Colors"

printf "  $(tcbg 243 139 168)  Rosewater ${RESET} "
printf "$(tcbg 242 205 205)  Flamingo  ${RESET} "
printf "$(tcbg 245 194 231)  Pink      ${RESET} "
printf "$(tcbg 203 166 247)\033[38;2;30;30;46m  Mauve     ${RESET} "
echo ""
printf "  $(tcbg 243 139 168)  Red       ${RESET} "
printf "$(tcbg 235 160 172)  Maroon    ${RESET} "
printf "$(tcbg 250 179 135)  Peach     ${RESET} "
printf "$(tcbg 249 226 175)\033[38;2;30;30;46m  Yellow    ${RESET} "
echo ""
printf "  $(tcbg 166 227 161)\033[38;2;30;30;46m  Green     ${RESET} "
printf "$(tcbg 148 226 213)\033[38;2;30;30;46m  Teal      ${RESET} "
printf "$(tcbg 137 220 235)\033[38;2;30;30;46m  Sky       ${RESET} "
printf "$(tcbg 116 199 236)\033[38;2;30;30;46m  Sapphire  ${RESET} "
echo ""
printf "  $(tcbg 137 180 250)\033[38;2;30;30;46m  Blue      ${RESET} "
printf "$(tcbg 180 190 254)\033[38;2;30;30;46m  Lavender  ${RESET} "
echo ""

subsection "基础色 Base Colors"

printf "  $(tcbg 205 214 244)\033[38;2;30;30;46m  Text      ${RESET} "
printf "$(tcbg 186 194 222)\033[38;2;30;30;46m  Subtext1  ${RESET} "
printf "$(tcbg 166 173 200)\033[38;2;30;30;46m  Subtext0  ${RESET} "
printf "$(tcbg 147 153 178)\033[38;2;30;30;46m  Overlay2  ${RESET} "
echo ""
printf "  $(tcbg 127 132 156)  Overlay1  ${RESET} "
printf "$(tcbg 108 112 134)  Overlay0  ${RESET} "
printf "$(tcbg 88 91 112)  Surface2  ${RESET} "
printf "$(tcbg 69 71 90)  Surface1  ${RESET} "
echo ""
printf "  $(tcbg 49 50 68)  Surface0  ${RESET} "
printf "$(tcbg 30 30 46)  Base      ${RESET} "
printf "$(tcbg 24 24 37)  Mantle    ${RESET} "
printf "$(tcbg 17 17 27)  Crust     ${RESET} "
echo ""

echo ""
body "特点：$(hlp "低饱和 · 温暖偏蓝紫 · 每个色都有名字")"
body "背景 #1E1E2E 不是纯黑，而是 $(hlp "带蓝紫调的深色")"

pause

# ============================================================
#  PART 6: Dracula 调色板
# ============================================================

section "⑦ Dracula 完整调色板"

body "11 个标准色 · 经典暗色方案 · 2013年诞生"
echo ""

printf "  $(tcbg 40 42 54)  Background ${RESET} #282A36\n"
printf "  $(tcbg 68 71 90)  Current    ${RESET} #44475A\n"
printf "  $(tcbg 248 248 242)\033[38;2;40;42;54m  Foreground ${RESET} #F8F8F2\n"
printf "  $(tcbg 98 114 164)  Comment    ${RESET} #6272A4\n"
echo ""
printf "  $(tcbg 139 233 253)\033[38;2;40;42;54m  Cyan       ${RESET} #8BE9FD\n"
printf "  $(tcbg 80 250 123)\033[38;2;40;42;54m  Green      ${RESET} #50FA7B\n"
printf "  $(tcbg 255 184 108)\033[38;2;40;42;54m  Orange     ${RESET} #FFB86C\n"
printf "  $(tcbg 255 121 198)\033[38;2;40;42;54m  Pink       ${RESET} #FF79C6\n"
printf "  $(tcbg 189 147 249)  Purple     ${RESET} #BD93F9\n"
printf "  $(tcbg 255 85 85)  Red        ${RESET} #FF5555\n"
printf "  $(tcbg 241 250 140)\033[38;2;40;42;54m  Yellow     ${RESET} #F1FA8C\n"

echo ""
body "特点：$(hlr "高饱和 · 鲜艳锐利 · 每个色都很「跳」")"
body "对比 Catppuccin 的柔和——Dracula 是 $(hlr "「一眼就能看到」") 的风格"

pause

# ============================================================
#  PART 6.5: 两个方案直接对比
# ============================================================

section "⑧ Catppuccin vs Dracula 直接对比"

printf "  %-12s  %-22s  %-22s\n" "" "$(hlp "Catppuccin Mocha")" "$(hlr "Dracula")"
printf "  $(tc 108 112 134)%-12s${RESET}" "背景"
printf "  $(tcbg 30 30 46)    #1E1E2E 蓝紫调    ${RESET}"
printf "  $(tcbg 40 42 54)    #282A36 蓝灰调    ${RESET}"
echo ""
printf "  $(tc 108 112 134)%-12s${RESET}" "前景"
printf "  $(tcbg 30 30 46)$(tc 205 214 244)    #CDD6F4 淡蓝白    ${RESET}"
printf "  $(tcbg 40 42 54)$(tc 248 248 242)    #F8F8F2 近纯白    ${RESET}"
echo ""
printf "  $(tc 108 112 134)%-12s${RESET}" "Red"
printf "  $(tcbg 30 30 46)$(tc 243 139 168)    ████ #F38BA8     ${RESET}"
printf "  $(tcbg 40 42 54)$(tc 255 85 85)    ████ #FF5555     ${RESET}"
echo ""
printf "  $(tc 108 112 134)%-12s${RESET}" "Green"
printf "  $(tcbg 30 30 46)$(tc 166 227 161)    ████ #A6E3A1     ${RESET}"
printf "  $(tcbg 40 42 54)$(tc 80 250 123)    ████ #50FA7B     ${RESET}"
echo ""
printf "  $(tc 108 112 134)%-12s${RESET}" "Yellow"
printf "  $(tcbg 30 30 46)$(tc 249 226 175)    ████ #F9E2AF     ${RESET}"
printf "  $(tcbg 40 42 54)$(tc 241 250 140)    ████ #F1FA8C     ${RESET}"
echo ""
printf "  $(tc 108 112 134)%-12s${RESET}" "Blue"
printf "  $(tcbg 30 30 46)$(tc 137 180 250)    ████ #89B4FA     ${RESET}"
printf "  $(tcbg 40 42 54)$(tc 139 233 253)    ████ #8BE9FD     ${RESET}"
echo ""
printf "  $(tc 108 112 134)%-12s${RESET}" "Purple"
printf "  $(tcbg 30 30 46)$(tc 203 166 247)    ████ #CBA6F7     ${RESET}"
printf "  $(tcbg 40 42 54)$(tc 189 147 249)    ████ #BD93F9     ${RESET}"
echo ""

echo ""
body "左边整体更 $(hlp "温暖柔和")，右边整体更 $(hlr "鲜艳醒目")"
body "日常长时间编码 → Catppuccin | 演示/录屏 → Dracula"

pause

# ============================================================
#  PART 7: Powerline & Nerd Font
# ============================================================

section "⑨ Powerline 符号 & Nerd Font 图标"

subsection "Powerline 分隔符"

body "Powerline 风格的 Prompt 用箭头形分隔符连接各段信息："
echo ""
# Powerline arrow: U+E0B0 = \xEE\x82\xB0 in UTF-8
PL_ARROW=$'\xee\x82\xb0'
# Catppuccin powerline
printf "  $(tcbg 137 180 250)\033[38;2;30;30;46m  ~/project $(tcbg 203 166 247)\033[38;2;137;180;250m${PL_ARROW}\033[38;2;30;30;46m  main $(tcbg 166 227 161)\033[38;2;203;166;247m${PL_ARROW}\033[38;2;30;30;46m  v20.1 ${RESET}\033[38;2;166;227;161m${PL_ARROW}${RESET}\n"
echo ""
# Dracula powerline
printf "  $(tcbg 139 233 253)\033[38;2;40;42;54m  ~/project $(tcbg 255 121 198)\033[38;2;139;233;253m${PL_ARROW}\033[38;2;40;42;54m  main $(tcbg 80 250 123)\033[38;2;255;121;198m${PL_ARROW}\033[38;2;40;42;54m  v20.1 ${RESET}\033[38;2;80;250;123m${PL_ARROW}${RESET}\n"
echo ""

body "上面的箭头 $(hl "${PL_ARROW}") 是 Powerline 专用字符（U+E0B0）"
body "$(hlr "如果你看到的是方块/乱码 → 你需要安装 Nerd Font")"

subsection "Nerd Font 图标采样"

body "Nerd Font 在字体里嵌入了 9000+ 图标："
echo ""
# Nerd Font icons via UTF-8 byte sequences
# Dev tools: nf-dev-git (U+E702), nf-dev-docker (U+F308→\xEF\x8C\x88), nf-dev-terminal (U+E795), nf-dev-database (U+F1C0→\xEF\x87\x80), nf-dev-react (U+E7BA)
I_GIT=$'\xee\x9c\x82'       # U+E702 git
I_DOCKER=$'\xef\x8c\x88'    # U+F308 docker (approx)
I_TERM=$'\xee\x9e\x95'      # U+E795 terminal
I_DB=$'\xef\x87\x80'        # U+F1C0 database
I_REACT=$'\xee\x9e\xba'     # U+E7BA react

# Languages: nf-dev-python (U+E73C), nf-dev-javascript (U+E74E→\xE781\x8E), nf-dev-rust (U+E7A8), nf-dev-go (U+E724→approx), nf-seti-typescript (U+E628)
I_PYTHON=$'\xee\x9c\xbc'    # U+E73C python
I_JS=$'\xee\x9d\x8e'        # U+E74E javascript (approx)
I_RUST=$'\xee\x9e\xa8'      # U+E7A8 rust
I_GO=$'\xee\x9c\xa4'        # U+E724 go (approx)
I_TS=$'\xee\x98\xa8'        # U+E628 typescript

# System: folder (U+F115→\xEF\x84\x95), home (U+F015→\xEF\x80\x95), cog (U+F013→\xEF\x80\x93), search (U+F002→\xEF\x80\x82), lock (U+F023→\xEF\x80\xA3)
I_FOLDER=$'\xef\x84\x95'    # U+F115 folder-open
I_HOME=$'\xef\x80\x95'      # U+F015 home
I_COG=$'\xef\x80\x93'       # U+F013 cog
I_SEARCH=$'\xef\x80\x82'    # U+F002 search
I_LOCK=$'\xef\x80\xa3'      # U+F023 lock

# Git: branch (U+E725→\xEE\x9C\xA5), merge (U+E727→\xEE\x9C\xA7), commit (U+E729→\xEE\x9C\xA9)
I_BRANCH=$'\xee\x9c\xa5'    # U+E725 git-branch
I_MERGE=$'\xee\x9c\xa7'     # U+E727 git-merge
I_COMMIT=$'\xee\x9c\xa9'    # U+E729 git-commit

# File types: markdown (U+E73E→\xEE\x9C\xBE), json (U+E60B→\xEE\x98\x8B), config (U+E615→\xEE\x98\x95)
I_MD=$'\xee\x9c\xbe'        # U+E73E markdown
I_JSON=$'\xee\x98\x8b'      # U+E60B json
I_CONF=$'\xee\x98\x95'      # U+E615 config

printf "  $(tc 137 180 250)开发工具:${RESET}     $(tc 205 214 244)${I_GIT}  ${I_DOCKER}  ${I_TERM}  ${I_DB}  ${I_REACT}${RESET}\n"
printf "  $(tc 166 227 161)编程语言:${RESET}     $(tc 205 214 244)${I_PYTHON}  ${I_JS}  ${I_RUST}  ${I_GO}  ${I_TS}${RESET}\n"
printf "  $(tc 249 226 175)系统图标:${RESET}     $(tc 205 214 244)${I_FOLDER}  ${I_HOME}  ${I_COG}  ${I_SEARCH}  ${I_LOCK}${RESET}\n"
printf "  $(tc 243 139 168)Git 图标:${RESET}     $(tc 205 214 244)${I_BRANCH}  ${I_MERGE}  ${I_COMMIT}${RESET}\n"
printf "  $(tc 203 166 247)文件类型:${RESET}     $(tc 205 214 244)${I_MD}  ${I_JSON}  ${I_CONF}${RESET}\n"
echo ""
body "$(hl "如果上面的图标正常显示 → 你已经装好了 Nerd Font ✓")"
body "$(hlr "如果显示为方块 □ → 需要安装：") brew install --cask font-fira-code-nerd-font"

pause

# ============================================================
#  PART 8: 语法高亮 / 语义着色
# ============================================================

section "⑩ 语义着色演示"

body "好的配色方案让你 $(hl "扫一眼就看懂代码结构")："
echo ""

# Catppuccin style code
subsection "Catppuccin 风格"

printf "  $(tcbg 30 30 46)                                                          ${RESET}\n"
printf "  $(tcbg 30 30 46)  $(tc 137 180 250)import$(tc 205 214 244) { $(tc 166 227 161)useState$(tc 205 214 244) } $(tc 137 180 250)from$(tc 205 214 244) $(tc 249 226 175)'react'$(tc 205 214 244)                        ${RESET}\n"
printf "  $(tcbg 30 30 46)                                                          ${RESET}\n"
printf "  $(tcbg 30 30 46)  $(tc 137 180 250)function$(tc 205 214 244) $(tc 166 227 161)App$(tc 205 214 244)() {                                      ${RESET}\n"
printf "  $(tcbg 30 30 46)    $(tc 137 180 250)const$(tc 205 214 244) [$(tc 243 139 168)count$(tc 205 214 244), $(tc 250 179 135)setCount$(tc 205 214 244)] = $(tc 166 227 161)useState$(tc 205 214 244)($(tc 250 179 135)0$(tc 205 214 244))            ${RESET}\n"
printf "  $(tcbg 30 30 46)    $(tc 137 180 250)return$(tc 205 214 244) <$(tc 137 180 250)button$(tc 205 214 244) $(tc 249 226 175)onClick$(tc 205 214 244)={() => $(tc 250 179 135)setCount$(tc 205 214 244)($(tc 243 139 168)count$(tc 205 214 244)+$(tc 250 179 135)1$(tc 205 214 244))}>  ${RESET}\n"
printf "  $(tcbg 30 30 46)  }                                                      ${RESET}\n"
printf "  $(tcbg 30 30 46)                                                          ${RESET}\n"

echo ""

# Dracula style code
subsection "Dracula 风格"

printf "  $(tcbg 40 42 54)                                                          ${RESET}\n"
printf "  $(tcbg 40 42 54)  $(tc 255 121 198)import$(tc 248 248 242) { $(tc 80 250 123)useState$(tc 248 248 242) } $(tc 255 121 198)from$(tc 248 248 242) $(tc 241 250 140)'react'$(tc 248 248 242)                        ${RESET}\n"
printf "  $(tcbg 40 42 54)                                                          ${RESET}\n"
printf "  $(tcbg 40 42 54)  $(tc 255 121 198)function$(tc 248 248 242) $(tc 80 250 123)App$(tc 248 248 242)() {                                      ${RESET}\n"
printf "  $(tcbg 40 42 54)    $(tc 255 121 198)const$(tc 248 248 242) [$(tc 255 85 85)count$(tc 248 248 242), $(tc 255 184 108)setCount$(tc 248 248 242)] = $(tc 80 250 123)useState$(tc 248 248 242)($(tc 189 147 249)0$(tc 248 248 242))            ${RESET}\n"
printf "  $(tcbg 40 42 54)    $(tc 255 121 198)return$(tc 248 248 242) <$(tc 139 233 253)button$(tc 248 248 242) $(tc 80 250 123)onClick$(tc 248 248 242)={() => $(tc 255 184 108)setCount$(tc 248 248 242)($(tc 255 85 85)count$(tc 248 248 242)+$(tc 189 147 249)1$(tc 248 248 242))}>  ${RESET}\n"
printf "  $(tcbg 40 42 54)  }                                                      ${RESET}\n"
printf "  $(tcbg 40 42 54)                                                          ${RESET}\n"

echo ""
body "$(hlb "关键字")用蓝/粉  $(hlg "函数")用绿  $(hlr "变量")用红  $(hl "字符串")用黄"
body "不需要逐字读 → $(hl "扫一眼就知道哪里是什么")"

pause

# ============================================================
#  PART 9: 三层架构
# ============================================================

section "⑪ 终端美化三层架构"

# 不用闭合框，只用左边色条标记层级，彻底避免对齐问题
L1="$(tc 137 180 250)" # blue
L2="$(tc 166 227 161)" # green
L3="$(tc 203 166 247)" # purple
DIM="$(tc 108 112 134)"
YEL="$(tc 249 226 175)"
WHT="$(tc 205 214 244)"

echo ""
printf "  ${L1}${BOLD}Layer 1  Terminal Emulator${RESET}\n"
printf "  ${L1}==${RESET}${DIM}======================================${RESET}\n"
printf "  ${L1}||${RESET}  ${WHT}iTerm2 / Alacritty / Kitty / Warp${RESET}\n"
printf "  ${L1}||${RESET}  ${DIM}Color Scheme + Font${RESET}\n"
printf "  ${L1}||${RESET}\n"
printf "  ${L1}||${RESET}  ${L2}${BOLD}Layer 2  Shell${RESET}\n"
printf "  ${L1}||${RESET}  ${L2}==${RESET}${DIM}================================${RESET}\n"
printf "  ${L1}||${RESET}  ${L2}||${RESET}  ${WHT}Zsh / Bash / Fish${RESET}\n"
printf "  ${L1}||${RESET}  ${L2}||${RESET}  ${DIM}Plugins + Aliases${RESET}\n"
printf "  ${L1}||${RESET}  ${L2}||${RESET}\n"
printf "  ${L1}||${RESET}  ${L2}||${RESET}  ${L3}${BOLD}Layer 3  Prompt${RESET}\n"
printf "  ${L1}||${RESET}  ${L2}||${RESET}  ${L3}==${RESET}${DIM}===========================${RESET}\n"
printf "  ${L1}||${RESET}  ${L2}||${RESET}  ${L3}||${RESET}  ${WHT}Starship / Powerlevel10k${RESET}\n"
printf "  ${L1}||${RESET}  ${L2}||${RESET}  ${L3}||${RESET}  ${DIM}Prompt style + info display${RESET}\n"
printf "  ${L1}||${RESET}  ${L2}||${RESET}  ${L3}==${RESET}${DIM}===========================${RESET}\n"
printf "  ${L1}||${RESET}  ${L2}||${RESET}\n"
printf "  ${L1}||${RESET}  ${L2}==${RESET}${DIM}================================${RESET}\n"
printf "  ${L1}||${RESET}\n"
printf "  ${L1}==${RESET}${DIM}======================================${RESET}\n"
echo ""
printf "  ${YEL}${BOLD}+ Nerd Font${RESET}${DIM} -- runs through ALL layers${RESET}\n"
echo ""

pause

# ============================================================
#  结尾
# ============================================================

section "✅ 演示完成"

body "你刚才看到的所有颜色，都是你的终端 $(hl "实时渲染") 的。"
echo ""
body "$(hlp "快速开始美化你的终端：")"
echo ""
body "  $(hlg "1.")  brew install --cask font-fira-code-nerd-font"
body "  $(hlg "2.")  终端 Settings → Font → FiraCode Nerd Font"
body "  $(hlg "3.")  brew install starship"
body "  $(hlg "4.")  echo 'eval \"\$(starship init zsh)\"' >> ~/.zshrc"
body "  $(hlg "5.")  下载 Catppuccin/Dracula 配色导入终端"
echo ""
printf "  $(tc 243 139 168)█$(tc 250 179 135)█$(tc 249 226 175)█$(tc 166 227 161)█$(tc 137 180 250)█$(tc 203 166 247)█$(tc 245 194 231)█${RESET}  "
printf "$(tc 108 112 134)Happy Ricing!${RESET}\n"
echo ""
