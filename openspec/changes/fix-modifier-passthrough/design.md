# Design

## Context

`main.ahk` 当前用 `*WheelUp` / `*WheelDown` 静态热键全程拦截滚轮：非速度模式下靠 `Send("{WheelDown}")` 回放，速度模式下吸收为速度增量。AHK `Send` 发送前会释放物理按住的修饰键，导致 Ctrl+滚轮等组合的修饰信息丢失（见 proposal.md - Why）。触发键经 `RegisterTrigger` 注册，无 `*` 前缀，修饰键按住时不触发——该行为与"修饰键透明"语义一致，保留。

## Goals / Non-Goals

**Goals:**

- 非速度模式对滚轮零拦截（动态挂/卸钩子），原生事件直达应用
- 速度模式期间修饰键+滚轮以 `{Blind}` 透传，仅裸滚轮参与速度调节
- HOTKEY 成为唯一常驻拦截点；HOTKEY 配置为滚轮键时回退 MButton 并提示

**Non-Goals:**

- 不改速度映射算法（STEP / TICK_MS / carry）、杀停语义、hold/tap 状态机
- 不改 `.env` 解析格式
- 不处理 Win 键（`#` 前缀组合）作为旁路触发——Win+滚轮无通用原生语义，超出本次范围

## Decisions

### D1: 动态注册滚轮钩子，而非静态钩子 + 条件回放

进入速度模式时 `Hotkey("*WheelDown", ...)` / `Hotkey("*WheelUp", ...)` 挂载，退出时以 `Hotkey("*WheelDown", 0)` 注销。

- 备选 A（现状）：静态钩子全程拦截，非速度模式 `Send` 回放 —— 被否决：回放必然经过 `Send`，修饰键剥离是 `Send` 的默认行为，`{Blind}` 只能补救无法根除，且空闲期常驻钩子徒增系统级干扰。
- 备选 B：静态钩子 + 处理器内检测 `speedMode` 决定吸收或 blind 回放 —— 可行但非速度模式仍有拦截-回放路径，违背"零拦截"目标。
- 动态注册让"透传"成为"根本不碰"，是唯一同时满足零拦截与修饰键保真的方案。

### D2: 速度模式内修饰键检测用 `GetKeyState(..., "P")`

滚轮钩子处理器内检查 Ctrl / Shift / Alt 的物理状态（`"P"` 模式），任一按住则 `Send("{Blind}{WheelDown}")` / `Send("{Blind}{WheelUp}")` 透传并 return，不修改 `speed`。

- `{Blind}` 不释放已按住的修饰键，合成事件自带修饰状态，应用侧行为与原生一致。
- 备选：`~` 前缀热键（不阻断原生事件）—— 但那样裸滚轮在速度模式下也会原生滚动，无法实现"只吃裸滚轮"，故否决。

### D3: ScrollTick 输出保持裸滚轮 Send

`Send("{WheelDown n}")` 维持现状。速度增量只来自裸滚轮，输出时若用户恰好按住修饰键，`Send` 默认释放修饰键恰好保证输出事件为裸滚轮，与"速度模式只由裸滚轮驱动"自洽，无需改动。

### D4: HOTKEY 滚轮键校验放在 RegisterTrigger 入口

解析出 `cfgHotkey` 后做大小写不敏感的滚轮键名单匹配（`WheelDown` / `WheelUp` / `WheelLeft` / `WheelRight`），命中即走现有回退路径（MButton + TrayTip），与无效热键回退共用同一条路径。理由：滚轮键作 HOTKEY 与速度模式滚轮拦截语义冲突，且 hold 模式下滚轮键无可靠 Up 事件。

### D5: 归档顺序约束

本 change 的 `wheel-speed-mode` delta 含 MODIFIED 操作，依赖主 spec 已存在；而上游 change `wheel-speed-mode`（已完成、未归档）尚未同步到 `openspec/specs/`。**本 change 必须在 `wheel-speed-mode` 归档之后归档**，否则 MODIFIED 将被拒绝。不改变本 change 的工件内容，仅记录顺序约束。

## Risks / Trade-offs

- [动态挂/卸钩子在快速连续进出速度模式时的时序] → 挂载/注销都在 Enter/ExitSpeedMode 单点完成，AHK `Hotkey` 调用同步生效；杀停路径（SetTimer 0 + 清零）不变，无残留定时器。
- [`GetKeyState("P")` 检测与透传之间的毫秒级窗口内修饰键状态变化] → 窗口极小且后果仅是单次拨动的归类偏差，可接受；不做重试。
- [blind 透传的合成事件与原生事件在个别应用中的细微差异] → Chrome 等主流应用对带修饰的合成滚轮事件处理与原生一致；如遇个别应用异常，属 AHK Send 固有限制，记录为已知限制。
- [HOTKEY 配置为修饰键（如 LCtrl）时 hold 模式的 Up 事件语义] → AHK 对修饰键支持 `::`/` Up::` 对，现有 RegisterTrigger 已兼容，不在本次范围内额外改动。