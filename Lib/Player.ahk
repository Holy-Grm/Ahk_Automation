class Player {
    static IsPlaying := false
    static Mode := "1x" ; 1x, Nx, Loop
    static LoopCount := 1
    static Turbo := false

    static TogglePlayback() {
        if (this.IsPlaying) {
            this.Stop()
        } else {
            this.Play()
        }
    }

    static Play(macroName := "") {
        if (macroName == "")
            macroName := MacroManager.CurrentMacro
        
        actions := MacroManager.GetMacroActions(macroName)
        settings := MacroManager.GetMacroSettings(macroName)

        if (actions.Length == 0) {
            MsgBox("No actions in macro: " . macroName)
            return
        }
        
        ; Apply Settings
        if (settings.Has("Turbo"))
            this.Turbo := settings["Turbo"]
        if (settings.Has("Mode"))
            this.Mode := settings["Mode"]
        if (settings.Has("LoopCount"))
            this.LoopCount := settings["LoopCount"]

        this.IsPlaying := true
        A_IconTip := "Running: " . macroName . "`n[Esc] to Stop"
        
        ; Show OSD
        AppUI.ShowOSD("" . macroName . "`nESC to stop", "0A66C2") ; Bleu linkedin
        
        local counter := 0
        loop {
            if (!this.IsPlaying)
                break
            
            counter++
            this.ExecuteActions(actions)

            if (this.Mode == "1x" && counter >= 1)
                break
            if (this.Mode == "Nx" && counter >= this.LoopCount)
                break
            ; Loop implies infinite, only break on Stop
        }

        this.Stop()
    }

    static Stop() {
        if (this.IsPlaying) {
            this.IsPlaying := false
            A_IconTip := "AHK Automation Tool"
            
            ; Show Finished State (Green) and auto-hide
            AppUI.ShowOSD("Finished", "08A552") ; Green
            SetTimer(ObjBindMethod(AppUI, "HideOSD"), -2000) ; Hide after 2s
        }
    }

    static ExecuteActions(actions) {
        lastTime := 0
        
        for action in actions {
            if (!this.IsPlaying)
                return

            ; Extract properties robustly (Handle Map vs Object)
            aDelay := 0
            aType := ""
            aData := ""
            
            if IsObject(action) {
                if (Type(action) == "Map") {
                    if action.Has("Delay")
                        aDelay := action["Delay"]
                    if action.Has("Type")
                        aType := action["Type"]
                    if action.Has("Data")
                        aData := action["Data"]
                } else {
                    try aDelay := action.Delay
                    try aType := action.Type
                    try aData := action.Data
                }
            }

            ; Handle Delay
            if (aDelay > 0) {
                if (!this.Turbo) {
                    Sleep(aDelay)
                } else {
                    ; Smart Turbo: Cap max delay at 50ms to prevent skipping actions
                    if (aDelay > 20)
                        Sleep(20)
                    else
                        Sleep(aDelay)
                }
            }

            ; Execute
            switch aType {
                case "KeyDown":
                    Send("{" . aData . " Down}")
                case "KeyUp":
                    Send("{" . aData . " Up}")
                case "Mouse":
                    ; Data is also an object/map
                    inputs := aData
                    ix := 0, iy := 0, ibtn := "", ievt := ""
                    
                    if (Type(inputs) == "Map") {
                        if inputs.Has("X")
                            ix := inputs["X"]
                        if inputs.Has("Y")
                            iy := inputs["Y"]
                        if inputs.Has("Button")
                            ibtn := inputs["Button"]
                        if inputs.Has("Event")
                            ievt := inputs["Event"]
                    } else {
                        try ix := inputs.X
                        try iy := inputs.Y
                        try ibtn := inputs.Button
                        try ievt := inputs.Event
                    }
                    
                    ; Normalize Button Names
                    switch ibtn {
                        case "LButton": ibtn := "Left"
                        case "RButton": ibtn := "Right"
                        case "MButton": ibtn := "Middle"
                    }
                    
                    MouseMove(ix, iy)
                    if (ievt == "Down")
                        Click(ibtn . " Down")
                    else
                        Click(ibtn . " Up")
            }
        }
    }
}
