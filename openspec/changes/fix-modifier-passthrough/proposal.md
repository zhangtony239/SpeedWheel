# Proposal

## Why

当前实现用 `*WheelUp` / `*WheelDown` 静态全局热键全程拦截滚轮，非速度模式下靠 `Send("{WheelDown}")` 回放。AHK 的 `Send` 在发送前会释放物理按住的修饰键，导致 Chrome 中 Ctrl+滚轮（横滚）等修饰键组合行为被破坏、退化为普通竖滚；速度模式下修饰键+滚轮还会被错误吸收为速度增量。修饰键透传是脚本的核心语义承诺，当前实现违背了它。

## What Changes

- **拦截策略改为动态注册**：滚轮钩子（`*WheelUp` / `*WheelDown`）仅在速度模式激活期间挂载，退出速度模式立即注销；非速度模式下脚本对滚轮零拦截，原生事件直接到达应用，不再需要"拦截再回放"。
- **速度模式期间修饰键旁路**：Ctrl / Shift / Alt 任一物理按住时拨动滚轮，事件以 `Send("{Blind}{Wheel...}")` 原样透传（保留修饰键），不吸收为速度增量；仅裸滚轮参与速度调节。
- **HOTKEY 唯一拦截点原则**：除 HOTKEY 本身外，脚本不常驻拦截任何按键；HOTKEY 若被配置为滚轮键（`WheelDown` / `WheelUp` / `WheelLeft` / `WheelRight`），视为无效配置，回退默认 `MButton` 并提示（与现有无效热键回退路径一致）。
- 速度映射、杀停、hold/tap 触发等既有行为不变。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `wheel-speed-mode`: 新增"修饰键全程透明"要求——非速度模式零拦截（动态挂钩），速度模式下修饰键+滚轮旁路透传、仅裸滚轮被吸收为速度增量；并修正"非速度模式下滚轮行为不变"的实现违背。
- `env-configuration`: 新增 HOTKEY 取值约束——HOTKEY 配置为滚轮键时回退默认 MButton 并提示，不报错退出。

## Impact

- 受影响代码：`main.ahk`（热键注册/注销逻辑、滚轮热键处理器、`RegisterTrigger` 的滚轮键校验）。
- 不影响：`.env` 解析格式、速度映射算法（STEP / TICK_MS / carry）、杀停语义、hold/tap 状态机。
- 行为变化对用户可见：Ctrl+滚轮横滚、Shift+滚轮等修饰键组合在脚本运行时恢复原生行为。