-- LivePageMain.lua

-- 1. GLOBALE REGISTRIERUNG
_G.LivePage = {
    Version = "0.5.2",
    IsRunning = false, -- Global Running Flag
    Settings = {
        LoopInterval = 0.5,
    },
    Debug = {
        Enabled = true,
        Help = true,
        Padentic = false, -- Future Feature
    }
}

-----------------------------------------------------------
-- 2. INIT
-----------------------------------------------------------
function InitPlugin()
    gma.echo("--- Start LivePage Setup ---")

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
-- 3. SCHEDULED LOOP
-----------------------------------------------------------
function MainLoop()
    if not _G.LivePage.IsRunning then return end
    -- Hier kommen alle Funktionen rein, die regelmäßig ausgeführt im Hintergrund laufen sollen

    if UpdateStatusDisplay then UpdateStatusDisplay() end
    CheckProgrammerState() -- Future Feature

    -- Reschedule
    gma.timer(MainLoop, _G.LivePage.Settings.LoopInterval, 1)
end

-----------------------------------------------------------
-- 4. HILFSFUNKTIONEN
-----------------------------------------------------------
function CheckProgrammerState()
    -- Beispiel: Prüfen ob Werte im Programmer hängen
    -- (Dummy Logik für QoL)
end

-- Plugin-Start beim Laden
InitPlugin()