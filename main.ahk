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
; ============================================================

; ---------------- 配置解析 ----------------

global cfgHotkey := "MButton"   ; 触发热键（AHK 热键语法字符串）
global cfgMode := "hold"        ; "hold" 或 "tap"

LoadEnv(A_ScriptDir "\.env")

LoadEnv(path) {
    global cfgHotkey, cfgMode
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
        switch key {
            case "HOTKEY":
                if (val != "")
                    cfgHotkey := val
            case "MODE":
                m := StrLower(val)
                if (m = "hold" || m = "tap")
                    cfgMode := m
                ; 非法值回退默认 hold
            ; 未知键忽略
        }
    }
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
    for wk in wheelKeys {
        if (StrLower(hk) = StrLower(wk)) {
            TrayTip("HOTKEY 不能配置为滚轮键 `"" hk "`"，已回退为鼠标中键。", "SpeedWheel", "Iconi")
            hk := "MButton"
            break
        }
    }
    try {
        Hotkey(hk, HotkeyDown)
        if (mode = "hold")
            Hotkey(hk " Up", HotkeyUp)
    } catch {
        TrayTip("热键 `"" hk "`" 无效，已回退为鼠标中键。", "SpeedWheel", "Iconi")
        Hotkey("MButton", HotkeyDown)
        if (mode = "hold")
            Hotkey("MButton Up", HotkeyUp)
    }
}

HotkeyDown(*) {
    global speedMode, cfgMode
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
    ExitSpeedMode()
}

; ---------------- 模式状态机 ----------------

EnterSpeedMode() {
    global speedMode, speed, carry
    speedMode := true
    speed := 0
    carry := 0
    ; 动态挂载滚轮钩子：仅速度模式期间拦截，非速度模式零拦截
    Hotkey("*WheelDown", WheelDownHandler)
    Hotkey("*WheelUp", WheelUpHandler)
    SetTimer ScrollTick, TICK_MS
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
}

; ---------------- 滚轮拦截与速度映射 ----------------

; 修饰键旁路：Ctrl/Shift/Alt 任一物理按住时，滚轮事件原样透传
; （{Blind} 保留修饰键），不吸收为速度调节；仅裸滚轮参与调速。
WheelDownHandler(*) {
    global speed, STEP
    if (GetKeyState("Ctrl", "P") || GetKeyState("Shift", "P") || GetKeyState("Alt", "P")) {
        Send("{Blind}{WheelDown}")
        return
    }
    speed += STEP
}

WheelUpHandler(*) {
    global speed, STEP
    if (GetKeyState("Ctrl", "P") || GetKeyState("Shift", "P") || GetKeyState("Alt", "P")) {
        Send("{Blind}{WheelUp}")
        return
    }
    speed -= STEP
}

; ---------------- 滚动输出 ----------------

ScrollTick() {
    global speed, carry
    if (speed = 0)
        return
    total := speed + carry
    n := Integer(total)      ; 向零取整，保留符号
    carry := total - n
    if (n > 0)
        Send("{WheelDown " n "}")
    else if (n < 0)
        Send("{WheelUp " (-n) "}")
}
