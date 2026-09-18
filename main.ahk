#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; SpeedWheel — 鼠标滚轮速度调控模式
;
; 进入速度模式后，滚轮的拨动量决定持续滚动的"速度"而非距离；
; 反向拨动即减速，速度过零后自然反转为反方向滚动。
; 退出速度模式（hold 松开 / tap 再按）时立即杀停一切滚动。
;
; 配置：脚本同目录下的 .env 文件（可缺失，缺失时用默认值）
;   HOTKEY=MButton   触发热键（AHK 热键语法），默认鼠标中键
;   MODE=hold        hold=按住生效松开退出；tap=按下切换。默认 hold
;   DEBUG=1          输出调试日志到脚本目录 speedwheel.log（缺省关闭）
; ============================================================

; ---------------- 配置解析 ----------------

global cfgHotkey := "MButton"   ; 触发热键（AHK 热键语法字符串）
global cfgMode := "hold"        ; "hold" 或 "tap"
global cfgDebug := false        ; DEBUG=1 时输出调试日志
global logPath := ""            ; 调试日志文件路径

LoadEnv(A_ScriptDir "\.env")

; DEBUG=1 时初始化日志：每次启动覆盖旧日志，避免跨次运行混淆
if (cfgDebug) {
    logPath := A_ScriptDir "\speedwheel.log"
    try FileDelete(logPath)
    LogMsg("=== SpeedWheel 启动 ===")
    LogMsg("配置: HOTKEY=" cfgHotkey "  MODE=" cfgMode "  DEBUG=1")
}

LoadEnv(path) {
    global cfgHotkey, cfgMode, cfgDebug
    local text := ""
    try text := FileRead(path)
    if (text = "")
        return  ; 文件缺失或为空：全部走默认值
    for line in StrSplit(text, "`n", "`r") {
        line := Trim(line)
        if (line = "" || SubStr(line, 1, 1) = "#")
            continue  ; 跳过空行与注释
        eq := InStr(line, "=")
        if !eq
            continue  ; 无 "=" 的行忽略
        key := Trim(SubStr(line, 1, eq - 1))
        val := Trim(SubStr(line, eq + 1))
        ; 去除行内注释（仅识别 " #"，避免误伤以 # 开头的 Win 组合热键如 "#a"）
        cpos := InStr(val, " #")
        if cpos
            val := Trim(SubStr(val, 1, cpos - 1))
        switch key {
            case "HOTKEY":
                if (val != "")
                    cfgHotkey := val
            case "MODE":
                m := StrLower(val)
                if (m = "hold" || m = "tap")
                    cfgMode := m
                ; 非法值回退默认 hold
            case "DEBUG":
                if (val = "1")
                    cfgDebug := true
            ; 未知键忽略
        }
    }
}

; 调试日志：仅 DEBUG=1 时写入脚本目录 speedwheel.log（UTF-8 带 BOM，记事本/控制台均可直读）
LogMsg(msg) {
    global cfgDebug, logPath
    if !cfgDebug || (logPath = "")
        return
    try FileAppend("[" FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") "." Format("{:03}", A_MSec) "] " msg "`n", logPath, "UTF-8")
}

; ---------------- 状态 ----------------

global speedMode := false   ; 是否处于速度模式
global speed := 0.0         ; 有符号速度（行/tick），正=向下，负=向上
global carry := 0.0         ; 亚行精度累积器
global STEP := 0.25         ; 每次拨动的速度增量（行/tick）
global TICK_MS := 10        ; 滚动定时器周期（ms）

; 说明：本脚本 Send 产生的合成滚轮事件 SendLevel 为默认 0，
; 不会触发本脚本注册的 level-0 热键（人工输入仅在 level 高于
; 热键级别时才触发热键），天然避免自吞循环。
; 滚轮钩子为动态注册：仅速度模式期间挂载（见 EnterSpeedMode），
; 非速度模式零拦截，滚轮保持完全原生行为。

; ---------------- 热键注册 ----------------

RegisterTrigger(cfgHotkey, cfgMode)

RegisterTrigger(hk, mode) {
    ; 滚轮键不可作 HOTKEY：与速度模式滚轮拦截语义冲突，且 hold 模式下无可靠 Up 事件
    wheelKeys := ["WheelDown", "WheelUp", "WheelLeft", "WheelRight"]
    LogMsg("RegisterTrigger: 请求 HOTKEY=" hk "  MODE=" mode)
    for wk in wheelKeys {
        if (StrLower(hk) = StrLower(wk)) {
            TrayTip("HOTKEY 不能配置为滚轮键 `"" hk "`"，已回退为鼠标中键。", "SpeedWheel", "Iconi")
            LogMsg("RegisterTrigger: HOTKEY 为滚轮键，回退 MButton")
            hk := "MButton"
            break
        }
    }
    ; `*` 通配注册：修饰键（Ctrl/Shift/Alt）按住时 HOTKEY 仍可触发速度模式，
    ; 触发独立于修饰键状态（HOTKEY 本身配置为修饰键的情形属用户自行选择，不在脚本侧特判）
    try {
        Hotkey("*" hk, HotkeyDown)
        if (mode = "hold")
            Hotkey("*" hk " Up", HotkeyUp)
        LogMsg("RegisterTrigger: 已注册 *" hk (mode = "hold" ? " 及其 Up 事件（通配）" : "（通配）"))
    } catch {
        TrayTip("热键 `"" hk "`" 无效，已回退为鼠标中键。", "SpeedWheel", "Iconi")
        LogMsg("RegisterTrigger: 热键无效，回退 MButton")
        Hotkey("*MButton", HotkeyDown)
        if (mode = "hold")
            Hotkey("*MButton Up", HotkeyUp)
    }
}

HotkeyDown(*) {
    global speedMode, cfgMode
    LogMsg("HotkeyDown: 触发 (speedMode=" speedMode "  cfgMode=" cfgMode ")")
    if (cfgMode = "tap") {
        if speedMode
            ExitSpeedMode()
        else
            EnterSpeedMode()
    } else {
        EnterSpeedMode()
    }
}

HotkeyUp(*) {
    LogMsg("HotkeyUp: 触发")
    ExitSpeedMode()
}

; ---------------- 模式状态机 ----------------

EnterSpeedMode() {
    global speedMode, speed, carry
    speedMode := true
    speed := 0
    carry := 0
    ; 动态挂载滚轮钩子：仅速度模式期间拦截，非速度模式零拦截。
    ; 必须显式传 "On"：Hotkey() 对已存在的热键省略 Options 时保留原 On/Off 状态，
    ; 若 ExitSpeedMode 曾以 "Off" 禁用，省略会导致第二次进入后钩子仍被禁用。
    Hotkey("*WheelDown", WheelDownHandler, "On")
    Hotkey("*WheelUp", WheelUpHandler, "On")
    SetTimer ScrollTick, TICK_MS
    LogMsg("EnterSpeedMode: 进入速度模式，滚轮钩子已挂载")
}

; 唯一的退出路径：停表 + 清零 + 注销钩子，保证杀停无残留
ExitSpeedMode() {
    global speedMode, speed, carry
    if !speedMode
        return
    speedMode := false
    speed := 0
    carry := 0
    SetTimer ScrollTick, 0
    Hotkey("*WheelDown", , "Off")
    Hotkey("*WheelUp", , "Off")
    LogMsg("ExitSpeedMode: 退出速度模式，滚轮钩子已注销")
}

; ---------------- 滚轮拦截与速度映射 ----------------

; 速度模式内滚轮全量吸收（D2 修订）：Ctrl/Shift/Alt 组合也参与调速，不做旁路；
; 修饰键语义由输出侧 {Blind} 保留并作用于速度滚动（D3 修订，横滚速度模式）。
WheelDownHandler(*) {
    global speed, STEP
    speed += STEP
    LogMsg("WheelDown: 吸收为速度增量 (speed=" speed "  Ctrl=" GetKeyState("Ctrl", "P") " Shift=" GetKeyState("Shift", "P") " Alt=" GetKeyState("Alt", "P") ")")
}

WheelUpHandler(*) {
    global speed, STEP
    speed -= STEP
    LogMsg("WheelUp: 吸收为速度增量 (speed=" speed "  Ctrl=" GetKeyState("Ctrl", "P") " Shift=" GetKeyState("Shift", "P") " Alt=" GetKeyState("Alt", "P") ")")
}

; ---------------- 滚动输出 ----------------

ScrollTick() {
    global speed, carry
    if (speed = 0)
        return
    total := speed + carry
    n := Integer(total)      ; 向零取整，保留符号
    carry := total - n
    ; {Blind}（D3 修订）：携带发送时刻物理按住的修饰键，修饰键透传最终到软件——
    ; 按住 Shift 时应用表现为横滚方向的速度滚动，未按住时为裸滚轮竖向滚动。
    if (n > 0)
        Send("{Blind}{WheelDown " n "}")
    else if (n < 0)
        Send("{Blind}{WheelUp " (-n) "}")
}
