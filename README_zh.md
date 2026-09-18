# SpeedWheel

[English](README.md) | [简体中文](README_zh.md)

SpeedWheel 让鼠标滚轮从"拨一下滚一段"变成一个**速度旋钮**。

按住鼠标中键，然后拨动滚轮：滚轮不再每格跳固定距离，而是逐渐积累滚动**速度**。多拨几下就滚得更快，往反方向拨就减速，继续拨还能平滑地掉头反向滚动。松开按键，滚动立刻停止。

它特别适合浏览长页面和长列表：轻轻拨几下就能持续滑行，再也不用和滚轮固定的步长较劲。

## 环境要求

- Windows
- [AutoHotkey v2.0](https://www.autohotkey.com/)

## 快速开始

1. 安装 AutoHotkey v2。
2. 运行 `main.ahk`（双击即可）。
3. 按住鼠标中键，上下拨动滚轮。

## 配置

SpeedWheel 开箱即用。如果想更换触发按键或改变模式的激活方式，在 `main.ahk` 同目录下创建一个 `.env` 文件：

```dotenv
HOTKEY=XButton1
MODE=hold
```

| 配置项 | 默认值 | 可选值 |
| --- | --- | --- |
| `HOTKEY` | `MButton`（鼠标中键） | 任意 [AutoHotkey 热键](https://www.autohotkey.com/docs/v2/Hotkeys.htm)，如 `XButton1`（鼠标第四键）、`RButton`、`^MButton` |
| `MODE` | `hold` | `hold` — 按住期间生效，松开退出；`tap` — 按一下开启，再按一下关闭 |

`.env` 文件是可选的——没有它时，SpeedWheel 使用鼠标中键的 hold 模式。
