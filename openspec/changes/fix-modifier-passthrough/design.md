# Design

## Context

`main.ahk` 当前用 `*WheelUp` / `*WheelDown` 静态热键全程拦截滚轮：非速度模式下靠 `Send("{WheelDown}")` 回放，速度模式下吸收为速度增量。AHK `Send` 发送前会释放物理按住的修饰键，导致 Ctrl+滚轮等组合的修饰信息丢失（见 proposal.md - Why）。触发键经 `RegisterTrigger` 注册——初版无 `*` 前缀，实测发现修饰键按住时（如 Shift 让 Chrome 进入横滚时）按下 HOTKEY 生成"修饰键+HOTKEY"组合，不匹配无修饰的热键定义，速度模式无法进入；已按 D6 改为通配注册。

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

### D2: 速度模式内滚轮全量吸收（实施中按用户决策修订）

初版设计：速度模式内用 `GetKeyState(..., "P")` 检测 Ctrl / Shift / Alt，任一按住则 `{Blind}` 透传、不吸收为速度调节（"仅裸滚轮参与调速"）。实施验证（DEBUG 日志）发现：按住 Shift（Chrome 横滚）进入速度模式后一切旁路，模式"看似失效"。经用户决策修订：**速度模式激活期间，滚轮事件（含 Ctrl / Shift / Alt 任意组合）全部吸收为速度调节，处理器内不做修饰键旁路**。

- 修饰键的"透传"改由输出侧承担（见 D3）；非速度模式的修饰键原生行为由"零拦截"保证。
- 备选（初版）：修饰键+滚轮旁路透传 —— 被否决：速度模式在修饰键按住期间无法驱动应用滚动语义，与"横滚速度模式"需求冲突。

### D3: ScrollTick 输出改用 `{Blind}`，携带修饰键（实施中按用户决策修订）

初版设计：`Send("{WheelDown n}")` 裸滚轮输出（Send 默认释放修饰键，保证输出为竖向裸滚轮）。经用户决策修订：输出改为 `Send("{Blind}{WheelDown n}")` / `Send("{Blind}{WheelUp n}")`，**携带发送时刻物理按住的修饰键，修饰键透传最终到软件**——按住 Shift 时应用（如 Chrome）表现为横滚方向的速度滚动；按住 Ctrl 时应用按其原生 Ctrl+滚轮语义消费输出。

- 自吞循环仍不存在：合成滚轮事件 SendLevel 为 0，不触发 level-0 热键。
- 已知语义（用户明确选择）：速度模式内按住 Ctrl 时输出表现为应用定义的 Ctrl+滚轮行为（如连续缩放）。

### D4: HOTKEY 滚轮键校验放在 RegisterTrigger 入口

解析出 `cfgHotkey` 后做大小写不敏感的滚轮键名单匹配（`WheelDown` / `WheelUp` / `WheelLeft` / `WheelRight`），命中即走现有回退路径（MButton + TrayTip），与无效热键回退共用同一条路径。理由：滚轮键作 HOTKEY 与速度模式滚轮拦截语义冲突，且 hold 模式下滚轮键无可靠 Up 事件。

### D6: 触发热键使用 `*` 通配注册（实施中新增）

`RegisterTrigger` 以 `Hotkey("*" hk, ...)` 通配注册触发热键（含 hold 模式的 `"*" hk " Up"` 与 MButton 回退路径），使 HOTKEY 在 Ctrl / Shift / Alt 任一按住时仍可触发速度模式。

- 初版无通配前缀：按住 Shift（Chrome 横滚）等修饰键时按下 HOTKEY，产生"修饰键+HOTKEY"组合，不匹配无修饰的热键定义，`HotkeyDown` 不触发，速度模式无法进入（DEBUG 日志证实：Shift 场景下无任何触发热键记录）。
- 用户需求明确：只要 HOTKEY 不是修饰键本身，速度模式触发应独立于修饰键状态。
- HOTKEY 配置为修饰键本身时，通配注册会与其原生修饰功能冲突——属用户自行选择的配置，脚本不特判（记录为已知限制）。

### D5: 归档顺序约束

本 change 的 `wheel-speed-mode` delta 含 MODIFIED 操作，依赖主 spec 已存在；而上游 change `wheel-speed-mode`（已完成、未归档）尚未同步到 `openspec/specs/`。**本 change 必须在 `wheel-speed-mode` 归档之后归档**，否则 MODIFIED 将被拒绝。不改变本 change 的工件内容，仅记录顺序约束。

## Risks / Trade-offs

- [动态挂/卸钩子在快速连续进出速度模式时的时序] → 挂载/注销都在 Enter/ExitSpeedMode 单点完成，AHK `Hotkey` 调用同步生效；杀停路径（SetTimer 0 + 清零）不变，无残留定时器。
- [`{Blind}` 输出携带修饰键：速度模式内按住 Ctrl 时输出表现为应用定义的 Ctrl+滚轮行为（如连续缩放）] → 用户明确选择的语义（D3 修订），文档记录为已知语义而非缺陷。
- [blind 透传的合成事件与原生事件在个别应用中的细微差异] → Chrome 等主流应用对带修饰的合成滚轮事件处理与原生一致；如遇个别应用异常，属 AHK Send 固有限制，记录为已知限制。
- [HOTKEY 配置为修饰键（如 LCtrl）时 hold 模式的 Up 事件语义] → AHK 对修饰键支持 `::`/` Up::` 对，现有 RegisterTrigger 已兼容，不在本次范围内额外改动。
- [D6 通配注册后 HOTKEY 配置为修饰键本身时与该修饰键原生功能冲突] → 属用户自行选择的配置，脚本不特判；文档记录为已知限制。