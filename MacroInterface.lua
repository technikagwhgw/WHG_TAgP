-- Macro LivePage Interface --
-- Verwaltet die Macros für die LivePage

-- Variables --
local macroRoot = 106 -- 1:0
local macroMax = 164  -- 3:14
local macroPageSize = 15

CurrentActiveConfig = nil
local enableHelp = true
Debug = true

-- Macro Config --
-- Paste MacroConfig here ...





-- Colors --
Color = {
    red    = "#FF0000",
    green  = "#00FF00",
    blue   = "#0000FF",
    MAgold = "#FFCC00",
    grey   = "#222222",
    cyan   = "#00FFFF",
}

-- Lädt gmaDummy, falls nicht in grandMA2 Umgebung
if not gma then require("gmaDummy") end  -- Remove in Prod

-------------------------------------------
--               Functions               --
-------------------------------------------

function ValidateConfig()
    gma.echo("--- Starte Config Check ---")
    local errorCount = 0

    if not MacroConfig then 
        gma.gui.msgbox("ERROR", "MacroConfig Tabelle existiert nicht!")
        return false 
    end

    for pageName, pageData in pairs(MacroConfig) do
        -- Check 1: Actions
        if not pageData.actions then
            gma.echo("FEHLER: Seite '" .. pageName .. "' hat keine 'actions' Tabelle!")
            errorCount = errorCount + 1
        else
            for idx, action in pairs(pageData.actions) do
                -- Check 2: Content-Typ 
                if type(action.content) ~= "string" and type(action.content) ~= "table" then
                    gma.echo("SYNTAX FEHLER: Action [" .. idx .. "] in '" .. pageName .. "' hat ungültigen Content!")
                    errorCount = errorCount + 1
                end
                -- Check 3: Komma-Fehler (Leere Einträge)
                if not action then
                    gma.echo("WARNUNG: Lücke in der Tabelle bei ID " .. idx .. " auf Seite '" .. pageName .. "' gefunden!")
                end
            end
        end
    end

    if errorCount > 0 then
        gma.gui.msgbox("Config Fehler", "Es wurden " .. errorCount .. " Fehler gefunden! Siehe Command Line für Informationen.")
        return false
    end
    
    gma.echo("--- Config Check erfolgreich ---")
    return true
end

local status, err = pcall(function() 
    ValidateConfig()
end)

if not status then
    gma.gui.msgbox("Fatal Syntax Error", "Deine Config hat einen schweren Fehler: " .. err)
end



-- Fun Functions --
local function weightedRandom(items)
    local sum = 0
    for _, item in ipairs(items) do
        sum = sum + item.weight
    end

    local rand = math.random() * sum
    local current = 0

    for _, item in ipairs(items) do
        current = current + item.weight
        if rand <= current then
            return item.value
        end
    end
end
-- Langweilige Funktion geh weiter
local exceptionMsg = {{weight=1, value="Ohh No"},{weight=10, value="Erwarteter Fehler"},{weight=5, value="Warum? Darum ->"},{weight=4, value="Fehler Freie Operation zur Zeit nicht erreichbar"},{weight=10, value="Sorry .."},{weight=1, value="Fehler 666: Teufel im System"},{weight=5, value="Nein"},{weight=10, value="Fehler: Fehler"},{weight=1, value="Fehlerhafte Fehlermeldung (jk): Fehler"},{weight=20, value="Fehler"},{weight=20, value="Error"},{weight=7, value="Hahaha"},{weight=5, value="Ups"},{weight=5, value="Idk"},{weight=6, value="Fehler: Hilfe benötigt"},{weight=2, value="DU BIST SCHULD"},{weight=5, value="Was"},{weight=10, value="Unerwartet"},{weight=3, value="Fakt: Aeneas Plugin Produziert keine Fehler"},{weight=8, value="Ahhhhhhhhhhhh"},{weight=2, value="GUTEN TAG"},{weight=1, value="Schlechter Tag"},{weight=5, value="Ich entschuldige mich für den Fehler"},{weight=5, value="Unvermeidbar"},{weight=1, value="Ich kann dich nicht hören"},{weight=15, value="Du solltest das nicht sehen"},{weight=2, value="404: Fehler nicht gefunden"},{weight=2, value="Fehler: 404 nicht gefunden"},{weight=1, value="Nicht gefunden: 404 Fehler"},{weight=1, value="Niemand mag Fehler"},{weight=2, value="Ich glaube an dich"},
}
local function getExceptionMsg()
    return weightedRandom(exceptionMsg)
end


-- TODO: M420 format für Addressen unterstützen (M gefolgt von Addresse 1d Array)
-- TODO: Generelle Definition für ID einführen aktuell sehr wage definiert
function ConvertMacroAddr(Macro_Addr)
    -- Beispiel Page0 "1:0" -> "106"
    local base = tonumber(macroRoot)
    local sepInx = string.find(Macro_Addr, ":")
    if not sepInx then
        gma.echo("ConvertMacroAddr: Ungültige Macro Adresse '" .. Macro_Addr .. "'")
        return nil
    end
    local xValue = tonumber(string.sub(Macro_Addr, 1, sepInx - 1))
    local yValue = tonumber(string.sub(Macro_Addr, sepInx + 1))

    if xValue == 0 and yValue == 0 then
        gma.echo("ConvertMacroAddr: Ungültige Macro Adresse '" .. Macro_Addr .. "' Kein Addresse kleiner RootMacro!")
        return nil
    end

    local macroNumber = (base - 1) + (yValue * macroPageSize + xValue)
    return macroNumber  -- id
end

function SelectPage(PageName)
    local config = MacroConfig[PageName]
    if not config then 
        gma.echo("SelectPage: Seite '" .. PageName .. "' nicht in MacroConfig gefunden!")
        return nil
    end
    
    for i = 1, macroMax - macroRoot do
        local macroID = macroRoot + i - 1
        local action = config.actions[i]
    
        -- Pos Override
        if action.pos then
            local convertedID = ConvertMacroAddr(action.pos)
            if convertedID then
                macroID = convertedID
            end
        end

        if action.content then
            ApplyMacroConfig(action, macroID)
        else
            if not config.suppressEmpty then
                gma.echo('SelectPage: Kein Action für Macro ' .. macroID)
            end
        end
    end
    gma.feedback("Layout auf " .. PageName .. " umgeschaltet.")
    CurrentActiveConfig = config
end

function ApplyMacroConfig(action, macroID)
    local indexOffset = 0
    gma.cmd("Delete Macro 1." .. macroID .. ".*")
    
    if action.help and enableHelp then
        gma.cmd('Store Macro 1.' .. macroID .. '.1')
        gma.cmd('Set Macro 1.' .. macroID .. '.1 Command "CheckHelp(' .. macroID .. ')"')
        indexOffset = 1
    end

    for lineIndex, lineData in ipairs(action.content) do
        local lineIndex = lineIndex + indexOffset
        local cmdText = ""
        local waitTime = "0" -- Default = 0
        
        if type(lineData) == "table" then
            cmdText = lineData.cmd or ""
            waitTime = lineData.wait or "0"
        else
            cmdText = lineData
        end
        gma.cmd('Store Macro 1.' .. macroID .. '.' .. lineIndex)
        
        gma.cmd('Set Macro 1.' .. macroID .. '.' .. lineIndex .. ' Command "' .. cmdText .. '"')
        gma.cmd('Set Macro 1.' .. macroID .. '.' .. lineIndex .. ' Wait ' .. waitTime)
    end
end

-- Utility Functions --

-- Help --

local isHelpModeActive = false

function ToggleHelpMode()
    isHelpModeActive = not isHelpModeActive
    if isHelpModeActive then
        gma.echo("Help Mode aktiviert.")
    else
        gma.echo("Hilfe-Modus beendet.")
    end
end

function CheckHelp(id)
    if isHelpModeActive then
        -- HILFE-MODUS:
        ShowHelp(id)
        gma.cmd("Off Macro @") --Könnte zu Langsam sein eventuell go nutzen
    end
end

function ShowHelp(id)
    if not CurrentActiveConfig then
        gma.gui.msgbox(getExceptionMsg(), "Keine aktive Macro Seite ausgewählt.")
        return
    end

    local action = CurrentActiveConfig.actions[id]
    if action and action.help then
        gma.gui.msgbox("Hilfe: " .. action.name, action.help)
    else
        gma.gui.msgbox(getExceptionMsg(), "Keine Hilfe für ID " .. id .. " hinterlegt.")
    end
end


-- Smart Button --

local startTime = {}
local lastClickTime = {}

local long_press_threshold = 0.5   -- Sekunden (Konfig)
local double_click_threshold = 0.3 -- Sekunden (Konfig)


function SmartPress(state, id)
    local now = gma.gettime()

    if state == "START" then
        startTime[id] = now
        gma.echo("LongPress: START für ID " .. id)
    elseif state == "STOP" then
        local startTime = startTime[id] or 0
        local duration = now - startTime

        -- LongPress
        if duration >= long_press_threshold then
            gma.echo("LongPress: LONG PRESS erkannt für ID " .. id)
            LongPressAction(id)
        else
            -- DoublePress
            local lastClick = lastClickTime[id] or 0
            if (now - lastClick) <= double_click_threshold then
                gma.echo("LongPress: DOUBLE PRESS erkannt für ID " .. id)
                DoublePressAction(id)
                lastClickTime[id] = 0 -- Reset
            else
                -- ShortPress
                lastClickTime[id] = now
                gma.timer(function() 
                    -- Nur ausführen, wenn in der Zwischenzeit kein Double-Tap war
                    if lastClickTime[id] == now then
                        ShortPressAction(id)
                        gma.echo("SmartPress: KURZER PRESS erkannt für ID " .. id)
                    end
                end, double_click_threshold, 1)
            end
        end

        startTime[id] = nil
    end

end -- Sorry (Aeneas)


-- Aktionen --
-- TODO: Preset Für Action nutzen ?

function ShortPressAction(id)
    gma.cmd("")
end

function LongPressAction(id)
    gma.cmd("")
end

function DoublePressAction(id)
    gma.cmd("")
end

-- Radio Select --
local radioGroups = {
    ["Group"] = {start=106, stop=120, activeColor=Color.green, inactiveColor=Color.grey}, --PlaceholderValues
    ["Color"] = {start=121, stop=130, activeColor=Color.green, inactiveColor=Color.grey},
    ["Gobo"] = {start=131, stop=140, activeColor=Color.green, inactiveColor=Color.grey},
    ["Effect"] = {start=141, stop=150, activeColor=Color.green, inactiveColor=Color.grey},
}

function RadioSelect(Select_Group,ActivId)
    local cfg = radioGroups[Select_Group]
    if not cfg then return end

    for i = cfg.start, cfg.stop do
        gma.cmd("Appearance Macro " .. i .. " /color='" .. cfg.inactiveColor .. "'")
    end

    gma.cmd("Appearance Macro " .. ActivId .. " /color='" .. cfg.activeColor .. "'")

    -- Nicht Fest idee hier
    gma.cmd("Preset 1." .. (ActivId - cfg.start + 1))
end

-- Cycle Select --
local cycleConfigs = {
    [1] = { -- ID 1: PlaceholderValues
        { name = "Pos 1", cmd = "Go Effect 1", color = Color.cyan }, -- Cyan
        { name = "Pos 2", cmd = "Go Effect 2", color = Color.blue }, -- Blau
        { name = "Pos 3", cmd = "Go Effect 3", color = Color.magenta }, -- Magenta
        { name = "STOP Cycle", cmd = "Off Effect 1 thru 3", color = Color.grey } -- Aus
    },
    [2] = { -- ID 2: PlaceholderValues
        { name = "Slow", cmd = "Attribute 'Shutter' At 10", color = Color.red},
        { name = "Fast", cmd = "Attribute 'Shutter' At 80", color = Color.green},
        { name = "Off", cmd = "Attribute 'Shutter' At 100", color = Color.grey}, -- Aus
    }
}

-- Interner Zähler --
local currentStep = {}

function CycleEffect(id)
    local config = cycleConfigs[id]
    if not config then return end

    local step = (currentStep[id] or 0) + 1
    if step > #config then step = 1 end
    currentStep[id] = step

    local action = config[step]

    gma.cmd(action.cmd)

    local macroID = macroRoot + id - 1
    gma.cmd('Label Macro ' .. macroID .. ' "' .. action.name .. '"')
    gma.cmd('Appearance Macro ' .. macroID .. ' /color="' .. action.color .. '"')
end