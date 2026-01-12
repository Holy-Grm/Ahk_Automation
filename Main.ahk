#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; Include Libraries
#Include Lib\MacroManager.ahk
#Include Lib\Recorder.ahk
#Include Lib\Player.ahk
#Include Lib\UI.ahk
#Include Lib\MacroCompiler.ahk

; Initialize Macro Manager
MacroManager.Init()

; Show UI on startup
AppUI.Show()

; Tray Icon Setup
A_IconTip := "AHK Automation Tool"
if FileExist("icon.ico") {
    TraySetIcon("icon.ico")
}

; Global Settings
CoordMode "Mouse", "Screen"

; --- Stream Deck Hotkeys ---
; Loaded via MacroManager.Init() -> ApplySystemBindings()

#HotIf Player.IsPlaying
Esc::Player.Stop()
#HotIf

; Debug/Exit
^Esc::ExitApp
