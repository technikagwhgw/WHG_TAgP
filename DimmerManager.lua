-- DimmerManager
-- Manages LivePage Dimmer

-- Global Variables --
FadeTime = 3 -- ToDo: Map to SpecialMaster

-- Executor Table --
EGroup = {
    Exec1 = {
        Exec = "100.101",
        Dimmer = "0",
    },
    Exec2 = {
        Exec = "100.102",
        Dimmer = "0",
    },
    Exec3 = {
        Exec = "100.103",
        Dimmer = "0",
    }
}

-- Lädt gma Dummy, falls nicht in grandMA2 Umgebung
if not gma then
    require("gma_dummy")
end

-- Functions --
function ApplyValueChange(T_Exec, T_Dimmer)
    EGroup[T_Exec].Dimmer = T_Dimmer
    EvalDimmer()
    gma.cmd("Executor " .. EGroup[T_Exec].Exec .. " At Fade " .. EGroup[T_Exec].Dimmer .. "")
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