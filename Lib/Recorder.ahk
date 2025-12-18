class Recorder {
    static IsRecording := false
    static StartTime := 0
    static LastActionTime := 0
    static KeyHook := ""
    
    ; Mouse buttons to record
    static MouseKeys := ["LButton", "RButton", "MButton", "WheelUp", "WheelDown"]

    static ToggleRecording() {
        if (this.IsRecording) {
            this.Stop()
            return false ; Stopped
        } else {
            this.Start()
            return true ; Started
        }
    }

    static Start(name := "") {
        if (name == "") {
            i := 1
            Loop {
                name := "Macro" . i
                if (!MacroManager.Macros.Has(name))
                    break
                i++
            }
        }

        ; Always create/reset the macro when recording starts
        MacroManager.CreateMacro(name)
        if (AppUI.MainGui)
            AppUI.RefreshMacroList()

        this.IsRecording := true
        this.StartTime := A_TickCount
        this.LastActionTime := this.StartTime
        
        ; Setup Keyboard Hook
        this.KeyHook := InputHook("V L0") ; Visible input
        this.KeyHook.KeyOpt("{All}", "N") ; Notify on all keys
        this.KeyHook.OnKeyDown := ObjBindMethod(this, "OnKeyDown")
        this.KeyHook.OnKeyUp := ObjBindMethod(this, "OnKeyUp")
        this.KeyHook.Start()

        ; Setup Mouse Hotkeys
        for key in this.MouseKeys {
            Hotkey("~" . key, ObjBindMethod(this, "OnMouse", key, "Down"), "On")
            Hotkey("~" . key . " Up", ObjBindMethod(this, "OnMouse", key, "Up"), "On")
        }

        AppUI.ShowOSD("Recording", "FF0033") ; Rouge youtube
    }

    static Stop() {
        this.IsRecording := false
        
        if (this.KeyHook)
            this.KeyHook.Stop()
        
        ; Turn off mouse hotkeys
        for key in this.MouseKeys {
            try Hotkey("~" . key, "Off")
            try Hotkey("~" . key . " Up", "Off")
        }

        AppUI.ShowOSD("Finished", "008800") ; Green
        SetTimer(ObjBindMethod(AppUI, "HideOSD"), -2000) ; Hide after 2s
        
        if (AppUI.MainGui) {
            AppUI.Show() ; Re-show UI
        }
    }

    static OnKeyDown(ih, vk, sc) {
        keyName := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))
        if (keyName = "F14")
            return
        this.RecordAction("KeyDown", keyName)
    }

    static OnKeyUp(ih, vk, sc) {
        keyName := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))
        if (keyName = "F14")
            return
        this.RecordAction("KeyUp", keyName)
    }

    static OnMouse(key, event, *) {
        MouseGetPos(&x, &y)
        this.RecordAction("Mouse", {Button: key, Event: event, X: x, Y: y})
    }

    static RecordAction(type, data) {
        if (!this.IsRecording)
            return

        currentTime := A_TickCount
        delay := currentTime - this.LastActionTime
        this.LastActionTime := currentTime

        action := {
            Type: type,
            Data: data,
            Delay: delay
        }
        
        MacroManager.AddAction(action)
    }
}
