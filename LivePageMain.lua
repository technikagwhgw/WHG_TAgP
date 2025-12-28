-- LivePageMain.lua

-- 1. GLOBALE REGISTRIERUNG
_G.LivePage = {
    Version = "0.5.3",
    IsRunning = false, -- Global Running Flag
    SuperUser = false, -- Niemals anschalten ohen zuwissen was es macht !
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
        LoopInterval = 0.5,
    },
    Debug = {
        Enabled = true,
        Help = true,
        Padentic = false, -- Future Feature
    },
    MacroSettings = {
        DisplayMacroID = 420 -- Status Anzeige Macro ID (placeholder)
    }
}

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

-----------------------------------------------------------
-- 2. INIT
-----------------------------------------------------------
function InitPlugin()
    gma.feedback("--- Start LivePage Setup ---")
    gma.feedback("Plugin Version: " .. _G.LivePage.Version)
    -- Future Feature
    -- Datein laden (Hierarchisch wichtig!)
    -- dofile(gma.show.getvar('PATH') .. "/DimmerManager.lua")
    -- dofile(gma.show.getvar('PATH') .. "/MacroInterface.lua")

    -- Validierung
    local errorCollector = ValidateConfig()
    if not ExecTest then errorCollector = ExecTest() end -- DimmerManager Test

    if errorCollector == nil then
        _G.LivePage.IsRunning = true
        gma.echo("--- Setup erfolgreich beendet ---")

        -- Init Done
        MainLoop()
    else
        gma.gui.msgbox("SETUP FEHLER", "Plugin wurde aufgrund von Fehlern gestoppt.")
    end
end

-----------------------------------------------------------
-- 3. SCHEDULER LOOP + WATCHDOG
-----------------------------------------------------------
-- Main --
function MainLoop()
    if not _G.LivePage.IsRunning then 
        gma.cmd("Off Plugin Thru") 
        gma.echo("--- PLUGIN STOPPED ---")
        return
    end
    -- Hier kommen alle Funktionen rein, die regelmäßig ausgeführt im Hintergrund laufen sollen
    UpdateStatusDisplay()
    CheckProgrammerState() -- Future Feature

    _G.LivePage.WatchDog.LastResponse = gma.gettime() -- WatchDog Integration
    -- Reschedule
    gma.timer(MainLoop, _G.LivePage.Settings.LoopInterval, 1)
end

-- WATCHDOG --
local currentWatchDogRestartCap = 3
function WatchDog() -- ToDo: Namespace für WatchDog
    local currentTime = gma.gettime()
    local timeSinceLastResponse = currentTime - _G.LivePage.WatchDog.LastResponse

    if _G.LivePage.WatchDog.Enabled and timeSinceLastResponse > _G.LivePage.WatchDog.MaxResponseTime then
        _G.LivePage.WatchDog.RestartCount = _G.LivePage.WatchDog.RestartCount + 1
        gma.feedback("!!! WATCHDOG: MainLoop antwortet seit " .. timeSinceLastResponse .. " Sekunden nicht. Force Plugin Restart !!! (Restart Count: " ..
        _G.LivePage.WatchDog.RestartCount .. ")")
        
        if not _G.LivePage.WatchDog.OverrideForceStop and _G.LivePage.WatchDog.RestartCount > 3 then
            gma.feedback("!!! WATCHDOG: Override Force Stop aktiviert. Plugin wird nicht neu gestartet. !!!")
            _G.LivePage.IsRunning = false
            return
        else
            -- Restart Plugin
            gma.echo("!!! WATCHDOG: Stop Plugin ... !!!")
            _G.LivePage.IsRunning = false
            ForceCleanUp()
            for i = 1, 3 do gma.sleep(1) gma.echo("...") end
            gma.echo("!!! WATCHDOG: Initialisiere Plugin !!!")
            InitPlugin()
        end
    elseif _G.LivePage.WatchDog.Enabled and _G.LivePage.WatchDog.Padentic and
    timeSinceLastResponse > (_G.LivePage.WatchDog.MaxResponseTime - (_G.LivePage.WatchDog.Interval * 3)) then

        gma.echo("!!! WATCHDOG WARNUNG: MainLoop antwortet seit " .. timeSinceLastResponse .. " Sekunden nicht. Überwache Situation !!!")
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
        gma.cmd("ClearAll") 
        gma.cmd("Blind Off")
        gma.cmd("Freeze Off")
        gma.cmd("Go Off")
        gma.cmd("Off Page Thru")
        gma.echo("!!! WATCHDOG: Force CleanUp durchgeführt !!!")
        gma.sleep(1)
    end
end

function KillLivePage()
    if not _G.LivePage.SuperUser then gma.feedback("Unable to kill LivePage. Permission denied.") return end
    _G.LivePage.IsRunning = false
    -- Alle Timer stoppen (indem wir sie nicht neu aufrufen)
    gma.echo("--- PLUGIN TERMINATED BY USER ---")

    -- Optisches Feedback im Display
    if _G.LivePage.MacroSettings.DisplayMacroID then
        gma.cmd('Label Macro ' .. _G.LivePage.MacroSettings.DisplayMacroID .. ' "LIVEPAGE OFF"')
        gma.cmd('Appearance Macro ' .. _G.LivePage.MacroSettings.DisplayMacroID .. ' /color="black"')
    end
end
-----------------------------------------------------------
-- 4. HILFSFUNKTIONEN
-----------------------------------------------------------
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
    for _ in pairs(IsTrackingFade or {}) do fadeCount = fadeCount + 1 end

    -- WatchDog
    local restartText = ""
    if lp.RestartCount and lp.RestartCount > 0 then
        restartText = string.format(" RST:%d", lp.RestartCount)
    end

    -- Data String
    -- Format: (*) RUN HELP FADES:2 RST:0 -- Beispiel
    local statusString = string.format("(%s) %s %s F: %d%s", 
        blinker, modeText, helpText, fadeCount, restartText)

    gma.cmd('Label Macro ' .. displayMacroID .. ' "' .. statusString .. '"')

    local color = Color.grey -- TODO: Color + Bedeutung Muss Überarbeitet werden
    if not lp.IsRunning then color = Color.red
    elseif lp.RestartCount > 0 then color = Color.orange
    elseif lp.Debug.Help then color = Color.yellow end

    gma.cmd('Appearance Macro ' .. displayMacroID .. ' /color="' .. color .. '"')
end


--------------------------------------------------------------
-- Plugin-Start beim Laden

InitPlugin()