# Spec Delta

## MODIFIED Requirements

### Requirement: 非速度模式下滚轮行为不变
系统未处于速度模式时，MUST NOT 拦截或修改滚轮事件，滚轮 SHALL 保持操作系统原生行为。例外：officePatch 变体（`main+officePatch.ahk`）在 Word/Excel 前台按住 Shift 的滚轮重映射由 `office-horizontal-scroll` 定义并接管；标准构建（`main.ahk`）不受影响。

#### Scenario: 普通模式下滚动滚轮
- **WHEN** 系统处于普通模式且用户拨动滚轮
- **THEN** 滚轮事件按原生语义传递给当前应用，脚本不产生任何合成滚动

#### Scenario: 非 Office 应用 Shift+滚轮保持原生（officePatch 变体）
- **WHEN** officePatch 变体处于普通模式、前台不是 Word/Excel 且用户按住 Shift 拨动滚轮
- **THEN** 当前应用收到带 Shift 修饰的原生滚轮事件，脚本不产生任何合成滚动

### Requirement: 非速度模式修饰键透明与触发热键通配
系统未处于速度模式时，SHALL 保证 Ctrl、Shift、Alt 修饰键完全透传：脚本 MUST NOT 挂载任何滚轮事件钩子，MUST NOT 拦截、抑制或改写任何修饰键事件；除 HOTKEY 本身外，脚本 MUST NOT 常驻拦截任何按键（例外：officePatch 变体在 Word/Excel 前台的 Shift+滚轮热键，见 `office-horizontal-scroll`；其作用域外按键与应用不受影响）。触发热键 MUST 以通配（`*`）形式注册，使 HOTKEY 在任一修饰键按住时仍可触发速度模式（前提：HOTKEY 不是该修饰键本身）；速度模式触发 SHALL 独立于修饰键状态。

#### Scenario: 非速度模式下 Ctrl+滚轮横滚
- **WHEN** 系统处于普通模式且用户按住 Ctrl 拨动滚轮
- **THEN** 当前应用收到带 Ctrl 修饰的原生滚轮事件，横滚（或应用定义的 Ctrl+滚轮行为）正常生效，脚本不产生任何合成滚动

#### Scenario: 非速度模式下 Shift+滚轮横滚
- **WHEN** 系统处于普通模式、当前情形不适用 Office 重映射（标准构建，或 officePatch 变体但前台非 Word/Excel）且用户按住 Shift 拨动滚轮
- **THEN** 当前应用收到带 Shift 修饰的原生滚轮事件，横滚正常生效，脚本不产生任何合成滚动

#### Scenario: 修饰键按住时仍可触发速度模式
- **WHEN** 用户按住 Shift（或 Ctrl / Alt）并按下 HOTKEY，且 HOTKEY 不是该修饰键本身
- **THEN** 速度模式被正常触发（进入/退出语义不变）

#### Scenario: 进入速度模式后钩子生效
- **WHEN** 系统从普通模式进入速度模式
- **THEN** 滚轮事件开始被脚本拦截并解释为速度调节

#### Scenario: 退出速度模式后恢复零拦截
- **WHEN** 系统退出速度模式
- **THEN** 滚轮钩子被注销，滚轮立即恢复完全原生行为，无残留拦截

### Requirement: 速度滚动输出携带修饰键
速度滚动输出 MUST 以 `{Blind}` 方式发送，携带发送时刻物理按住的修饰键，使应用按修饰键原生语义消费速度滚动输出（修饰键透传最终到软件）；未按住修饰键时输出为裸滚轮。例外：officePatch 变体在 Word/Excel 前台且按住 Shift 时，输出 SHALL 为不携带 Shift 的 WheelLeft/WheelRight 横向滚轮（见 `office-horizontal-scroll`）。

#### Scenario: 按住 Shift 时速度滚动为横滚方向
- **WHEN** 速度模式激活、滚动速度非零、用户按住 Shift 且当前情形不适用 Office 横滚输出（如 Chrome，或非 Word/Excel）
- **THEN** 速度滚动输出携带 Shift，应用表现为横滚方向的速度滚动（如 Chrome 横滚加速）

#### Scenario: 未按住修饰键时输出为裸滚轮
- **WHEN** 速度模式激活、滚动速度非零且用户未按住修饰键
- **THEN** 速度滚动输出为裸滚轮，应用表现为竖向速度滚动
