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

        if action.pos then
            local convertedID = ConvertMacroAddr(action.pos)
            if convertedID then
                macroID = convertedID
            end
        end
        
        if action then
            gma.cmd('Set Macro 1.' .. macroID .. '.1 Command "' .. action.cmd .. '"')
            gma.cmd('Label Macro ' .. macroID .. ' "' .. action.name .. '"')
            gma.cmd('Appearance Macro ' .. macroID .. ' /color="' .. config.color .. '"')
        else
        -- Macro leeren/ausgrauen, falls für diesen Typ kein Config definiert ist
            gma.cmd('Set Macro 1.' .. macroID .. '.1 Command ""')
            gma.cmd('Label Macro ' .. macroID .. ' "-"')
            gma.cmd('Appearance Macro ' .. macroID .. ' /r=20 /g=20 /b=20')
            if not config.suppressEmpty then
                gma.echo('SelectPage: Kein Action für Macro ' .. macroID .. ' in Seite "' .. PageName .. '" definiert.')
            end
        end
    end
    gma.feedback("Layout auf " .. PageName .. " umgeschaltet.")
end