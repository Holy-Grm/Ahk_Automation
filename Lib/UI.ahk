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
