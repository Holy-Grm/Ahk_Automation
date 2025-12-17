class AppUI {
    static MainGui := ""
    static IsVisible := false
    static IsRecording := false

    ; --- Player Settings ---
    static TurboMode := false
    
    static SetTurbo(enabled) {
        Player.Turbo := enabled
    }

    static Toggle() {
        if (this.IsVisible) {
            this.Hide()
        } else {
            this.Show()
        }
    }

    static Show() {
        if !this.MainGui {
            this.CreateGui()
        }
        this.MainGui.Show()
        this.IsVisible := true
    }

    static Hide() {
        if this.MainGui {
            this.MainGui.Hide()
        }
        this.IsVisible := false
    }

    static CreateGui() {
        this.MainGui := Gui("+Resize +AlwaysOnTop", "AHK Automation Tool")
        this.MainGui.OnEvent("Close", (*) => this.Hide())
        this.MainGui.SetFont("s10", "Segoe UI")

        ; Macro List
        this.MainGui.Add("Text",, "Saved Macros:")
        this.MacroList := this.MainGui.Add("ListBox", "w300 h200 vMacroList", [])
        this.MacroList.OnEvent("Change", (*) => this.OnMacroSelection())

        ; Controls
        this.MainGui.Add("Button", "w95 Section", "Record New").OnEvent("Click", (*) => this.StartNewRecording())
        this.MainGui.Add("Button", "w95 ys", "Delete").OnEvent("Click", (*) => this.DeleteSelected())
        this.MainGui.Add("Button", "w95 ys", "Rename").OnEvent("Click", (*) => this.RenameSelected())
        this.MainGui.Add("Button", "w95 ys", "Edit Code").OnEvent("Click", (*) => this.EditSelected())
        this.MainGui.Add("Button", "w95 ys", "Bind Key").OnEvent("Click", (*) => this.BindSelected()) 
        this.MainGui.Add("Button", "w95 ys", "Manage Keys").OnEvent("Click", (*) => this.ShowBindingsUI()) ; New Button
        this.MainGui.Add("Button", "w95 xm", "Play").OnEvent("Click", (*) => this.PlaySelected())
        
        ; Playback Settings
        ; Playback Settings
        this.MainGui.Add("GroupBox", "xm w300 h80", "Playback Mode")
        this.Opt1x := this.MainGui.Add("Radio", "xp+10 yp+20 Group Checked", "Run 1x")
        this.Opt1x.OnEvent("Click", (*) => this.SetMode("1x"))
        
        this.OptNx := this.MainGui.Add("Radio", "y+5", "Run N times:")
        this.OptNx.OnEvent("Click", (*) => this.SetMode("Nx"))
        
        this.OptLoop := this.MainGui.Add("Radio", "y+5", "Loop Indefinitely")
        this.OptLoop.OnEvent("Click", (*) => this.SetMode("Loop"))

        ; Edit field for N times (Moved after Radios to prevent group break)
        this.EditN := this.MainGui.Add("Edit", "x+180 yp-27 w50 Number", "1")
        this.EditN.OnEvent("Change", (*) => this.UpdateN())

        ; Turbo Mode
        this.ChkTurbo := this.MainGui.Add("Checkbox", "xm+10 y+20", "Turbo Mode (Skip Delays)")
        this.ChkTurbo.OnEvent("Click", (*) => this.SetTurbo(this.ChkTurbo.Value))

        ; Status
        this.StatusText := this.MainGui.Add("Text", "xm w300 h20 y+20", "Ready")

        this.RefreshMacroList()
    }
    
    static SetMode(mode) {
        Player.Mode := mode
        if (mode == "Nx")
            this.UpdateN()
    }
    
    static UpdateN() {
        val := Integer(this.EditN.Value)
        if (val > 0)
            Player.LoopCount := val
    }

    static RefreshMacroList() {
        if !this.MainGui
            return
        
        macros := MacroManager.GetMacroList()
        this.MacroList.Delete()
        this.MacroList.Add(macros)
        
        if (MacroManager.CurrentMacro != "")
            this.MacroList.Choose(MacroManager.CurrentMacro)
    }

    static OnMacroSelection() {
        selected := this.MacroList.Text
        if (selected) {
            MacroManager.CurrentMacro := selected
            this.StatusText.Value := "Selected: " . selected
        }
    }

    static StartNewRecording() {
        name := InputBox("Enter Macro Name:", "New Macro").Value
        if (name) {
            MacroManager.CreateMacro(name)
            this.RefreshMacroList()
            Recorder.Start()
            this.Hide() ; Hide UI while recording
        }
    }

    static DeleteSelected() {
        selected := this.MacroList.Text
        if (selected) {
            MacroManager.DeleteMacro(selected)
            this.RefreshMacroList()
            this.StatusText.Value := "Deleted: " . selected
        }
    }

    static RenameSelected() {
        selected := this.MacroList.Text
        if (selected) {
            newName := InputBox("Enter New Name:", "Rename Macro",, selected).Value
            if (newName && newName != selected) {
                if MacroManager.RenameMacro(selected, newName) {
                    this.RefreshMacroList()
                    this.MacroList.Choose(newName)
                    this.StatusText.Value := "Renamed to: " . newName
                } else {
                    MsgBox("Error: Name already exists or invalid.")
                }
            }
        }
    }

    static BindSelected() {
        selected := this.MacroList.Text
        if (!selected)
            return

        this.ShowOSD("PRESS KEY TO BIND`n(Esc to Cancel)", "Blue")
        
        ih := InputHook("L1 M") ; Length 1, Modify (block? No, M ensures suppression if we want, but wait.)
        ; User said "does not take into account F1 on windows". 
        ; We need to capture the key name.
        ; InputHook is tricky for F-keys unless we use {All}.
        
        ih := InputHook("L1 T5", "{Esc}") ; Wait for 1 key or 5 seconds or Esc. Capture includes F-keys? No.
        ; Better approach for binding: "KeyWait" loop or InputHook with KeyOpt.
        
        ; Using a robust Key binder:
        ih := InputHook("V0 L0") ; Invisible, no length limit, we rely on OnKeyDown
        ih.KeyOpt("{All}", "N") ; Notify all
        ih.OnKeyDown := ObjBindMethod(this, "OnBindKeyDown", selected, ih)
        ih.Start()
    }
    
    static OnBindKeyDown(macroName, ih, hook, vk, sc) {
        keyName := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))
        hook.Stop()
        this.HideOSD()
        
        if (keyName == "Escape") {
            MsgBox("Binding Cancelled")
            return
        }
        
        if (keyName != "") {
            result := MsgBox("Bind '" . keyName . "' to '" . macroName . "'?", "Confirm Binding", "YesNo")
            if (result == "Yes") {
                MacroManager.RegisterBinding(keyName, macroName)
                MsgBox("Bound " . keyName . " to " . macroName)
            }
        }
    }

    static EditSelected() {
        selected := this.MacroList.Text
        if (!selected)
            return

        actions := MacroManager.GetMacro(selected)
        jsonStr := Jxon_Dump(actions) ; Get JSON string
        
        this.EditGui := Gui("+Owner" . this.MainGui.Hwnd, "Edit Macro: " . selected)
        this.EditGui.Add("Text",, "Edit Raw JSON:")
        this.EditBox := this.EditGui.Add("Edit", "w400 h300 Multi", jsonStr)
        this.EditGui.Add("Button", "w100", "Save").OnEvent("Click", (*) => this.SaveEdit(selected))
        this.EditGui.Show()
    }

    static SaveEdit(name) {
        jsonText := this.EditBox.Value
        try {
            newActions := ParseJSON(jsonText) ; Use the parser we fixed
            if (IsObject(newActions)) {
                MacroManager.UpdateMacro(name, newActions)
                this.EditGui.Destroy()
                MsgBox("Macro updated!")
            } else {
                MsgBox("Error: Invalid Object")
            }
        } catch as err {
            MsgBox("JSON Parse Error: " . err.Message)
        }
    }

    static PlaySelected() {
        selected := this.MacroList.Text
        if (selected) {
            MacroManager.CurrentMacro := selected
            Player.Play()
        }
    }

    static ShowBindingsUI() {
        this.BindingsGui := Gui("+Owner" . this.MainGui.Hwnd, "Manage Bindings")
        this.BindingsGui.Add("Text",, "Active Bindings (Key -> Macro):")
        this.BindingList := this.BindingsGui.Add("ListBox", "w300 h200")
        
        this.BindingsGui.Add("Button", "w300", "Unbind Selected").OnEvent("Click", (*) => this.UnbindSelected())
        
        this.RefreshBindingsList()
        this.BindingsGui.Show()
    }

    static RefreshBindingsList() {
        if (!this.BindingsGui)
            return
            
        this.BindingList.Delete()
        for key, macro in MacroManager.Bindings {
            this.BindingList.Add([key . "  ->  " . macro]) ; Must be an array
        }
    }

    static UnbindSelected() {
        selectedText := this.BindingList.Text
        if (selectedText) {
            ; Format is "Key  ->  Macro"
            parts := Array()
            Loop Parse, selectedText, " "
                if (A_LoopField != "" && A_LoopField != "->" && A_LoopField != " ")
                    parts.Push(A_LoopField)
            
            ; Re-parse specifically 
            ; Actually simplest is to split by "  ->  "
            splitPos := InStr(selectedText, "  ->  ")
            if (splitPos > 0) {
                key := SubStr(selectedText, 1, splitPos - 1)
                MacroManager.UnbindKey(key)
                this.RefreshBindingsList()
                MsgBox("Unbound: " . key)
            }
        }
    }

    static OSD := ""

    static ShowOSD(text, color := "Red") {
        if (this.OSD)
            this.OSD.Destroy()
        
        this.OSD := Gui("+AlwaysOnTop -Caption +ToolWindow +Disabled", "MacroOverlay")
        this.OSD.SetFont("s12 w700", "Segoe UI")
        this.OSD.BackColor := color 
        this.OSD.Add("Text", "cWhite Center", text)
        
        ; Position Top-Left
        this.OSD.Show("x0 y0 NoActivate AutoSize")
    }

    static HideOSD() {
        if (this.OSD)
            this.OSD.Destroy()
        this.OSD := ""
    }
}
