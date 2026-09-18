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

### Requirement: DEBUG 调试日志开关与行内注释
`.env` 中 `DEBUG=1` 时，系统 SHALL 在脚本目录写调试日志 `speedwheel.log`（每次启动覆盖），记录配置解析、热键注册/触发、速度模式进出与滚轮事件处理决策；未开启或值不为 `1` 时 MUST NOT 写任何日志文件。`.env` 值中的行内注释（` #` 之后的内容）SHALL 被剥离，且 MUST NOT 影响以 `#` 开头的热键值（如 Win 组合热键 `#a`）。

#### Scenario: 开启 DEBUG 输出日志
- **WHEN** `.env` 包含 `DEBUG=1` 且脚本启动
- **THEN** 脚本目录生成/覆盖 `speedwheel.log`，记录配置与运行事件

#### Scenario: 未开启 DEBUG 不产生日志
- **WHEN** `.env` 无 `DEBUG` 键或值不为 `1`
- **THEN** 脚本不写任何日志文件

#### Scenario: 行内注释被剥离
- **WHEN** `.env` 包含 `MODE=hold # hold or tap`
- **THEN** MODE 解析为 `hold`