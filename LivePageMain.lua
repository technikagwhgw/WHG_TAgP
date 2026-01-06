-- LivePageMain.lua

-- 1. GLOBALE REGISTRIERUNG
_G.LivePage = { --TODO: Namespace für WatchDog und andere Module -- TODO: Debug Global local entfernen und immer mit _G umsetzen. 
    Version = "0.6.4",
    IsRunning = false, -- Global Running Flag
    CurrentActiveConfig = nil,
    DimmerManager = {
        fadeTimeFaderName = "100.106",  -- Fade Time Executor
        fadeTimeDefault = 3,     -- Standard Fade Zeit
        IsTrackingFade = {},     -- Info Variable um Fading zu tracken
        ExecutorGroup = {
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
        },
    },
    WatchDog = {
        Enabled = true,
        Padentic = true,
        ForceCleanUpOnRestart = false,
        Interval = 2, -- Sekunden
        LastResponse = 0,
        MaxResponseTime = 14, -- Sekunden
        RestartCount = 0,
        RestartCountLimit = true,
        OverrideForceStop = false,
    },
    Settings = {
        UpdateRate = 0.1,    -- Sekunden
        SuperUser = false,   -- Niemals anschalten ohen zuwissen was es macht !
        LogDisplayLevel = 2, -- 0=All Logs, 1=Debug, 2=Info, 3=Warn, 4=Error, 5=None
        ForceLog = false,    -- Druck alle Logs unabhängig vom Level in Echo (Vollständig Logs in Echo)
        EcoInterval = 1.5,   -- Intevale für MainLoop
        ActiveInterval = 0.5,-- 
        LoopInterval = 0.5,  -- 
        AutoStart = true,    -- Starte Plugin automatisch beim Laden
        GhostMode = false,   -- Simuliere gma.cmd Aufrufe (Keine Ausführung)
    },
    Debug = {
        Enabled = true,
        Help = true,
        Padentic = false, -- Future Feature
        Prod = false,
    },
    MacroSettings = {
        macroRoot = 106, -- 1:0
        macroMax = 164,  -- 3:14
        macroPageSize = 15,
        DisplayMacroID = 420, -- Status Anzeige Macro ID (placeholder)
    },
    Color = {
        red    = "#FF0000",
        green  = "#00FF00",
        blue   = "#0000FF",
        MAgold = "#FFCC00",
        grey   = "#222222",
        cyan   = "#00FFFF",
        orange = "#FFA500",
        yellow = "#FFFF00",
    }
}

-- Globals --
local lp = _G.LivePage
local DM = _G.LivePage.DimmerManager
local Color = _G.LivePage.Color


-- Lädt Files, falls nicht in grandMA2 Umgebung
if not gma then require("gmaDummy") end  -- Remove in Prod
require("DimmerManager")  -- Provisorisch bitte Richtig machen
require("MacroInterface")

-----------------------------------------------------------
-- 2. INIT
-----------------------------------------------------------
function InitPlugin()
    LLog("Start LivePage Setup", "M")
    LLog("Plugin Version: " .. _G.LivePage.Version, 2)
    -- Future Feature
    -- Datein laden (Hierarchisch wichtig!)
    -- dofile(gma.show.getvar('PATH') .. "/DimmerManager.lua")
    -- dofile(gma.show.getvar('PATH') .. "/MacroInterface.lua")

    -- Validierung
    if not SystemCheck() then
        return
    end

    -- Set Running Flag
    _G.LivePage.IsRunning = true
    gma.timer(WatchDog, 3, 1)
    gma.timer(MainLoop, 1, 1)
end

-----------------------------------------------------------
-- 3. SCHEDULER LOOP + WATCHDOG
-----------------------------------------------------------
-- Main --
function MainLoop()
    if not _G.LivePage.IsRunning then 
        ExecCmd("Off Plugin Thru") 
        LLog("PLUGIN STOPPED", "M")
        return
    end
    --WatchDog Ping
    _G.LivePage.WatchDog.LastResponse = gma.gettime()

    local isSystemActive = false
    for _, active in pairs(DM.IsTrackingFade) do
        if active then isSystemActive = true; break end
    end
    -- Hier kommen alle Funktionen rein, die regelmäßig ausgeführt im Hintergrund laufen sollen
    UpdateStatusDisplay()
    CheckProgrammerState() -- Future Feature

    if isSystemActive then _G.LivePage.Settings.CurrentInterval = _G.LivePage.Settings.ActiveInterval
    else _G.LivePage.Settings.CurrentInterval = _G.LivePage.Settings.EcoInterval end

    -- Reschedule
    gma.timer(MainLoop, _G.LivePage.Settings.LoopInterval, 1)
end

-- WATCHDOG --
local currentWatchDogRestartCap = 3
function WatchDog() -- ToDo: Namespace für WatchDog
    if not _G.LivePage.WatchDog.Enabled then return end
    local currentTime = gma.gettime()
    local timeSinceLastResponse = currentTime - _G.LivePage.WatchDog.LastResponse

    if _G.LivePage.WatchDog.Enabled and timeSinceLastResponse > _G.LivePage.WatchDog.MaxResponseTime then
        _G.LivePage.WatchDog.RestartCount = _G.LivePage.WatchDog.RestartCount + 1
        LLog("MainLoop antwortet seit " .. timeSinceLastResponse .. " Sekunden nicht. Force Plugin Restart !!! (Restart Count: " ..
        _G.LivePage.WatchDog.RestartCount .. ")", "W")

        if not _G.LivePage.WatchDog.OverrideForceStop and _G.LivePage.WatchDog.RestartCount > 3 then
            LLog("Override Force Stop aktiviert. Plugin wird nicht neu gestartet. !!!", "W")
            _G.LivePage.IsRunning = false
            return
        else
            -- Restart Plugin
            LLog("Stop Plugin ...", "W")
            _G.LivePage.IsRunning = false
            ForceCleanUp()
            for i = 1, 3 do gma.sleep(1) LLog("...", "M") end
            LLog("Initialisiere Plugin !!!", "W")
            InitPlugin()
        end
    elseif _G.LivePage.WatchDog.Enabled and _G.LivePage.WatchDog.Padentic and
    timeSinceLastResponse > (_G.LivePage.WatchDog.MaxResponseTime - (_G.LivePage.WatchDog.Interval * 3)) then

        LLog("MainLoop antwortet seit " .. timeSinceLastResponse .. " Sekunden nicht. Überwache Situation !!!", "W")
    else
        if _G.LivePage.IsRunning and _G.LivePage.WatchDog.RestartCountLimit and _G.LivePage.WatchDog.RestartCount > currentWatchDogRestartCap then
            gma.gui.msgbox("WATCHDOG WARNUNG", 
            "Der LivePage Plugin Watchdog hat mehr als " .. currentWatchDogRestartCap ..
            " Neustarts durchgeführt. \nBitte überprüfe das System auf mögliche Probleme. \n(Um diese Meldung zu deaktivieren, setze 'RestartCountLimit' in den Plugin Settings auf false.)")
            currentWatchDogRestartCap = currentWatchDogRestartCap + 5
        end
        -- Reschedule Watchdog
        gma.timer(WatchDog, _G.LivePage.WatchDog.Interval, 1)
    end
end -- Sorry -Aeneas

function ForceCleanUp()
    if _G.LivePage.Settings.ForceCleanUpOnRestart then
        ExecCmd("ClearAll") 
        ExecCmd("Blind Off")
        ExecCmd("Freeze Off")
        ExecCmd("Go Off")
        ExecCmd("Off Page Thru")
        LLog("Force CleanUp durchgeführt !","W")
        gma.sleep(1)
    end
end

function KillLivePage()
    if not _G.LivePage.Settings.SuperUser then LLog("Unable to kill LivePage. Permission denied.", "W") return end
    _G.LivePage.IsRunning = false
    -- Alle Timer stoppen (indem wir sie nicht neu aufrufen)
    LLog("PLUGIN TERMINATED BY USER", "M")

    -- Optisches Feedback im Display
    if _G.LivePage.MacroSettings.DisplayMacroID then
        ExecCmd('Label Macro ' .. _G.LivePage.MacroSettings.DisplayMacroID .. ' "LIVEPAGE OFF"')
        ExecCmd('Appearance Macro ' .. _G.LivePage.MacroSettings.DisplayMacroID .. ' /color="black"')
    end
end
-----------------------------------------------------------
-- 4. HILFSFUNKTIONEN
-----------------------------------------------------------
-- Wrapper für gma.cmd um GhostMode zu unterstützen --
-- ggf. Queue System hinzufügen in Zukunft
function ExecCmd(cmd)
    if lp.Settings.GhostMode then
        LLog("Skip Cmd: " .. tostring(cmd), "G")
    else
        gma.cmd(cmd)
    end
end

-- Programmer State Check (Future Feature) --
function CheckProgrammerState()
    -- Beispiel: Prüfen ob Werte im Programmer hängen
    -- (Dummy Logik für QoL)
end

-- Status Display --
function UpdateStatusDisplay()
    local lp = _G.LivePage
    local displayMacroID = lp.MacroSettings.DisplayMacroID
    if not displayMacroID then return end

    -- Heartbeat Indicator
    local blinker = (math.floor(gma.gettime()) % 2 == 0) and "*" or " "

    -- Data Get
    local modeText = lp.IsRunning and "RUN" or "STOP"
    local helpText = lp.Debug.Help and "HELP" or "LIVE"

    -- Fader Count
    local fadeCount = 0
    for _ in pairs(DM.IsTrackingFade or {}) do fadeCount = fadeCount + 1 end

    -- WatchDog
    local restartText = ""
    if lp.WatchDog.RestartCount > 0 then
        restartText = string.format(" RST:%d", lp.WatchDog.RestartCount)
    end

    -- Data String
    -- Format: (*) RUN HELP FADES:2 RST:0 -- Beispiel
    local statusString = string.format("(%s) %s %s F: %d%s", 
        blinker, modeText, helpText, fadeCount, restartText)

    ExecCmd('Label Macro ' .. displayMacroID .. ' "' .. statusString .. '"')

    local color = Color.grey -- TODO: Color + Bedeutung Muss Überarbeitet werden
    if not lp.IsRunning then color = Color.red
    elseif lp.WatchDog.RestartCount > 0 then color = Color.orange
    elseif lp.Debug.Help then color = Color.yellow end

    ExecCmd('Appearance Macro ' .. displayMacroID .. ' /color="' .. color .. '"')
end

-- Global Log Function --
-- ggf. Log in andere Datei verschieben wegen Funktion Override 
function LLog(msg, level) -- Lazy Log = LLog
    if _G.LivePage.Settings.LogDisplayLevel == 0 then return end -- Logging disabled
    local finalMsg = "Error Logging Message"
    local prefix = { "[DEBUG]", "[INFO]", "[WARN]", "[ERROR]" }

    -- Format String
    if type(level) == "string" then
        local specialPrefixes = {
            W = "[WATCHDOG]",
            M = "[MAIN]",
            G = "[GHOST]",
        }
        finalMsg = string.format("%s %s", specialPrefixes[level] or "[LOG]", msg)
        level = 3 -- Default Level for string prefixes

    else finalMsg = string.format("%s %s", prefix[level] or "[LOG]", msg) end

    -- Return based on level
    if level >= _G.LivePage.Settings.LogDisplayLevel then gma.feedback(finalMsg)
    elseif not _G.LivePage.Settings.ForceLog then gma.echo(finalMsg) end -- Es muss ein Bessern Weg geben

    if _G.LivePage.Settings.ForceLog then gma.echo(finalMsg) end
end

-- Main System Integrity Check -- 
function SystemCheck()
    LLog("Initialisiere Startup-Sequence...", "M")
    local errors = 0
    local warnings = 0

    -- CHECK 1: Struktur-Validierung
    if not lp or not lp.DimmerManager or not lp.DimmerManager.ExecutorGroup then
        LLog("CRITICAL: Namespace Struktur unvollständig!", 4)
        return false
    end

    -- CHECK 2: Hardware-Validierung (Executoren)
    for id, data in pairs(lp.DimmerManager.ExecutorGroup) do
        local handle = gma.show.getobj.handle("Executor " .. data.Exec)
        if not handle then
            LLog("Hardware Error: Executor " .. data.Exec .. " (" .. data.Name .. ") fehlt!", 4)
            errors = errors + 1
        end

        -- Check ob zugehöriges Macro existiert
        local mHandle = gma.show.getobj.handle("Macro " .. data.Macro)
        if not mHandle then
            LLog("Config Warning: Macro " .. data.Macro .. " für " .. data.Name .. " nicht vorhanden.", 3)
            warnings = warnings + 1
        end
    end

    -- CHECK 3.1: FadeTime Fader
    if not gma.show.getobj.handle("Executor " .. lp.DimmerManager.fadeTimeFaderName) then
        LLog("Warning: FadeTime Fader nicht gefunden. Nutze Default: " .. lp.DimmerManager.fadeTimeDefault .. "s", 3)
        warnings = warnings + 1
    end

    -- CHECK 3.2: Status Display Macro
    if not gma.show.getobj.handle("Macro " .. lp.MacroSettings.DisplayMacroID) then
        LLog("Warning: Status-Display Macro " .. lp.MacroSettings.DisplayMacroID .. " fehlt!", 3)
        warnings = warnings + 1
    end

    -- CHECK 4: MacroConfig Validierung
    if _G.MacroConfig then
        for pageName, pageData in pairs(_G.MacroConfig) do
            if not pageData.actions or #pageData.actions == 0 then
                LLog("Config: Seite '" .. pageName .. "' ist leer.", 3)
                warnings = warnings + 1
            end
        end
    else
        LLog("Error: MacroConfig.lua wurde nicht geladen!", 4)
        errors = errors + 1
    end

    -- AUSWERTUNG --
    if errors > 0 then
        gma.gui.msgbox("Startup Failed", errors .. " kritische Fehler gefunden! Siehe Log.")
        return false
    end

    LLog("Startup-Check erfolgreich: " .. warnings .. " Warnungen ignoriert.", "M")
    return true
end

-- Exporte --
_G.LivePage.ExecCmd = ExecCmd
_G.LivePage.LLog = LLog
_G.LivePage.InitPlugin = InitPlugin
--_G.LivePage.ForceCleanUp = ForceCleanUp -- NICHT JETZT DU NICHT BRAUCHST

--------------------------------------------------------------
-- Plugin-Start beim Laden
if _G.LivePage.Settings.AutoStart then InitPlugin()
else LLog("LivePage AutoStart deaktiviert. MainPlugin -> InitPlugin", "M") end