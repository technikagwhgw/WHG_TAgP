-- DimmerManager --
-- Manages LivePage Dimmer

-- Globals --
local debug = _G.LivePage.Debug.Enabled
local DM = _G.LivePage.DimmerManager
local EGroup = DM.ExecutorGroup
local Color = _G.LivePage.Color

-- Lädt gmaDummy, falls nicht in grandMA2 Umgebung
if not gma then require("gmaDummy") end  -- Remove in Prod

-------------------------------------------
--               Functions               --
-------------------------------------------

-- Dimmer Executor Functions --
function ApplyValueChange(T_Exec, T_Dimmer)
    local execData = EGroup[T_Exec]
    if not execData then return end

    execData.Dimmer = T_Dimmer
    EvalDimmer()

    local fTime = GetFadeTime()

    gma.cmd(string.format("Executor %s At %s Fade %s", execData.Exec, execData.Dimmer, fTime))
    gma.cmd(string.format("Appearance Macro %s /color='%s'", execData.Macro, Color.red))

    DM.IsTrackingFade[T_Exec] = true
    gma.timer(function() CheckFading(T_Exec) end, fTime + 0.2, 1) -- fTime + Buffer(0.2s)

    LabelMacro(T_Exec)
end

function CheckFading(T_Exec)
    local execData = EGroup[T_Exec]
    if not T_Exec or not execData then LLog("CheckFading: Ungültiger Executor!", 3) return end

    local handle = gma.show.getobj.handle("Executor " .. execData.Exec)
    local isFading = gma.show.property.get(handle, 'isFading')

    if isFading == "No" or isFading == nil then
        gma.cmd(string.format("Appearance Macro %s /color='%s'", execData.Macro, Color.grey))
        DM.IsTrackingFade[T_Exec] = nil -- Tracking beenden
    else
        gma.timer(function() CheckFading(T_Exec) end, 0.5, 1)
    end
end

function GetFadeTime()
    local handle = gma.show.getobj.handle("Executor " .. DM.fadeTimeFaderName)
    if not handle then return DM.fadeTimeDefault end
    -- Wandelt 0-100% des Faders in Sekunden um
    local faderValue = gma.show.property.get(handle, "fader") or "0"
    return tonumber(faderValue:match("%d+")) / 10 or DM.fadeTimeDefault
end

function EvalSingleDimmer(T_Exec)
    local val = tonumber(EGroup[T_Exec].Dimmer) or 0
    if val > 100 then val = 100 end
    if val < 0 then val = 0 end
    EGroup[T_Exec].Dimmer = tostring(val)
end

function EvalDimmer()
    for key, data in pairs(EGroup) do
        EvalSingleDimmer(key)
    end
end

function ChangeExecDimmer(T_Exec, C_Dimmer)
    T_Dimmer = EGroup[T_Exec].Dimmer + C_Dimmer
    ApplyValueChange(T_Exec, T_Dimmer)
end

-- Flash Plugin Implementation --
function FlashExecutor(T_Exec, FlashDuration)
    local execData = EGroup[T_Exec]
    if not execData then return end

    local duration = FlashDuration or 0.5 -- Standard: Eine halbe Sekunde
    local originalValue = execData.Dimmer -- Merke dir den aktuellen Wert

    gma.cmd(string.format("Executor %s At 100 Fade 0", execData.Exec))
    gma.cmd(string.format("Appearance Macro %s /color='%s'", execData.Macro, Color.MAgold))

    gma.timer(function()    
        gma.cmd(string.format("Executor %s At %s Fade 0.2", execData.Exec, originalValue))

        local endColor = Color.grey
        if DM.IsTrackingFade[T_Exec] then endColor = Color.red end
        gma.cmd(string.format("Appearance Macro %s /color='%s'", execData.Macro, endColor))

        LLog("Flash beendet für: " .. execData.Name, 1)
    end, duration, 1)
end --idk

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
    if not gma.show.getobj.handle("Executor " .. DM.fadeTimeFaderName) then testPassed = false end

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