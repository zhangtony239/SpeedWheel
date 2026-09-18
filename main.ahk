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
; 与热键的输入级别相同，因此不会被下方 *WheelUp/*WheelDown
; 热键再次拦截（人工输入仅在 level 高于热键级别时才触发热键），
; 天然避免自吞循环。

; ---------------- 热键注册 ----------------

RegisterTrigger(cfgHotkey, cfgMode)

RegisterTrigger(hk, mode) {
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
    SetTimer ScrollTick, TICK_MS
}

; 唯一的退出路径：停表 + 清零，保证杀停无残留
ExitSpeedMode() {
    global speedMode, speed, carry
    if !speedMode
        return
    speedMode := false
    speed := 0
    carry := 0
    SetTimer ScrollTick, 0
}

; ---------------- 滚轮拦截与速度映射 ----------------

*WheelDown:: {
    global speedMode, speed, STEP
    if speedMode {
        speed += STEP
        return
    }
    Send("{WheelDown}")
}

*WheelUp:: {
    global speedMode, speed, STEP
    if speedMode {
        speed -= STEP
        return
    }
    Send("{WheelUp}")
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
