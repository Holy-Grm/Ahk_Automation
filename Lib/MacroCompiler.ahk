class MacroCompiler {
    ; Converts Action List to Simplified Text
    static Decompile(actions) {
        if (!IsObject(actions))
            return ""
            
        txt := ""
        for action in actions {
            ; 1. Handle Delay (Pre-action)
            delay := 0
            if (Type(action) == "Map" && action.Has("Delay"))
                delay := action["Delay"]
            else if (action.HasProp("Delay"))
                delay := action.Delay
                
            if (delay > 0)
                txt .= "Delay " . delay . "`r`n"
            
            ; 2. Handle Action Type
            actionType := ""
            if (Type(action) == "Map" && action.Has("Type"))
                actionType := action["Type"]
            else if (action.HasProp("Type"))
                actionType := action.Type
            
            data := ""
            if (Type(action) == "Map" && action.Has("Data"))
                data := action["Data"]
            else if (action.HasProp("Data"))
                data := action.Data
                
            switch actionType {
                case "KeyDown":
                    txt .= "KeyDown " . data . "`r`n"
                case "KeyUp":
                    txt .= "KeyUp " . data . "`r`n"
                case "Mouse":
                    ; Parse Data: {Button, Event, X, Y}
                    btn := "", evt := "", x := 0, y := 0
                    if (Type(data) == "Map") {
                        btn := data.Get("Button", "LButton")
                        evt := data.Get("Event", "Down")
                        x := data.Get("X", 0)
                        y := data.Get("Y", 0)
                    } else {
                        try btn := data.Button
                        try evt := data.Event
                        try x := data.X
                        try y := data.Y
                    }
                    ; Format: Mouse <Button> <Event> <X>, <Y>
                    txt .= "Mouse " . btn . " " . evt . " " . x . ", " . y . "`r`n"
            }
        }
        return txt
    }
    
    ; Converts Text back to Action List
    static Compile(text) {
        actions := []
        pendingDelay := 0
        
        Loop Parse, text, "`n", "`r" 
        {
            line := Trim(A_LoopField)
            if (line == "" || SubStr(line, 1, 1) == ";")
                continue
                
            parts := StrSplit(line, " ")
            cmd := parts[1]
            
            if (cmd = "Delay") {
                if (parts.Length > 1)
                    pendingDelay += Integer(parts[2])
                continue
            }
            
            newAction := Map()
            newAction["Delay"] := pendingDelay
            pendingDelay := 0 ; Reset consumed delay
            
            switch cmd {
                case "KeyDown":
                    newAction["Type"] := "KeyDown"
                    newAction["Data"] := (parts.Length > 1) ? parts[2] : ""
                    actions.Push(newAction)
                    
                case "KeyUp":
                    newAction["Type"] := "KeyUp"
                    newAction["Data"] := (parts.Length > 1) ? parts[2] : ""
                    actions.Push(newAction)
                    
                case "Mouse":
                    ; Format: Mouse LButton Down 100, 200
                    ; parts: [Mouse, LButton, Down, 100,, 200] (comma might split or not depending on parsing)
                    ; Let's parse the line remainder carefully.
                    
                    ; Improve parsing for Mouse
                    ; Regex might be safer
                    ; ^Mouse\s+(\w+)\s+(\w+)\s+([\d-]+)\s*,\s*([\d-]+)
                    
                    btn := "LButton", evt := "Down", x := 0, y := 0
                    if RegExMatch(line, "i)^Mouse\s+(\w+)\s+(\w+)\s+([\d-]+)\s*,\s*([\d-]+)", &match) {
                        btn := match[1]
                        evt := match[2]
                        x := Integer(match[3])
                        y := Integer(match[4])
                        
                        newAction["Type"] := "Mouse"
                        newAction["Data"] := Map("Button", btn, "Event", evt, "X", x, "Y", y)
                        actions.Push(newAction)
                    }
            }
        }
        
        ; If there is a trailing delay, we lose it because it's not attached to an action.
        ; Alternatively, we could append a dummy action or just ignore it implies end of script wait.
        ; For now, ignore.
        
        return actions
    }
}
