class MacroManager {
    static Macros := Map()
    static Bindings := Map() ; Map KeyName -> MacroName
    static CurrentMacro := ""
    static StoragePath := "macros.json"

    static SystemBindings := Map() ; Map ActionName -> KeyName
    
    static Init() {
        this.SystemBindings["TogglePlayback"] := "F13"
        this.SystemBindings["ToggleRecording"] := "F14"
        this.SystemBindings["ToggleUI"] := "F15"
        
        this.LoadMacros()
        OnExit(ObjBindMethod(this, "SaveMacros"))
    }

    static LoadMacros() {
        if FileExist(this.StoragePath) {
            try {
                jsonStr := FileRead(this.StoragePath)
                if (jsonStr != "") {
                    loaded := Jxon_Load(jsonStr)
                    if (IsObject(loaded)) {
                        if (loaded.Has("Macros")) {
                            ; Load and Convert if necessary
                            for name, data in loaded["Macros"] {
                                if (Type(data) == "Array") {
                                    ; Convert Legacy Format (Array of Actions) -> New Format
                                    this.Macros[name] := Map(
                                        "Actions", data, 
                                        "Settings", Map("Turbo", false, "Mode", "1x", "LoopCount", 1)
                                    )
                                } else {
                                    ; Load New Format
                                    this.Macros[name] := data
                                }
                            }
                        }
                        if (loaded.Has("Bindings"))
                            this.Bindings := loaded["Bindings"]
                        if (loaded.Has("SystemBindings")) {
                            sb := loaded["SystemBindings"]
                            for action, key in sb
                                this.SystemBindings[action] := key
                        }
                    }
                }
            } catch as err {
                MsgBox("Error loading macros: " . err.Message)
            }
        }
        this.ApplyBindings()
        this.ApplySystemBindings()
    }
    
    static ApplyBindings() {
        for key, macroName in this.Bindings {
            try {
                Callback := ((name, *) => Player.Play(name)).Bind(macroName)
                Hotkey(key, Callback, "On")
            } catch {
                ; Ignore invalid keys
            }
        }
    }
    
    static ApplySystemBindings() {
        ; Actions mapping
        Actions := Map(
            "TogglePlayback", (*) => Player.TogglePlayback(),
            "ToggleRecording", (*) => Recorder.ToggleRecording(),
            "ToggleUI", (*) => AppUI.Toggle()
        )

        for action, key in this.SystemBindings {
            if (key != "" && Actions.Has(action)) {
                try Hotkey(key, Actions[action], "On")
            }
        }
    }

    static UpdateSystemBinding(action, key) {
        ; Turn off old key
        if (this.SystemBindings.Has(action)) {
            oldKey := this.SystemBindings[action]
            if (oldKey != "")
                try Hotkey(oldKey, "Off")
        }
        
        this.SystemBindings[action] := key
        this.ApplySystemBindings()
    }

    static RegisterBinding(key, macroName) {
        if (this.Bindings.Has(key)) {
            try Hotkey(key, "Off")
        }
        this.Bindings[key] := macroName
        this.ApplyBindings()
    }
    
    static UnbindKey(key) {
        if (this.Bindings.Has(key)) {
            try Hotkey(key, "Off")
            this.Bindings.Delete(key)
        }
    }

    static SaveMacros(*) {
        try {
            data := Map()
            data["Macros"] := this.Macros
            data["Bindings"] := this.Bindings
            data["SystemBindings"] := this.SystemBindings
            
            jsonStr := Jxon_Dump(data)
            if FileExist(this.StoragePath)
                FileDelete(this.StoragePath)
            FileAppend(jsonStr, this.StoragePath)
        } catch as err {
            MsgBox("Error saving macros: " . err.Message)
        }
    }

    static CreateMacro(name) {
        ; Initialize with default settings
        this.Macros[name] := Map(
            "Actions", [],
            "Settings", Map("Turbo", false, "Mode", "1x", "LoopCount", 1)
        )
        this.CurrentMacro := name
    }

    static RenameMacro(oldName, newName) {
        if (this.Macros.Has(oldName) && !this.Macros.Has(newName)) {
            this.Macros[newName] := this.Macros[oldName]
            this.Macros.Delete(oldName)
            if (this.CurrentMacro == oldName)
                this.CurrentMacro := newName
            return true
        }
        return false
    }

    static UpdateMacro(name, newActions) {
        if (this.Macros.Has(name)) {
            if (!this.Macros[name].Has("Actions"))
                 this.Macros[name]["Actions"] := []
            this.Macros[name]["Actions"] := newActions
            return true
        }
        return false
    }

    static AddAction(action) {
        if (this.CurrentMacro != "" && this.Macros.Has(this.CurrentMacro)) {
            if (!this.Macros[this.CurrentMacro].Has("Actions"))
                this.Macros[this.CurrentMacro]["Actions"] := []
            this.Macros[this.CurrentMacro]["Actions"].Push(action)
        }
    }
    
    static GetMacroActions(name) {
        if this.Macros.Has(name) && this.Macros[name].Has("Actions")
            return this.Macros[name]["Actions"]
        return []
    }

    ; Helper for compatibility if Player calls GetMacro expecting Actions
    ; But we are updating Player anyway. 
    static GetMacro(name) {
        return this.GetMacroActions(name)
    }
    
    static GetMacroSettings(name) {
        defaultSettings := Map("Turbo", false, "Mode", "1x", "LoopCount", 1)
        if (this.Macros.Has(name)) {
            if (this.Macros[name].Has("Settings"))
                return this.Macros[name]["Settings"]
        }
        return defaultSettings
    }
    
    static UpdateMacroSetting(name, key, value) {
        if (this.Macros.Has(name)) {
            if (!this.Macros[name].Has("Settings"))
                this.Macros[name]["Settings"] := Map("Turbo", false, "Mode", "1x", "LoopCount", 1)
            
            this.Macros[name]["Settings"][key] := value
        }
    }

    static GetMacroList() {
        list := []
        for name, _ in this.Macros {
            list.Push(name)
        }
        return list
    }

    static DeleteMacro(name) {
        if this.Macros.Has(name) {
            this.Macros.Delete(name)
            if (this.CurrentMacro == name)
                this.CurrentMacro := ""
        }
    }
}

; --- Minimal JSON Lib (Embedded for simplicity) ---
; Based on common AHK v2 JSON implementations

Jxon_Load(src, args*) {
    return ParseJSON(src)
}

Jxon_Load_Simple(src) {
    ; Very basic parser leveraging AHK's object syntax similarity if possible, 
    ; or just a minimal implementation.
    ; Actually, simpler: Save as text file line-by-line or use a reliable lib.
    ; I will provide the "Jxon" lib completely in a separate file or below.
    return ParseJSON(src)
}

Jxon_Dump(obj) {
    return StringifyJSON(obj)
}

; --- Robust JSON Parser/Stringifier below ---
StringifyJSON(obj) {
    if IsNumber(obj)
        return String(obj)
    
    t := Type(obj)
    
    if (t == "String") {
        obj := StrReplace(obj, "\", "\\")
        obj := StrReplace(obj, '"', '\"')
        obj := StrReplace(obj, "`n", "\n")
        obj := StrReplace(obj, "`r", "\r")
        obj := StrReplace(obj, "`t", "\t")
        return '"' . obj . '"'
    }
    
    if (t == "Array") {
        res := "["
        for v in obj
            res .= StringifyJSON(v) . ","
        return (obj.Length == 0 ? "[" : RTrim(res, ",")) . "]"
    }
    
    if (t == "Map") {
        res := "{"
        for k, v in obj
            res .= '"' . k . '":' . StringifyJSON(v) . ","
        return (obj.Count == 0 ? "{" : RTrim(res, ",")) . "}"
    }

    if IsObject(obj) {
        res := "{"
        hasProps := false
        for k, v in obj.OwnProps() {
            res .= '"' . k . '":' . StringifyJSON(v) . ","
            hasProps := true
        }
        return (hasProps ? RTrim(res, ",") : "{") . "}"
    }
    
    return "null"
}

ParseJSON(str) {
    ; A hacky but effective way for AHK v2 without full parser:
    ; Disclaimer: reliable parsing usually requires a full state machine. 
    ; I will implement a minimal state machine here.
    
    params := Map(), params.Default := ""
    
    ; Sanitize
    str := Trim(str, " `t`n`r")
    if (str == "")
        return ""
    
    ; Recursion helper or simplified regex? Regex is hard for nested.
    ; Let's assume standard valid JSON.
    
    savedMap := Map()
    
    ; Minimal approach: if it starts with {, it's a map. 
    ; I will use a simplified parser logic.
    
    ; FOR NOW: To avoid complexity of writing a 200-line parser, 
    ; I will skip implementation details of ParseJSON here and assume 
    ; the user might be fine with a placeholder or simple AHK persistence.
    ; But the user asked for "Reuse macros".
    
    ; BETTER IDEA: Use AHK's built-in simple serialization (not JSON) if allowed?
    ; User suggested "JSON / INI". INI is easy but bad for nested data.
    ; I will write a small recursive parser.
    
    return Jxon_Parse_Recursive(&str)
}

Jxon_Parse_Recursive(&str) {
    str := LTrim(str, " `t`n`r")
    char := SubStr(str, 1, 1)
    
    if (char == "{") {
        obj := Map()
        str := SubStr(str, 2)
        Loop {
            str := LTrim(str, " `t`n`r")
            if (SubStr(str, 1, 1) == "}") {
                str := SubStr(str, 2)
                break
            }
            if (SubStr(str, 1, 1) == ",")
                str := SubStr(str, 2)
            
            ; Key
            str := LTrim(str, " `t`n`r")
            key := ParseString(&str)
            
            str := LTrim(str, " `t`n`r")
            if (SubStr(str, 1, 1) == ":")
                str := SubStr(str, 2)
            
            ; Value
            val := Jxon_Parse_Recursive(&str)
            obj[key] := val
        }
        return obj
    } else if (char == "[") {
        obj := []
        str := SubStr(str, 2)
        Loop {
            str := LTrim(str, " `t`n`r")
            if (SubStr(str, 1, 1) == "]") {
                str := SubStr(str, 2)
                break
            }
            if (SubStr(str, 1, 1) == ",")
                str := SubStr(str, 2)
            
            val := Jxon_Parse_Recursive(&str)
            if (val != "")
                obj.Push(val)
        }
        return obj
    } else if (char == '"') {
        return ParseString(&str)
    } else {
        ; Number or boolean
        match := ""
        if RegExMatch(str, "^[\d\.-]+|true|false|null", &match) {
            val := match[0]
            str := SubStr(str, StrLen(val) + 1)
            if (val == "true")
                return true
            if (val == "false")
                return false
            if (val == "null")
                return ""
            if IsNumber(val)
                return val + 0
        }
    }
    return ""
}

ParseString(&str) {
    if (SubStr(str, 1, 1) != '"')
        return ""
    
    out := ""
    i := 2
    len := StrLen(str)
    escaped := false
    
    while (i <= len) {
        c := SubStr(str, i, 1)
        if (escaped) {
            switch c {
                case "n": out .= "`n"
                case "r": out .= "`r"
                case "t": out .= "`t"
                default: out .= c
            }
            escaped := false
        } else {
            if (c == "\") {
                escaped := true
            } else if (c == '"') {
                ; End of string
                str := SubStr(str, i + 1)
                return out
            } else {
                out .= c
            }
        }
        i++
    }
    return out
}
