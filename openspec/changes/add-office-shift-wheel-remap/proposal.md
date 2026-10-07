# Proposal

## Why

Word 与 Excel 不支持 Shift+滚轮横向滚动，用户希望在 `main+officePatch.ahk`（officePatch 变体）中加入 `Shift+WheelUp/Down → WheelLeft/WheelRight` 的重映射，作用域限定 Word/Excel 前台。该重映射是常驻热键，会与 SpeedWheel 速度模式的滚轮拦截产生冲突，必须明确共存语义：速度模式优先，补丁不得覆盖 SpeedWheel 本身；同时补齐速度模式输出侧在 Office 中按住 Shift 时的横滚速度滚动（D3 语义），否则合成的 Shift+滚轮事件会被 Office 忽略。

## What Changes

- 仅修改 [`main+officePatch.ahk`](../../main+officePatch.ahk)；[`main.ahk`](../../main.ahk)（SpeedWheel 核心）保持不变。
- 新增 `#HotIf WinActive` 作用域（`ahk_exe WINWORD.EXE` 与 `ahk_exe EXCEL.EXE`）的 Shift+滚轮热键：Shift+WheelUp 发送 `WheelLeft`，Shift+WheelDown 发送 `WheelRight`（非速度模式下接管，Office 原生对 Shift+滚轮无行为）。
- 速度模式优先：速度模式激活期间 Shift+滚轮事件仍被吸收为速度调节（与裸滚轮/Ctrl/Alt 一致），补丁热键 MUST NOT 吞掉事件或发送横滚，SpeedWheel 的调速与杀停语义完全不变。
- 速度模式输出侧：当前台为 Word/Excel 且发送时刻物理按住 Shift 时，速度滚动输出改发 `WheelLeft`/`WheelRight`（不携带 Shift 的横滚速度滚动）；其他应用保持既有 `{Blind}` 输出（D3 语义）不变。

## Capabilities

### New Capabilities

- `office-horizontal-scroll`: Word/Excel 作用域的 Shift+滚轮横向滚动（officePatch 变体）：非速度模式下的 Shift+滚轮重映射、与速度模式的优先级共存语义（速度模式优先、不覆盖 SpeedWheel），以及速度模式输出在 Office+Shift 下的横滚速度滚动。

### Modified Capabilities

- `wheel-speed-mode`: 为 officePatch 变体在 Word/Excel 作用域引入显式例外——"非速度模式下滚轮行为不变"、"非速度模式修饰键透明"（常驻拦截例外）与"速度滚动输出携带修饰键"（`{Blind}` 输出例外）三条要求在该作用域内由 `office-horizontal-scroll` 接管；标准构建（`main.ahk`）行为不变。

## Impact

- 代码：仅 [`main+officePatch.ahk`](../../main+officePatch.ahk)（新增 `#HotIf` 热键段、速度模式优先的处理分支、[`ScrollTick()`](../../main+officePatch.ahk:189) 输出侧分支）。
- [`main.ahk`](../../main.ahk)、`.env` 配置解析（`env-configuration` 无需求变更）、README 不受影响。
- 兼容性：非 Office 应用、非 Shift 组合、速度模式的进入/退出/调速/杀停行为完全不变；行为变化仅限 Word/Excel 前台的 Shift+滚轮（由"Office 忽略"变为"横向滚动"）。
- 顺带观察（不在本变更范围）：`main+officePatch.ahk` 缺少 `logPath := A_ScriptDir "\speedwheel.log"` 初始化，DEBUG 日志在该变体中失效。
