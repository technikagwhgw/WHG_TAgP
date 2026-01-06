-- Macro LivePage Interface --
-- Verwaltet die Macros für die LivePage

-- Vars --
local debug = _G.LivePage.Debug.Enabled
local MS = _G.LivePage.MacroSettings
local Color = _G.LivePage.Color
-- Functions
local ExecCmd = _G.LivePage.ExecCmd
local LLog = _G.LivePage.LLog

-- Macro Config --
-- Paste MacroConfig here ...
--   ... ... ... ... ...





-- Lädt gmaDummy, falls nicht in grandMA2 Umgebung
if not gma then require("gmaDummy") end  -- Remove in Prod

-------------------------------------------
--               Functions               --
-------------------------------------------

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
    local base = tonumber(MS.macroRoot)
    local sepInx = string.find(Macro_Addr, ":")
    if not sepInx then
        LLog("ConvertMacroAddr: Ungültige Macro Adresse '" .. Macro_Addr .. "'", 4)
        return nil
    end
    local xValue = tonumber(string.sub(Macro_Addr, 1, sepInx - 1))
    local yValue = tonumber(string.sub(Macro_Addr, sepInx + 1))

    if xValue == 0 and yValue == 0 then
        LLog("ConvertMacroAddr: Ungültige Macro Adresse '" .. Macro_Addr .. "' Kein Addresse kleiner RootMacro!", 4)
        return nil
    end

    local macroNumber = (base - 1) + (yValue * MS.macroPageSize + xValue)
    return macroNumber  -- id
end

function UpdateMacroLabels(pageName)
    local pageData = MacroConfig[pageName]
    if not pageData then LLog("Page '"..pageName.."' nicht gefunden", 3) return end

    for i = 0, MS.macroPageSize - 1 do
        ExecCmd(string.format("Label Macro %d \"--\"", MS.macroRoot + i))
    end

    for idx, action in pairs(pageData.actions) do
        local macroID = MS.macroRoot + idx - 1
        local label = tostring(action.name or "Empty")
        ExecCmd(string.format("Label Macro %d \"%s\"", macroID, label))
    end
end

function SyncPageUI(pageName)
    local pageData = MacroConfig[pageName]
    if not pageData or not pageData.actions then return end

    LLog("Syncing UI for Page: " .. pageName, "DEBUG")

    for idx, action in pairs(pageData.actions) do
        local macroID = MS.macroRoot + idx - 1
        local isActive = false

        if action.syncID and action.type then
            isActive = IsContentActive(action.type, action.syncID)
        end

        local colorActive = pageData.color or Color.green
        local finalColor = isActive and colorActive or Color.grey

        ExecCmd(string.format("Appearance Macro %d /color='%s'", macroID, finalColor))
    end
end

function IsContentActive(contentType, id)
    if contentType == "Preset" then
        local handle = gma.show.getobj.handle("Preset " .. id)
        if handle then
            return gma.show.property.get(handle, "active") == "Yes"
        end
    elseif contentType == "Effect" then
        local handle = gma.show.getobj.handle("Effect " .. id)
        return gma.show.property.get(handle, "running") == "Yes"
    end
    return false
end

function ChangePage(name)
    if not MacroConfig[name] then 
        LLog("Seitenwechsel fehlgeschlagen: " .. tostring(name) .. " nicht in Config!", 4)
        return 
    end
    _G.LivePage.CurrentActiveConfig = name
    
    UpdateMacroLabels(name)
    SyncPageUI(name)
    LLog("Page gewechselt: " .. name, "I")
    UpdateStatusDisplay() 
end

function ApplyMacroConfig(pageName, slotIndex)
    local pageData = MacroConfig[pageName]
    if not pageData then return end
    local action = pageData.actions[slotIndex]
    if not action then return end

    local macroID = MS.macroRoot + slotIndex - 1

    ExecCmd("Delete Macro 1." .. macroID .. ".*")

    local indexOffset = 0
    if action.help and _G.LivePage.Debug.Help then
        ExecCmd('Store Macro 1.' .. macroID .. '.1')
        ExecCmd('Set Macro 1.' .. macroID .. '.1 Command "LUA \'LivePage.MacroInterface.CheckHelp(' .. slotIndex .. ')\'"') --Neue Command Idx Methode
        indexOffset = 1
    end
    local content = action.content

    if type(content) == "string" then
        ExecCmd('Store Macro 1.' .. macroID .. '.' .. (1 + indexOffset))
        ExecCmd('Set Macro 1.' .. macroID .. '.' .. (1 + indexOffset) .. ' Command "' .. content .. '"')

    elseif type(content) == "table" then
        for lineIndex, lineData in ipairs(content) do
            local actualLine = lineIndex + indexOffset
            local cmdText = lineData.cmd or ""
            local waitTime = lineData.wait or "0"
            
            ExecCmd('Store Macro 1.' .. macroID .. '.' .. actualLine)
            ExecCmd('Set Macro 1.' .. macroID .. '.' .. actualLine .. ' Command "' .. cmdText .. '"')
            ExecCmd('Set Macro 1.' .. macroID .. '.' .. actualLine .. ' Wait ' .. waitTime)
        end
    end
end

-- Utility Functions --

-- Help --

local isHelpModeActive = false

function ToggleHelpMode()
    isHelpModeActive = not isHelpModeActive
    if isHelpModeActive then
        LLog("Help Mode aktiviert.", 2)
    else
        LLog("Hilfe-Modus beendet.", 2)
    end
end

function CheckHelp(id)
    if isHelpModeActive then
        -- HILFE-MODUS:
        ShowHelp(id)
        ExecCmd("Off Macro @") --Könnte zu Langsam sein eventuell wait = GO nutzen
    end
end

function ShowHelp(id)
    if not _G.LivePage.CurrentActiveConfig then
        gma.gui.msgbox(getExceptionMsg(), "Keine aktive Macro Seite ausgewählt.")
        return
    end

    local action = _G.LivePage.CurrentActiveConfig.actions[id]
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
        LLog("LongPress: START für ID " .. id, 1)
    elseif state == "STOP" then
        local startTime = startTime[id] or 0
        local duration = now - startTime

        -- LongPress
        if duration >= long_press_threshold then
            LLog("LongPress: LONG PRESS erkannt für ID " .. id, 1)
            LongPressAction(id)
        else
            -- DoublePress
            local lastClick = lastClickTime[id] or 0
            if (now - lastClick) <= double_click_threshold then
                LLog("LongPress: DOUBLE PRESS erkannt für ID " .. id, 1)
                DoublePressAction(id)
                lastClickTime[id] = 0 -- Reset
            else
                -- ShortPress
                lastClickTime[id] = now
                gma.timer(function() 
                    if lastClickTime[id] == now then
                        ShortPressAction(id)
                        LLog("SmartPress: KURZER PRESS erkannt für ID " .. id, 1)
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
    ExecCmd("")
end

function LongPressAction(id)
    ExecCmd("")
end

function DoublePressAction(id)
    ExecCmd("")
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
        ExecCmd("Appearance Macro " .. i .. " /color='" .. cfg.inactiveColor .. "'")
    end

    ExecCmd("Appearance Macro " .. ActivId .. " /color='" .. cfg.activeColor .. "'")

    -- Nicht Fest idee hier
    ExecCmd("Preset 1." .. (ActivId - cfg.start + 1))
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

-- Cycle Effect --
local currentStep = {}

function CycleEffect(id)
    local config = cycleConfigs[id]
    if not config then return end

    local step = (currentStep[id] or 0) + 1
    if step > #config then step = 1 end
    currentStep[id] = step

    local action = config[step]

    ExecCmd(action.cmd)

    local macroID = MS.macroRoot + id - 1
    ExecCmd('Label Macro ' .. macroID .. ' "' .. action.name .. '"')
    ExecCmd('Appearance Macro ' .. macroID .. ' /color="' .. action.color .. '"')
end