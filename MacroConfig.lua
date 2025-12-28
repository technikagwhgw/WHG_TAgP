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
                content = "Attribute 'Gobo1' At +10",
                pos = "2:7",
                help = "Generic.help help text hier" },
            [2] = {
                name = "Reset Focus",
                content = "Attribute 'Focus' At 50",
                help = "Generic.help help text hier" },
            [3] = {
                name = "Reset + Home",
                content = {
                    {cmd = "Group 5 At 100",wait = "0.5"},
                    {cmd = "Attribute 'Pan' At 0"},
                    {cmd = "Attribute 'Tilt' At 0"},
                    {cmd = "Effect 1 Off",wait = "Go"}
                },
                pos = "1:3",
                help = "Generic.help help text hier"
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