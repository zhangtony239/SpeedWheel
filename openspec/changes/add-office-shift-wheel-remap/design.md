# Design

## Context

见 [proposal.md](proposal.md) 的动机。实现现状（[`main+officePatch.ahk`](../../../main+officePatch.ahk)，与 [`main.ahk`](../../../main.ahk) 仅差 `logPath` 初始化一行）：

- 速度模式期间动态挂载 `*WheelDown`/`*WheelUp` 钩子（[`EnterSpeedMode()`](../../../main+officePatch.ahk:143) 挂载、[`ExitSpeedMode()`](../../../main+officePatch.ahk:158) 以 `"Off"` 注销），非速度模式零拦截。
- 输出侧 [`ScrollTick()`](../../../main+officePatch.ahk:189) 以 `{Blind}` 发送竖向滚轮，携带发送时刻物理按住的修饰键（D3 语义）。
- 脚本自身 `Send`/`SendInput` 的合成事件 SendLevel 为 0，不会触发本脚本的 level-0 热键——补丁热键输出的 `WheelLeft/Right` 不会自吞，速度模式输出也不会回流到补丁热键（这也意味着速度模式输出的 `Shift+WheelDown` 到达 Office 后不会被补丁重映射，故输出侧必须单独处理）。
- 补丁热键是常驻热键，与 `wheel-speed-mode` 既有"零拦截/修饰键透明"要求冲突，已按 [wheel-speed-mode delta](specs/wheel-speed-mode/spec.md) 以显式例外处理。

## Goals / Non-Goals

**Goals:**

- 仅在 [`main+officePatch.ahk`](../../../main+officePatch.ahk) 内实现，行为契约见 [office-horizontal-scroll delta](specs/office-horizontal-scroll/spec.md)。
- 无论 AHK 热键变体（`+WheelDown` 作用域热键 vs 动态 `*WheelDown` 通配钩子）以何种优先级命中，速度模式行为完全一致（速度模式优先，可验证地"不覆盖 SpeedWheel"）。
- 输出侧按每次发送实时判定前台与 Shift 状态，滚动中途切换焦点/修饰键立即生效。

**Non-Goals:**

- 不修改 [`main.ahk`](../../../main.ahk)、`.env` 解析（`env-configuration` 无变更）与 README。
- 不修复 `main+officePatch.ahk` 缺失 `logPath` 初始化的既有漂移（DEBUG 日志失效）。
- 不扩展到 PowerPoint 等其他 Office 应用、触控板横滑、Shift 以外的修饰键横滚语义。

## Decisions

### D1：输入侧收敛为"双路径同行为"，而非依赖热键变体优先级
`#HotIf WinActive("ahk_exe WINWORD.EXE") || WinActive("ahk_exe EXCEL.EXE")` 作用域下的 `+WheelUp`/`+WheelDown` 热键处理器首行判定 `speedMode`：

- 速度模式激活 → 走与 [`WheelUpHandler`](../../../main+officePatch.ahk:181)/[`WheelDownHandler`](../../../main+officePatch.ahk:175) 完全相同的调速逻辑（抽成共享函数，如 `AdjustSpeed(delta)`，三处调用）；
- 未激活 → `SendInput "{WheelLeft}"` / `SendInput "{WheelRight}"`（与用户给定片段一致）。

理由：`+WheelDown`（作用域热键）与动态注册的 `*WheelDown`（通配钩子）同为 `WheelDown` 热键变体，二者同时匹配时 AHK 的变体优先级细节不可依赖。让两条路径的行为完全收敛后，无论哪个变体命中，结果都是"速度模式调速 / 非速度模式横滚重映射"，SpeedWheel 语义零变化。备选方案"速度模式期间动态停用 `+Wheel` 热键"被否决：需在进出速度模式增删热键状态，且速度模式期间焦点切换会引入时序窗口，收益为零。

### D2：输出侧在 `ScrollTick()` 内按发送时刻判定，横滚输出用非 `{Blind}` 的 `SendInput`
每次 tick 输出前判定：`GetKeyState("Shift", "P")` 且前台为 WINWORD.EXE/EXCEL.EXE → 速度向下分量发 `SendInput "{WheelRight n}"`、向上分量发 `SendInput "{WheelLeft n}"`（方向映射与输入侧一致：Shift+WheelDown↔WheelRight、Shift+WheelUp↔WheelLeft）；否则保持既有 `Send "{Blind}{WheelUp/Down n}"` 路径一行不动。

理由：合成事件不触发本脚本热键（SendLevel 0），输出侧无法"借道"输入侧重映射，只能直接改发 `WheelLeft/Right`。非 `{Blind}` 发送会自动中和物理按住的 Shift（及 Ctrl/Alt），使 Office 收到不带修饰的横向滚轮事件，这正是规格要求的可观测行为；备选"`{Blind}` 携带 Shift 发 WheelLeft/Right"会让 Office 收到 Shift+WheelLeft/Right，语义未定义，否决。逐 tick 判定（而非进入速度模式时缓存）保证滚动中途切换焦点或松开 Shift 立即回到 `{Blind}` 语义。

### D3：`#HotIf` 块置于文件末尾并复位，动态注册不受作用域污染
`Hotkey()` 函数的 HotIf 判定跟随脚本源码位置上的最近 `#HotIf`。补丁的 `#HotIf WinActive(...)` 热键块放在文件末尾，块尾以裸 `#HotIf` 复位；[`EnterSpeedMode()`](../../../main+officePatch.ahk:143)/[`ExitSpeedMode()`](../../../main+officePatch.ahk:158) 中的 `Hotkey("*Wheel*")` 调用位于该块之前，注册的钩子保持无作用域（全台生效）。若实测发现被污染，回退手段是在注册前显式 `HotIf()` 复位。

### D4：作用域判定用统一谓词
新增 `IsOfficeActive()`（`WinActive("ahk_exe WINWORD.EXE") || WinActive("ahk_exe EXCEL.EXE")`），`#HotIf` 表达式与 `ScrollTick()` 输出判定共用同一定义，避免输入/输出作用域漂移。

## Risks / Trade-offs

- [`+WheelDown` 与 `*WheelDown` 变体命中不确定] → D1 双路径同行为已中和该风险；两路径共享 `AdjustSpeed()`，不存在语义分叉。
- [非 `{Blind}` 发送中和 Ctrl/Alt：Office 中 Shift+Ctrl+滚轮收到纯横滚] → 与输入侧重映射（`SendInput "{WheelLeft}"` 同样中和修饰键）行为一致，视为规格内可接受的边缘行为；如需保留 Ctrl 可后续扩展，不影响本次规格。
- [横滚输出期间切换焦点离开 Office] → 逐 tick 判定（D2），下一 tick 自动回到 `{Blind}` 路径；速度/携带量（`carry`）状态连续，无跳变。
- [Word/Excel 窗口判定以进程名为准] → 与用户给定片段一致；嵌入式 Office 控件（如 Outlook 预览）不属于 WINWORD/EXCEL 进程，不在作用域内，符合规格。
- [`#HotIf` 位置污染动态注册] → D3 的文件布局 + 实测验证（DEBUG 日志中 `RegisterTrigger`/`EnterSpeedMode` 记录可确认钩子行为）；回退手段已列明。

## Migration Plan

单文件脚本替换即生效：运行 `main+officePatch.ahk`（替换当前实例，`#SingleInstance Force`）。回滚 = 切回 [`main.ahk`](../../../main.ahk) 或还原该文件。无数据迁移、无配置变更。

## Open Questions

无（PowerPoint 等扩展与 logPath 漂移修复已明确排除在本变更外，留待未来独立变更）。
