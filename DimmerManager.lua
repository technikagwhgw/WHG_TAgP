-- DimmerManager --
-- Manages LivePage Dimmer

-- Global Variables --
FadeTimeFaderName = "fader_1.106"   -- Fade Time Fader
FadeTimeDefault = 3     -- Standard Fade Zeit
UpdateRate = 0.1        -- Update in Sekunden

-- Executor Table --
EGroup = {
    Exec1 = {
        Name = "LEDUV",
        Exec = "100.101",
        Macro = "20",
        Dimmer = "0",
    },
    Exec2 = {
        Name = "LEDUV",
        Exec = "100.102",
        Macro = "21",
        Dimmer = "0",
    },
    Exec3 = {
        Name = "LEDUV",
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
if not gma then require("gmaDummy") end

-- Functions --

function ApplyValueChange(T_Exec, T_Dimmer)
    EGroup[T_Exec].Dimmer = T_Dimmer
    EvalDimmer()
    
    gma.cmd("Executor " .. EGroup[T_Exec].Exec .. " At " .. EGroup[T_Exec].Dimmer .. " Fade " .. FadeTime())
    gma.cmd("Appearance Macro " .. EGroup[T_Exec].Macro .. " Color " .. Color.red)
    gma.timer(CheckFading(T_Exec), FadeTime(), 1)
    
    LabelMacro(T_Exec)
end

function ChangeExecDimmer(T_Exec, C_Dimmer)
    T_Dimmer = EGroup[T_Exec].Dimmer + C_Dimmer
    ApplyValueChange(T_Exec, T_Dimmer)
end

function FadeTime()
    return tonumber(gma.show.getvar(FadeTimeFaderName)) or FadeTimeDefault
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

function CheckFading(T_Exec)
    local handle = gma.show.getobj.handle(EGroup[T_Exec].Exec)
    local isFading = gma.show.property.get(handle, 'isFading')

    if isFading == "No" or isFading == nil then
        gma.cmd("Appearance Macro " .. EGroup[T_Exec].Macro .. " Color " .. Color.green)
    else
        -- Prüfen in UpdateRate Sekunden erneut
        gma.timer(CheckFading(T_Exec), UpdateRate, 1)
    end
end