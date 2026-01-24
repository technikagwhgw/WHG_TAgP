----- LivePageMain.lua

--#region LivePage Setup

local LivePage = {
    Version = "0.9.1",
    Name = "LivePageMain",
    IsRunning = false,
    Registry = {},
    Config = {
        FadeTimeFader = "100.106", -- Executor
        DefaultFade = 3,
        UpdateRate = 0.2, -- Delay between Loop Cycles
        StandByRate = 1,
        MaxRegistryEntrys = 100,
    },
    Settings = {
        LogDisplayLevel = 2, -- 0=All Logs, 1=Debug, 2=Info, 3=Warn, 4=Error, 5=None
        ForceLog = false,    -- Druck alle Logs unabhängig vom Level in Echo (Vollständig Logs in Echo)
        AutoStart = false,    -- Starte Plugin automatisch beim Laden
        GhostMode = false,   -- Simuliere gma.cmd Aufrufe (Keine Ausführung)
        SuppressMSGBox = false, -- Kein Msg PopUp Boxen mehr
        Debug = {
            Enabled = true,
            Help = true,
            Padentic = false, -- Future Feature
            Prod = false,
        },
    },
    ColorPresets = {
        Active = "Green",
        Idle = "Grey",
        Warning = "Red"
    }
}

-- Synonyme --
local lp = LivePage
local lpS = LivePage.Settings
local Color = LivePage.ColorPresets
local Conf = LivePage.Config
--#endregion

--#region WrapperFunctions

-- gma.feedback()/gma.echo()
function LLog(msg, level) -- Lazy Log = LLog
    if lpS.LogDisplayLevel == 0 then return end -- Logging disabled
    local finalMsg = "Error Logging Message"
    local prefix = { "[DEBUG]", "[INFO]", "[WARN]", "[ERROR]" }

    -- Format String
    if type(level) == "string" then
        local specialPrefixes = {
            M = "[MAIN]",
            G = "[GHOST]",
            W = "[WARN]"
        }
        finalMsg = string.format("%s %s", specialPrefixes[level] or "[LOG]", msg)
        level = 3 -- Default Level for string prefixes

    else finalMsg = string.format("%s %s", prefix[level] or "[LOG]", msg) end

    -- Return based on level
    if level >= lpS.LogDisplayLevel then gma.feedback(finalMsg)
    elseif not lpS.ForceLog then gma.echo(finalMsg) end -- Es muss ein Bessern Weg geben

    if lpS.ForceLog then gma.echo(finalMsg) end
end

-- gma.cmd()
function ExecCmd(cmd) --TODO: add fadeArg
    if lp.Settings.GhostMode then
        LLog("Ghosted Cmd: " .. tostring(cmd), "G")
    else
        gma.cmd(cmd)
    end
end

function SetAppearance(macroID, appearanceName)
    lp.Registry[macroID] = lp.Registry[macroID] or {}
    if lp.Registry[macroID].currentAppearance ~= appearanceName then
        local mH = lp.Registry[macroID].macroHandle or GetHandle("Macro 1." .. macroID)
        if mH then SetHandleProperty(mH,"Appearance",appearanceName)
        else
            local cmd = string.format("Assign Appearance '%s' At Macro 1.%s", appearanceName, macroID)
            ExecCmd(cmd)
            LLog(string.format("UI Update: Used Fallback to Update Macro %s -> %s", macroID, appearanceName), 1) -- Debug
        end
        lp.Registry[macroID].currentAppearance = appearanceName
    end
end

-- gma.gui.msgbox()
function MSGBox(Title, Text)
    if not lp.Settings.SuppressMSGBox then gma.gui.msgbox(Title, Text)
    else LLog("(".. Title .. ") " .. Text,2) end
end

-- gma.textinput()
function TextInput(Title, Default)
    gma.textinput(Title, Default) -- falls in Zukunft was Anders Gemacht werden soll
end

-- Handle/Property
function GetHandle(Object) return gma.show.getobj.handle(Object) end
function GetHandleProperty(Handle,Property) return gma.show.property.get(Handle,Property) end
function GetProperty(Object,Property) return GetHandleProperty(GetHandle(Object),Property) end
function GetNumProperty(handle, property) return tonumber(GetHandleProperty(handle, property)) or 0 end

function SetHandleProperty(Handle,Property,Value) gma.show.property.set(Handle,Property,Value) end

-- Simple
GetVar = gma.show.getvar
GetTime = gma.gettime
Sleep = gma.sleep


--#endregion

--#region EngineCore

local function EngineCore()
    LLog("Entering Main Loop ...","M")
    local activeRate = Conf.UpdateRate
    local standByRate = Conf.StandByRate

    while lp.IsRunning do
        local hasWork = next(lp.Registry) ~= nil
        if hasWork then
            CheckExecutorFading()
            Sleep(activeRate)
        else
            Sleep(standByRate)
        end
    end
end

-- EngineCoreLoopFunctions
function CheckExecutorFading()
    for macroID, data in pairs(lp.Registry) do
        if GetHandleProperty(data.handle, "isFading") == "No" then
            SetAppearance(macroID, Color.Idle)
            lp.Registry[macroID] = nil
        end
    end
end


--#endregion

--#region SystemCheck

function SystemCheck()
    LLog("System Integrity Check Initiated...", "M")
    local errors = 0
    local warnings = 0

    if not lp or not lp.Registry then
        MSGBox("CRITICAL ERROR", "Plugin memory structure corrupted!")
        return false
    end

    if lp.IsRunning and GetTime() > 0 then
        LLog("Duplicate engine detected. Restarting heartbeat...", "E")
        lp.IsRunning = false -- Force stop previous loop
        Sleep(0.2)
    end

    local faderHandle = GetHandle("Executor " .. (Conf.FadeTimeFader or ""))
    if not faderHandle then
        LLog("UX Warning: FadeTime Fader (" .. tostring(Conf.FadeTimeFader) .. ") missing. Using Default.", 3)
        warnings = warnings + 1
    end

    local isBlind = GetVar("BLIND")
    if isBlind == "On" then
        LLog("Console is in BLIND mode. Visual feedback may not reflect live output.", "W")
        warnings = warnings + 1
    end

    local registryCount = 0
    for _ in pairs(lp.Registry) do registryCount = registryCount + 1 end
    if registryCount > 100 then
        LLog("THREAT: Registry overflow (" .. registryCount .. " items). Purging stale data.", 3)
        lp.Registry = {}
        warnings = warnings + 1
    end

    -- Auswertung --
    if errors > 0 then
        MSGBox("Stopped Plugin", "Plugin stopped due to " .. errors .. " critical system errors.")
        return false
    end

    LLog("Safety Check Complete: " .. warnings .. " non-critical issues flagged.", "M")
    return true
end

--#endregion

--#region UserPluginInterface

local function StrSplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    -- Pattern: Suche alles außer dem Trennzeichen
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t -- Returned Tabell mit split _,str (ipairs)
end

function UserCommandInterface(input)
    if not input or input == "" then return end
    local args = StrSplit(input, " ")
    local action = args[1]:upper()

    local function GetValidNum(val, min, max, default)
        local n = tonumber(val)
        if not n then return default end
        return math.max(min, math.min(max, n))
    end

    local ActionFunctions = {
        ["START"]    = Main,
        ["STOP"]     = Cleanup,
        ["GHOST"]    = function() lpS.GhostMode = not lpS.GhostMode; LLog("GhostMode: "..tostring(lpS.GhostMode), "M") end,
        ["AUTO"]     = function() lpS.AutoStart = not lpS.AutoStart; LLog("AutoStart: "..tostring(lpS.AutoStart), "M") end,
        ["CLEAR"]    = function() lp.Registry = {}; LLog("Registry Purged", "M") end,
        ["LOG"]      = function()
            lpS.LogDisplayLevel = GetValidNum(args[2], 0, 5, 2)
            LLog("Log Level set to: "..lpS.LogDisplayLevel, "M")
        end,
        ["FADE"]     = function()
            Conf.DefaultFade = GetValidNum(args[2], 0, 60, Conf.DefaultFade)
            LLog("Default Fade set to: "..Conf.DefaultFade.."s", "M")
        end,
        ["RATE"]     = function()
            Conf.UpdateRate = GetValidNum(args[2], 0.05, 2, Conf.UpdateRate)
            LLog("Update Rate set to: "..Conf.UpdateRate.."s", "M")
        end,
        ["SRATE"] = function()
            Conf.StandByRate = not Conf.StandByRate
            LLog("StandBy Mode set to: " .. tostring(Conf.StandByRate), "M")
        end,
        ["PROVISION"] = function()
            local start = tonumber(args[2]) or 1
            local amount = tonumber(args[3]) or 10
            ProvisionMacros(start, amount)
        end
    }
    if ActionFunctions[action] then
        local status, err = pcall(ActionFunctions[action])
        if not status then LLog("Interface Error: " .. tostring(err), 4) end
    else
        MSGBox("LivePage", "Unknown Command: " .. action .. "\nTry: Start, Stop, Ghost, Auto, Clear, Log [val], Fade [val]")
    end
end

function OpenInterface()
    local userRequest = TextInput("LivePage Command Interface", "Start")
    if userRequest then
        UserCommandInterface(userRequest)
    end
end

--#endregion

--#region Subscribtion

function Subscribe(macroID, execID, actionType)
    local h = GetHandle("Executor " .. execID)
    local mH = GetHandle("Macro 1." .. macroID)
    if not h then
        LLog("Subscription Failed: Executor " .. execID .. " not found.", 4)
        return nil
    end
    SetAppearance(macroID,Color.Active)
    lp.Registry[macroID] = {
        handle = h,         --Cached Executor Handle
        macroHandle = mH,   --Cached Macro Handle
        exec = execID,
        type = actionType,
        startTime = GetTime(),
        isFading = true,
        currentAppearance = Color.Active,
    }
    return h
end

function UniversalAction(macroID, execID, attribute, value)
    local handle = Subscribe(macroID, execID, attribute)
    if not handle then return end

    local fTime = GetFadeTime()
    ExecCmd(string.format("Executor %s At %s Fade %s", execID, value, fTime)) --Handles Absolute and Relative Changes

    local name = GetHandleProperty(handle, "name") or "Exec"
    ExecCmd(string.format("Label Macro 1.%s '%s:%s'", macroID, name, value))
end
--#endregion

function GetFadeTime()
    local handle = GetHandle("Executor " .. Conf.FadeTimeFader)
    if not handle then return Conf.DefaultFade end

    local faderValue = GetHandleProperty(handle, "fader") or "0"
    local parsedValue = tonumber(faderValue:match("%d+"))

    if not parsedValue then return Conf.DefaultFade end

    local result = parsedValue / 10
    return math.max(0.1, result)
end

--#endregion

--#region Utility

function EnsurePoolObject(type, id, label)
    local path = type .. " " .. id
    local h = GetHandle(path)

    if not h then
        LLog("Auto-Generating " .. path, "M")
        ExecCmd("Store " .. path)
        if label then
            ExecCmd("Label " .. path .. " '" .. label .. "'")
        end
        h = GetHandle(path)
    end
    return h
end

function ProvisionMacros(startID, count)
    LLog("Provisioning " .. count .. " Macros starting at " .. startID, "M")

    for i = 0, count - 1 do
        local currentID = startID + i
        local label = "LP_Action_" .. currentID
        local mH = EnsurePoolObject("Macro 1.", currentID, label)
        local cmd = string.format("LUA \"UniversalAction(%d, %d, 'Dimmer', 100)\"", currentID, 100 + currentID)
        SetHandleProperty(mH, 1, cmd)
    end

    MSGBox("Provisioning Complete", count .. " Macros prepared for LivePage.")
end

--#endregion

--#region Entry Points

function Main()
    if lp.IsRunning then
        lp.IsRunning = false
        Sleep(0.3)
    end
    if not SystemCheck() then return end
    lp.IsRunning = true
    LLog("LivePage " .. lp.Version .. ": Coroutine Engine Started.", "M")
    EngineCore()
end

function Cleanup()
    lp.IsRunning = false
    -- Reset all tracked buttons to Idle before closing
    for mID, _ in pairs(lp.Registry) do
        SetAppearance(mID,Color.Idle)
    end
    lp.Registry = {}
    LLog("LivePage Engine safely terminated.", "M")
end

return Main, Cleanup
--#endregion