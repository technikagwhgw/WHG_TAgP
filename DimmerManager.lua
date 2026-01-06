-- DimmerManager --
-- Manages LivePage Dimmer

-- Vars --
local debug = _G.LivePage.Debug.Enabled
local DM = _G.LivePage.DimmerManager
local EGroup = DM.ExecutorGroup
local Color = _G.LivePage.Color
-- Functions
local ExecCmd = _G.LivePage.ExecCmd
local LLog = _G.LivePage.LLog

-- Lädt gmaDummy, falls nicht in grandMA2 Umgebung
if not gma then require("gmaDummy") end  -- Remove in Prod

-------------------------------------------
--               Functions               --
-------------------------------------------

-- Dimmer Executor Functions --
function ApplyValueChange(T_Exec, T_Dimmer)
    local execData = EGroup[T_Exec]
    if not execData then return end
    _G.LivePage.Settings.CurrentInterval = _G.LivePage.Settings.ActiveInterval --Mode = Speeed

    execData.Dimmer = T_Dimmer
    EvalDimmer()

    local fTime = GetFadeTime()

    ExecCmd(string.format("Executor %s At %s Fade %s", execData.Exec, execData.Dimmer, fTime))
    ExecCmd(string.format("Appearance Macro %s /color='%s'", execData.Macro, Color.red))

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
        ExecCmd(string.format("Appearance Macro %s /color='%s'", execData.Macro, Color.grey))
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

    ExecCmd(string.format("Executor %s At 100 Fade 0", execData.Exec))
    ExecCmd(string.format("Appearance Macro %s /color='%s'", execData.Macro, Color.MAgold))

    gma.timer(function()    
        ExecCmd(string.format("Executor %s At %s Fade 0.2", execData.Exec, originalValue))

        local endColor = Color.grey
        if DM.IsTrackingFade[T_Exec] then endColor = Color.red end
        ExecCmd(string.format("Appearance Macro %s /color='%s'", execData.Macro, endColor))

        LLog("Flash beendet für: " .. execData.Name, 1)
    end, duration, 1)
end --idk

-- Macro Functions --

function LabelMacro(T_Exec)
    Macro = EGroup[T_Exec].Macro
    Dimmer = EGroup[T_Exec].Dimmer
    Label = EGroup[T_Exec].Name .. "-" .. Dimmer
    ExecCmd("Label Macro " .. Macro .. " " .. Label)
end

function SetPopUp(T_Exec)
    UserInput = gma.textinput("Dimmer Wert für " .. EGroup[T_Exec].Name .. " eingeben", EGroup[T_Exec].Dimmer)
    ApplyValueChange(T_Exec, UserInput)
end

-- Funktionen Test --
if debug and not _G.LivePage.Debug.Prod and not true then -- Remove in Prod -- Vorerst Deaktiviert
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