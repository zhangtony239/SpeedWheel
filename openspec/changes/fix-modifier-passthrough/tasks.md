# Tasks

## 1. 滚轮钩子动态化

- [x] 1.1 移除静态 `*WheelDown` / `*WheelUp` 热键定义，改为在 `EnterSpeedMode()` 中以 `Hotkey("*WheelDown", ...)` / `Hotkey("*WheelUp", ...)` 挂载，验证：脚本启动后普通模式拨滚轮，Chrome 收到原生事件（含 Ctrl+滚轮横滚正常）（实现完成；`/Validate` 语法通过，Chrome 侧行为待 4.1 手工确认）
- [x] 1.2 在 `ExitSpeedMode()` 中注销滚轮钩子（`Hotkey("*WheelDown", 0)` 等），验证：hold 松开 / tap 切换退出后，滚轮立即恢复完全原生行为且速度杀停无残留（实现完成，采用 `Hotkey(name, , "Off")` 形式；Chrome 侧行为待 4.1 手工确认）

## 2. 速度模式内修饰键旁路

- [x] 2.1 滚轮钩子处理器内用 `GetKeyState(..., "P")` 检测 Ctrl / Shift / Alt，任一按住时 `Send("{Blind}{Wheel...}")` 透传并 return，不修改 `speed`，验证：速度模式下按住 Ctrl 拨滚轮，应用执行原生 Ctrl+滚轮行为且滚动速度不变（实现完成；Chrome 侧行为待 4.1 手工确认）
- [x] 2.2 确认裸滚轮路径不变（吸收为 speed 增量），验证：速度模式不按修饰键拨滚轮，加速/减速/反转行为与改动前一致（裸滚轮路径代码未变，逻辑等价）
- [x] 2.3 确认 `ScrollTick` 输出保持裸滚轮 `Send`（D3，无代码改动则仅验证），验证：速度滚动期间按住 Ctrl，输出事件仍为裸滚轮、不触发应用修饰键行为（`ScrollTick` 未改动，符合 D3）

## 3. HOTKEY 滚轮键校验

- [x] 3.1 在 `RegisterTrigger` 入口增加大小写不敏感的滚轮键名单校验（WheelDown/WheelUp/WheelLeft/WheelRight），命中走现有回退路径（MButton + TrayTip），验证：`.env` 写 `HOTKEY=WheelDown` 启动脚本，回退 MButton 并出现托盘提示（实现完成，`/Validate` 通过；托盘提示表现待 4.1 手工确认）
- [ ] 3.2 验证合法热键不受影响：`.env` 写 `HOTKEY=XButton2` 启动，XButton2 正常触发速度模式

## 4. 回归验证

- [ ] 4.1 全场景手工回归：非速度模式零拦截（裸滚轮 / Ctrl+滚轮 / Shift+滚轮）、速度模式裸滚轮调速、速度模式修饰键旁路、退出杀停，对照 specs/wheel-speed-mode/spec.md 各 Scenario 逐条确认
- [x] 4.2 运行 `openspec validate "fix-modifier-passthrough"` 确认无 error 级问题（通过，仅余归档顺序 INFO，见 design D5）