# SpeedWheel

[English](README.md) | [简体中文](README_zh.md)

SpeedWheel makes your mouse wheel scroll like a **speed dial** instead of a distance dial.

Hold the middle mouse button, then flick the wheel: the wheel no longer jumps a fixed distance per notch — instead it builds up scrolling **speed**. Flick more to go faster, flick the opposite way to slow down, and keep going to reverse direction smoothly. Let go of the button and scrolling stops right away.

It's great for long pages and lists: a couple of gentle flicks keep you gliding, and you're never fighting the wheel's fixed step size.

## Requirements

- Windows
- [AutoHotkey v2.0](https://www.autohotkey.com/)

## Getting started

1. Install AutoHotkey v2.
2. Run `main.ahk` (double-click it).
3. Hold the middle mouse button and flick the wheel up or down.

## Configuration

SpeedWheel works out of the box. If you want to change the trigger button or how the mode is activated, create a `.env` file next to `main.ahk`:

```dotenv
HOTKEY=XButton1
MODE=hold
```

| Key | Default | Values |
| --- | --- | --- |
| `HOTKEY` | `MButton` (middle button) | Any [AutoHotkey hotkey](https://www.autohotkey.com/docs/v2/Hotkeys.htm), e.g. `XButton1` (mouse button 4), `RButton`, `^MButton` |
| `MODE` | `hold` | `hold` — scroll while the button is held; `tap` — press once to start, press again to stop |

The `.env` file is optional — without it, SpeedWheel uses the middle mouse button in hold mode.
