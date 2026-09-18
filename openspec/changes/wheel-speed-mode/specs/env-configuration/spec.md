# Spec Delta

## Purpose

定义 `.env` 配置文件的读取与解析契约：`HOTKEY` 与 `MODE` 两个配置项的取值规则、默认值，以及配置缺失或非法时的容错行为。

## ADDED Requirements

### Requirement: 从 .env 读取 HOTKEY
系统启动时 SHALL 读取脚本同目录下的 `.env` 文件，并使用其中 `HOTKEY=` 行的字符串值作为触发速度模式的热键定义（AutoHotkey 热键语法）。`.env` 文件不存在、缺少 `HOTKEY` 行或该行为空时，系统 SHALL 使用默认热键 `MButton`（鼠标中键）。

#### Scenario: .env 中配置了 HOTKEY
- **WHEN** `.env` 文件存在且包含 `HOTKEY=F1`
- **THEN** 系统使用 F1 键作为速度模式的触发热键

#### Scenario: .env 不存在时使用默认中键
- **WHEN** 脚本同目录下不存在 `.env` 文件
- **THEN** 系统使用鼠标中键（MButton）作为触发热键，且不因配置缺失而报错退出

#### Scenario: HOTKEY 行为空
- **WHEN** `.env` 存在但 `HOTKEY=` 的值为空
- **THEN** 系统使用默认热键 MButton

### Requirement: 从 .env 读取 MODE
系统 SHALL 读取 `.env` 中 `MODE=` 行的值作为触发方式：`hold` 表示按住生效、松开退出；`tap` 表示按下切换。`MODE` 缺失、为空或取值不是 `hold`/`tap`（大小写不敏感）时，系统 SHALL 回退为默认值 `hold`。

#### Scenario: MODE 配置为 tap
- **WHEN** `.env` 包含 `MODE=tap`
- **THEN** 系统以 tap 方式触发速度模式（按下切换）

#### Scenario: MODE 配置为非法值
- **WHEN** `.env` 包含 `MODE=press`（非 hold/tap）
- **THEN** 系统回退为默认 hold 模式，且不因非法值而报错退出

#### Scenario: MODE 大小写不敏感
- **WHEN** `.env` 包含 `MODE=HOLD` 或 `MODE=Tap`
- **THEN** 系统分别按 hold / tap 模式运行

### Requirement: .env 解析容错
`.env` 解析 SHALL 忽略空行与以 `#` 开头的注释行，容忍键值两侧的空白字符，且 MUST NOT 因文件中出现未知键而失败。

#### Scenario: 含注释与空行的 .env
- **WHEN** `.env` 包含注释行、空行以及 `HOTKEY = XButton2`（键值两侧带空格）
- **THEN** 系统正确解析出热键 XButton2，忽略注释与空行

#### Scenario: 含未知键的 .env
- **WHEN** `.env` 包含 `FOO=bar` 等未知键
- **THEN** 系统忽略未知键并正常运行
