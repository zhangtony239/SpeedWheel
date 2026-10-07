# Tasks

## 1. 输入侧：共享调速与 Office 作用域重映射（main+officePatch.ahk）

- [x] 1.1 将 [`WheelDownHandler`](../../../main+officePatch.ahk:175)/[`WheelUpHandler`](../../../main+officePatch.ahk:181) 的调速逻辑抽成共享函数 `AdjustSpeed(delta)` 并让两处理器调用（行为零变化），验证：DEBUG=1 下运行脚本，速度模式拨动滚轮仍按 ±STEP 调速，日志记录与改动前一致
- [x] 1.2 新增 `IsOfficeActive()` 谓词（`WinActive("ahk_exe WINWORD.EXE") || WinActive("ahk_exe EXCEL.EXE")`），验证：仅 Word/Excel 前台返回真（可在 DEBUG 日志输出判定结果确认）
- [x] 1.3 在文件末尾新增 `#HotIf IsOfficeActive()` 作用域块：`+WheelUp`/`+WheelDown` 处理器先判 `speedMode`——激活则调用 `AdjustSpeed()`，未激活则 `SendInput "{WheelLeft}"` / `SendInput "{WheelRight}"`；块尾以裸 `#HotIf` 复位，验证：非速度模式下 Word/Excel 中 Shift+WheelUp/Down 分别横滚向左/向右，Word/Excel 中不按 Shift 的滚轮与其他应用的 Shift+滚轮保持原生

## 2. 输出侧：Office+Shift 横滚速度滚动

- [ ] 2.1 在 [`ScrollTick()`](../../../main+officePatch.ahk:189) 输出前按发送时刻判定：`GetKeyState("Shift", "P")` 且 `IsOfficeActive()` 为真时改发 `SendInput "{WheelLeft n}"` / `SendInput "{WheelRight n}"`（正速度→WheelRight、负速度→WheelLeft），否则原 `{Blind}` 路径一行不动；验证：速度模式下 Word 前台按住 Shift 持续横滚（速度语义、过零反转成立），松开 Shift 立即恢复竖向滚动

## 3. 集成验证

- [ ] 3.1 验证速度模式优先（不覆盖 SpeedWheel）：速度模式激活时在 Word/Excel 前台按住 Shift 拨动滚轮，只产生调速与横滚速度滚动、不出现一次性 WheelLeft/WheelRight 重映射；退出速度模式后 Shift+滚轮重映射立即恢复生效
- [x] 3.2 验证回归不变量：[`main.ahk`](../../../main.ahk) 与 `.env` 解析未被改动（diff 仅涉及 `main+officePatch.ahk`）；hold/tap 进出、退出杀停、Chrome 前台按住 Shift 的 `{Blind}` 横滚速度滚动等既有行为与改动前一致
- [x] 3.3 运行 `openspec validate add-office-shift-wheel-remap` 确认变更产物校验通过
