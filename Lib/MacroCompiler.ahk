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
                txt .= "⏱️ " . delay . "`r`n"
            
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
                    txt .= "⌨️ Down " . data . "`r`n"
                case "KeyUp":
                    txt .= "⌨️ Up " . data . "`r`n"
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
                    ; Format: <Button> <Event> <X>, <Y>
                    txt .= "🖱️ " . btn . " " . evt . " " . x . ", " . y . "`r`n"
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
            
            ; Strip Icons
            line := StrReplace(line, "⌨️", "")
            line := StrReplace(line, "⏱️", "")
            line := StrReplace(line, "🖱️", "")
            line := Trim(line)
            
            ; 1. Delay: Just a number
            if IsNumber(line) {
                pendingDelay += Integer(line)
                continue
            }
            
            newAction := Map()
            newAction["Delay"] := pendingDelay
            
            ; 2. Key: Down/Up KeyName
            match := ""
            if RegExMatch(line, "i)^(Down|Up)\s+(.+)", &match) {
                newAction["Type"] := (match[1] = "Down") ? "KeyDown" : "KeyUp"
                newAction["Data"] := match[2]
                actions.Push(newAction)
                pendingDelay := 0
                continue
            }
            
            ; 3. Mouse: Button Event X, Y
            ; e.g. LButton Down 100, 200
            if RegExMatch(line, "i)^(\w+)\s+(Down|Up)\s+([\d-]+)\s*,\s*([\d-]+)", &match) {
                newAction["Type"] := "Mouse"
                newAction["Data"] := Map(
                    "Button", match[1],
                    "Event", match[2],
                    "X", Integer(match[3]),
                    "Y", Integer(match[4])
                )
                actions.Push(newAction)
                pendingDelay := 0
                continue
            }
            
            ; 4. Legacy Support (Optional, mostly for "Delay 100")
            if (SubStr(line, 1, 5) = "Delay") {
                 parts := StrSplit(line, " ")
                 if (parts.Length > 1 && IsNumber(parts[2]))
                    pendingDelay += Integer(parts[2])
                 continue
            }
        }
        
        return actions
    }
}
