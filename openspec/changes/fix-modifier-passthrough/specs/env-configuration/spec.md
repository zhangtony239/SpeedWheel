# Spec Delta

## ADDED Requirements

### Requirement: HOTKEY 不允许配置为滚轮键
`.env` 中 `HOTKEY` 的值若为滚轮键（`WheelDown`、`WheelUp`、`WheelLeft`、`WheelRight`，大小写不敏感），系统 SHALL 视为无效配置：回退为默认热键 `MButton`，并以托盘提示告知用户回退，MUST NOT 因该配置而报错退出。理由：滚轮键作为 HOTKEY 会与速度模式期间的滚轮拦截语义冲突，且 hold 模式下滚轮键无可靠的释放事件。

#### Scenario: HOTKEY 配置为 WheelDown
- **WHEN** `.env` 包含 `HOTKEY=WheelDown`
- **THEN** 系统回退为默认热键 MButton，显示托盘提示，且正常运行

#### Scenario: HOTKEY 滚轮键大小写不敏感
- **WHEN** `.env` 包含 `HOTKEY=wheelup`
- **THEN** 系统同样判定为滚轮键并回退为 MButton

#### Scenario: 其他合法热键不受影响
- **WHEN** `.env` 包含 `HOTKEY=XButton2`
- **THEN** 系统正常使用 XButton2 作为触发热键，不触发回退