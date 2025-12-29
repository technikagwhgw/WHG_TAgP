-- DimmerManager --
-- Manages LivePage Dimmer

-- Global Variables --
local fadeTimeFaderName = "100.106"   -- Fade Time Executor
local fadeTimeDefault = 3     -- Standard Fade Zeit
UpdateRate = 0.1        -- Sekunden -- mögliche Verschiebung in LivePageMain.lua
IsTrackingFade = {}     -- Info Variable um Fading zu tracken
local debug = _G.LivePage.Debug.Enabled

-- Executor Group --
EGroup = {
    Exec1 = {
        Name = "LEDUV",
        Exec = "100.101",
        Macro = "20",
        Dimmer = "0",
    },
    Exec2 = {
        Name = "PAR6",
        Exec = "100.102",
        Macro = "21",
        Dimmer = "0",
    },
    Exec3 = {
        Name = "MMH",
        Exec = "100.103",
        Macro = "22",
        Dimmer = "0",
    }
}

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

-- Dimmer Executor Functions --

function ApplyValueChange(T_Exec, T_Dimmer)
    EGroup[T_Exec].Dimmer = T_Dimmer
    EvalDimmer()

    gma.cmd("Executor " .. EGroup[T_Exec].Exec .. " At " .. EGroup[T_Exec].Dimmer .. " Fade " .. FadeTime())
    gma.cmd("Appearance Macro " .. EGroup[T_Exec].Macro .. " Color " .. Color.red)
    
    IsTrackingFade[T_Exec] = true
    gma.timer(function() CheckFading(T_Exec) end, FadeTime(), 1)

    LabelMacro(T_Exec)
end

function CheckFading(T_Exec)
    if not T_Exec or not EGroup[T_Exec] then LLog("CheckFading: Ungültiger Executor!", 3) return end
    
    local handle = gma.show.getobj.handle("Executor " .. EGroup[T_Exec].Exec)
    local isFading = gma.show.property.get(handle, 'isFading')

    if isFading == "No" or isFading == nil then
        gma.cmd("Appearance Macro " .. EGroup[T_Exec].Macro .. " /color='" .. Color.green .. "'")
        IsTrackingFade[T_Exec] = nil -- Tracking beenden
    else
        
        gma.timer(function() CheckFading(T_Exec) end, UpdateRate, 1)
    end
end

function FadeTime()
    return tonumber(gma.show.getvar("fader_" .. fadeTimeFaderName)) or fadeTimeDefault
end

function EvalDimmer()
    for key, data in pairs(EGroup) do
        if data.Dimmer then
            local dimmer_value = tonumber(data.Dimmer)
            if dimmer_value > 100 then
                data.Dimmer = 100
            elseif dimmer_value < 0 then
                data.Dimmer = 0
            end
        end
    end
end

function ChangeExecDimmer(T_Exec, C_Dimmer)
    T_Dimmer = EGroup[T_Exec].Dimmer + C_Dimmer
    ApplyValueChange(T_Exec, T_Dimmer)
end

-- Macro Functions --

function LabelMacro(T_Exec)
    Macro = EGroup[T_Exec].Macro
    Dimmer = EGroup[T_Exec].Dimmer
    Label = EGroup[T_Exec].Name .. "-" .. Dimmer
    gma.cmd("Label Macro " .. Macro .. " " .. Label)
end

function SetPopUp(T_Exec)
    UserInput = gma.textinput("Dimmer Wert für " .. EGroup[T_Exec].Name .. " eingeben", EGroup[T_Exec].Dimmer)
    ApplyValueChange(T_Exec, UserInput)
end

-- Initialisierung Test --

function ExecTest()
    local testPassed = true
    for key, data in pairs(EGroup) do
        ExecState = gma.show.getobj.handle("Executor " .. data.Exec)
        if not ExecState then
            gma.gui.msgbox("Fehler", "Executor " .. data.Exec .. " für " .. data.Name .. " nicht gefunden!")
            testPassed = false
        end
    end
    if not gma.show.getobj.handle("Executor " .. fadeTimeFaderName) then testPassed = false end

    -- Ausgabe des Testergebnisses --
    if not testPassed then
        LLog("DIMMER MANAGER: DATA HANDLE NOT FOUND!", 4)
        return false
    else
        LLog("DIMMER MANAGER: INITIALISIERUNG ERFOLGREICH", 2)
        return true
    end
end

-- Funktionen Test --
if debug and not _G.LivePage.Debug.Prod then -- Remove in Prod
    print("\n------------------------------------\n")
    print("ApplyValueChange Exec1 auf 0\n")
    ApplyValueChange("Exec1", 0)
    print("\n")
    
    print("ChangeExecDimmer Exec1 um 10 erhöhen\n")
    ChangeExecDimmer("Exec2", 10)
    print("\n")
    
    print("SetPopUp Exec3\n")
    SetPopUp("Exec3")
end