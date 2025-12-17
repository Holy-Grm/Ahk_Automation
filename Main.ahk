#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; Include Libraries
#Include Lib\MacroManager.ahk
#Include Lib\Recorder.ahk
#Include Lib\Player.ahk
#Include Lib\UI.ahk

; Initialize
MacroManager.Init()

; Tray Icon Setup
A_IconTip := "AHK Automation Tool"

; Global Settings
CoordMode "Mouse", "Screen"

; --- Stream Deck Hotkeys ---

; F13 : Toggle Playback
F13::Player.TogglePlayback()

; F14 : Toggle Recording
F14::Recorder.ToggleRecording()

; F15 : Toggle UI
F15::AppUI.Toggle()

#HotIf Player.IsPlaying
Esc::Player.Stop()
#HotIf

; Debug/Exit
^Esc::ExitApp
