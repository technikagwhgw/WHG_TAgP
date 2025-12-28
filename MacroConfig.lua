-- MacroConfig --
-- Konfigurationsdatei für Makros um nicht die Interface Datei ändern zu müssen während der Entwicklung

-- Colors --
Color = {
    red    = "#FF0000",
    green  = "#00FF00",
    blue   = "#0000FF",
    MAgold = "#FFCC00",
    grey   = "#222222",
    cyan   = "#00FFFF",
}

-- Beispielcongiguration --
MacroConfig = {
    ["Spot"] = {
        color = Color.cyan,
        actions = {
            [1] = { 
                name = "Gobo Wheel", 
                cmd = "Attribute 'Gobo1' At +10",
                pos = "2:7"},
            [2] = { 
                name = "Reset Focus",
                cmd = "Attribute 'Focus' At 50" },
            [3] = {
                name = "Reset + Home",
                cmd = {
                    "Group 5 At 100",
                    "Attribute 'Pan' At 0",
                    "Attribute 'Tilt' At 0",
                    "Effect 1 Off"
                },
                pos = "1:3"
            }
        }
    },
    ["Wash"] = {
        color = Color.green,
        actions = {
            [1] = { name = "Wide", cmd = "Attribute 'Zoom' At 100" },
            [2] = { name = "Tight", cmd = "Attribute 'Zoom' At 0" },
        }
    }
}