-- Macro LivePage Interface --
-- Verwaltet die Macros für die LivePage

-- Variables --
local macroRoot = 106 -- 1:0
local macroMax = 164  -- 3:14

-- Macro Config --
-- Paste MacroConfig here

-- Macro Config check
if not MacroConfig then gma.echo("MacroConfig nicht gefunden!") end

-- Lädt gmaDummy, falls nicht in grandMA2 Umgebung
Debug = false                            -- Remove in Prod
if not gma then require("gmaDummy") end  -- Remove in Prod

-------------------------------------------
--               Functions               --
-------------------------------------------

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
 
    local macroNumber = (base - 1) + (yValue) * 15 + xValue
    return macroNumber
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
        
        if action.cmd then
            ApplyMacroConfig(action, macroID)
        else
            if not config.suppressEmpty then
                gma.echo('SelectPage: Kein Action für Macro ' .. macroID)
            end
        end
    end
    gma.feedback("Layout auf " .. PageName .. " umgeschaltet.")
end

function ApplyMacroConfig(action, macroID)
    gma.cmd("Delete Macro 1." .. macroID .. ".*")
    
    if action == "table" then
        for lineIndex, commandText in ipairs(action.cmd) do
            gma.cmd('Store Macro 1.' .. macroID .. '.' .. lineIndex)
            gma.cmd('Set Macro 1.' .. macroID .. '.' .. lineIndex .. ' Command "' .. commandText .. '"')
        end
    else
        gma.cmd('Store Macro 1.' .. macroID .. '.1')
        gma.cmd('Set Macro 1.' .. macroID .. '.1 Command "' .. action.cmd .. '"')
    end
end

-- Utility Functions --

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
                -- SinglePress
                lastClickTime[id] = now
                gma.timer(function() 
                    -- Nur ausführen, wenn in der Zwischenzeit kein Double-Tap war
                    if lastClickTime[id] == now then
                        ShortPressAction(id)
                    end
                end, double_click_threshold, 1)
            end
            
            gma.echo("LongPress: KURZER PRESS erkannt für ID " .. id)
            ShortPressAction(id)
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
        gma.cmd("Appearance Macro " .. i .. " /color=" .. cfg.inactiveColor)
    end

    gma.cmd("Appearance Macro " .. ActivId .. " /color=" .. cfg.activeColor)

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