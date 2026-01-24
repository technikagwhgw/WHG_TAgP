-- MacroConfig --
-- Konfigurationsdatei für Makros um nicht die Interface Datei ändern zu müssen während der Entwicklung

-- Globals --
-- local Color = nil -- lost in Refactor

-- Beispielcongiguration --
--[[
MacroConfig = {
    ["Spot"] = {
        color = Color.cyan,
        actions = {
            [1] = {
                name = "Gobo Wheel", 
                content = "Preset 3.1",
                type = "Preset",
                syncID = "3.1",
                pos = "2:7",
                help = "Wählt das Standard-Gobo aus Pool 3." 
            },
            [2] = {
                name = "Ballyhoo",
                content = {
                    {cmd = "Group 5 At 100", wait = "0.1"},
                    {cmd = "Effect 101 On"}
                },
                type = "Effect",
                syncID = "101",
                help = "Startet Kreis-Bewegung für Spots."
            },
            [3] = {
                name = "Reset + Home",
                content = {
                    {cmd = "Group 5 At 100", wait = "0.5"},
                    {cmd = "Attribute 'Pan' At 0"},
                    {cmd = "Attribute 'Tilt' At 0"},
                    {cmd = "Effect 1 thru 10 Off", wait = "0.1"}
                },
                pos = "1:3",
                help = "Setzt alle Moving Heads in Home-Position."
            }
        }
    },
    ["Wash"] = {
        color = Color.green,
        actions = {
            [1] = { 
                name = "Wide Zoom", 
                content = "Preset 3.5", -- Angenommen 3.5 ist 'Zoom Wide'
                type = "Preset",
                syncID = "3.5"
            },
            [2] = { 
                name = "Flash White", 
                content = {
                    {cmd = "Group 6 At 100", wait = "0.1"},
                    {cmd = "Preset 4.1"}, -- Weiß
                    {cmd = "Group 6 At 0", wait = "1.0"}
                },
                type = "Preset",
                syncID = "4.1" -- Leuchtet, solange Weiß aktiv ist
            },
            -- Platzhalter Button ---
            [3] = {
                name = "NOT ASSIGNED",
                content = "LLog('Button ohne Funktion', 3)",
                help = "Diesen Button in der Config belegen."
            }
        }
    }
}
]]--