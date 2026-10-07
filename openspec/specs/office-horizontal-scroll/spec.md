# office-horizontal-scroll Specification

## Purpose

定义 officePatch 变体在 Word/Excel 前台的 Shift+滚轮横向滚动行为，以及它与 SpeedWheel 速度模式的优先级共存语义（速度模式优先，补丁不覆盖 SpeedWheel 本身），并补齐速度模式输出侧在 Office 中按住 Shift 时的横滚速度滚动。

## Requirements

### Requirement: Office 前台 Shift+滚轮重映射为横向滚动
officePatch 变体（`main+officePatch.ahk`）未处于速度模式时，SHALL 在前台窗口为 Word（`ahk_exe WINWORD.EXE`）或 Excel（`ahk_exe EXCEL.EXE`）时将 Shift+WheelUp 重映射为 WheelLeft、Shift+WheelDown 重映射为 WheelRight。重映射作用域 MUST 限定 Word/Excel 前台：其他应用、以及不按住 Shift 的滚轮事件 MUST NOT 被重映射。

#### Scenario: Word 中 Shift+滚轮向下横向滚动
- **WHEN** officePatch 变体处于普通模式、前台为 Word 且用户按住 Shift 向下拨动滚轮
- **THEN** Word 收到 WheelRight 横向滚轮事件，视图横向滚动，且不收到 Shift+WheelDown

#### Scenario: Excel 中 Shift+滚轮向上横向滚动
- **WHEN** officePatch 变体处于普通模式、前台为 Excel 且用户按住 Shift 向上拨动滚轮
- **THEN** Excel 收到 WheelLeft 横向滚轮事件，视图横向滚动

#### Scenario: 非 Office 应用不受影响
- **WHEN** 前台不是 Word/Excel 且用户按住 Shift 拨动滚轮
- **THEN** 应用收到带 Shift 修饰的原生滚轮事件，脚本不做重映射

#### Scenario: Office 中不按 Shift 的滚轮保持原生
- **WHEN** 前台为 Word/Excel 且用户未按住 Shift 拨动滚轮
- **THEN** 滚轮事件按原生语义传递，脚本不做重映射

### Requirement: 速度模式优先于 Office 重映射
速度模式激活期间，Shift+滚轮事件 SHALL 与其他滚轮事件一致地被吸收为速度调节；Office Shift+滚轮重映射 MUST NOT 在速度模式期间生效（MUST NOT 吞掉事件，MUST NOT 发送 WheelLeft/WheelRight）。SpeedWheel 的调速、`{Blind}` 输出与退出杀停语义 MUST 保持不变，补丁 MUST NOT 覆盖速度模式行为。

#### Scenario: 速度模式中 Word 前台 Shift+滚轮被吸收为调速
- **WHEN** 速度模式激活、前台为 Word 且用户按住 Shift 拨动滚轮
- **THEN** 该事件被吸收为速度调节，不发送任何 WheelLeft/WheelRight，速度模式行为与非 Office 应用一致

#### Scenario: 退出速度模式后重映射恢复
- **WHEN** 用户退出速度模式后在 Word/Excel 前台按住 Shift 拨动滚轮
- **THEN** Shift+滚轮重映射重新生效，横向滚动正常

### Requirement: 速度模式输出在 Office+Shift 的横滚速度滚动
速度模式输出侧：当发送时刻前台为 Word/Excel 且物理按住 Shift 时，系统 SHALL 将速度滚动输出发送为 WheelLeft/WheelRight（应用收到不携带 Shift 修饰的横向滚轮事件），实现 Office 中的横滚速度滚动；其他情形 SHALL 保持既有的 `{Blind}` 输出语义。

#### Scenario: Word 前台按住 Shift 的横滚速度滚动
- **WHEN** 速度模式激活、前台为 Word、滚动速度非零且用户按住 Shift
- **THEN** Word 收到不带 Shift 修饰的 WheelLeft/WheelRight 连续横向滚动，速度语义（拨动调速、过零反转、退出杀停）不变

#### Scenario: Office 前台未按住 Shift 保持竖向速度滚动
- **WHEN** 速度模式激活、前台为 Word/Excel、滚动速度非零且用户未按住 Shift
- **THEN** 输出为竖向速度滚动（既有行为不变）

#### Scenario: 非 Office 应用保持 {Blind} 语义
- **WHEN** 速度模式激活、前台不是 Word/Excel、滚动速度非零且用户按住 Shift
- **THEN** 速度滚动输出以 `{Blind}` 携带 Shift，应用按原生语义横滚（如 Chrome）
