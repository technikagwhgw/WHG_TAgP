----- LivePageMain.lua

--#region LivePage Setup

local LivePage = {
    Version = "0.9.0",
    IsRunning = false,
    Registry = {},
    Config = {
        FadeTimeFader = "100.106",
        DefaultFade = 3,
        UpdateRate = 0.2, -- Delay between Loop Cycles
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

--#endregion

--#region EngineCore

local function EngineCore()
    while lp.IsRunning do
        CheckExecutorFading()
        CheckCmdEvent()
        -- Delay
        gma.sleep(lp.Config.UpdateRate)
    end
end

-- EngineCoreLoopFunctions
function CheckExecutorFading()
    for macroID, data in pairs(lp.Registry) do
        if GetHandleProperty(data.handle, "isFading") == "No" then
            ExecCmd(string.format("Assign Appearance '%s' At Macro 1.%s", Color.Idle, macroID))
            lp.Registry[macroID] = nil
        end
    end
end

function CheckCmdEvent()
    local last_cmd_index = 0
    local events = gma.user.getcmdevents(last_cmd_index)
    if events then
        for i, event in ipairs(events) do
            last_cmd_index = event.index
            if event.name:upper():find("^LP") then
                local cleanCmd = event.name:upper():gsub("LP%s*", "")
                HandleCommandLine(cleanCmd)
            end
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

    if lp.IsRunning and gma.gettime() > 0 then
        LLog("Duplicate engine detected. Restarting heartbeat...", "E")
        lp.IsRunning = false -- Force stop previous loop
        gma.sleep(0.2)
    end

    local faderHandle = GetHandle("Executor " .. (Conf.FadeTimeFader or ""))
    if not faderHandle then
        LLog("UX Warning: FadeTime Fader (" .. tostring(Conf.FadeTimeFader) .. ") missing. Using Default.", 3)
        warnings = warnings + 1
    end

    local isBlind = gma.show.getvar("BLIND")
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

--#region CommandLine

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

function HandleCommandLine(input)
    local args = StrSplit(input, " ")
    local action = args[1]

    local ActionFunctions = {
        ["START"] = Main,
        ["GHOST"] = function() lpS.GhostMode = not lpS.GhostMode end,
        ["SETFADE"] = function() 
            lp.Config.DefaultFade = tonumber(args[2]) or lp.Config.DefaultFade 
        end,
        -- etc.
    }
    if ActionFunctions[action] then
        ActionFunctions[action]()
        LLog("Executed CLI Action: " .. action, "M")
    end
end

--#endregion

--#region Subscribtion

function Subscribe(macroID, execID, actionType)
    local h = GetHandle("Executor " .. execID)
    if not h then 
        LLog("Subscription Failed: Executor " .. execID .. " not found.", 4)
        return nil 
    end
    ExecCmd(string.format("Assign Appearance '%s' At Macro 1.%s", Color.Active, macroID))
    lp.Registry[macroID] = {
        handle = h,
        exec = execID,
        type = actionType,
        startTime = gma.gettime(),
        isFading = true
    }
    return h
end

function UniversalAction(macroID, execID, attribute, value)
    local handle = Subscribe(macroID, execID, attribute)
    if not handle then return end

    local fTime = GetFadeTime()
    ExecCmd(string.format("Executor %s At %s Fade %s", execID, value, fTime))

    local name = GetHandleProperty(handle, "name") or "Exec"
    ExecCmd(string.format("Label Macro 1.%s '%s:%s'", macroID, name, value))
end
--#endregion

function GetFadeTime()
    local handle = GetHandle("Executor " .. Conf.FadeTimeFader)
    if not handle then return Conf.DefaultFade end
    -- Wandelt 0-100% des Faders in Sekunden um
    local faderValue = GetHandleProperty(handle, "fader") or "0"
    return tonumber(faderValue:match("%d+")) / 10 or Conf.FadeTimeDefault
end

--#endregion

--#region Entry Points

function Main()
    lp.IsRunning = true
    if not SystemCheck() then return end
    LLog("LivePage " .. lp.Version .. ": Coroutine Engine Started.", "M")
    EngineCore()
end

function Cleanup()
    lp.IsRunning = false
    -- Reset all tracked buttons to Idle before closing
    for mID, _ in pairs(lp.Registry) do
        gma.cmd(string.format("Assign Appearance '%s' At Macro 1.%s", Color.Idle, mID))
    end
    LLog("LivePage Engine safely terminated.", "M")
end

return Main, Cleanup
--#endregion
