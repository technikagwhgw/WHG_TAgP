----- LivePageMain.lua

--#region Globals

_G.LivePage = {
    Version = "0.8.1",
    IsRunning = false,
    DimmerManager = {
        fadeTimeFaderName = "100.106",
        fadeTimeDefault = 3,
        IsTrackingFade = {},
        ExecutorGroup = {
            Exec1 = { Name = "LEDUV", Exec = "100.101", Macro = "20", Dimmer = "0" },
            Exec2 = { Name = "PAR6", Exec = "100.102", Macro = "21", Dimmer = "0" },
            Exec3 = { Name = "MMH",   Exec = "100.103", Macro = "22", Dimmer = "0" }
        },
    },
    Settings = {
        --SuperUser = false,   -- Niemals anschalten ohen zuwissen was es macht !
        LogDisplayLevel = 2, -- 0=All Logs, 1=Debug, 2=Info, 3=Warn, 4=Error, 5=None
        ForceLog = false,    -- Druck alle Logs unabhängig vom Level in Echo (Vollständig Logs in Echo)
        AutoStart = false,    -- Starte Plugin automatisch beim Laden
        GhostMode = false,   -- Simuliere gma.cmd Aufrufe (Keine Ausführung)
        SuppressMSGBox = false, -- Kein Msg PopUp Boxen mehr
    },
    Debug = {
        Enabled = true,
        Help = true,
        Padentic = false, -- Future Feature
        Prod = false,
    },
    MacroConfig = nil,
    MacroSettings = {
        RequireMacroConfig = false,
        macroRoot = 106, -- 1:0
        macroMax = 164,  -- 3:14
        macroPageSize = 15,
        DisplayMacroID = 42, -- Status Anzeige Macro ID (placeholder)
    },
    AppearanceColor = {
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

-- Synonyme --
local lp = _G.LivePage
local DM = _G.LivePage.DimmerManager
local lpS = _G.LivePage.Settings
local EGroup = DM.ExecutorGroup
local Color = _G.LivePage.AppearanceColor

--#endregion

--#region WrapperFunctions

-- gma.feedback()/gma.echo()
function LLog(msg, level) -- Lazy Log = LLog
    if _G.LivePage.Settings.LogDisplayLevel == 0 then return end -- Logging disabled
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
    if level >= _G.LivePage.Settings.LogDisplayLevel then gma.feedback(finalMsg)
    elseif not _G.LivePage.Settings.ForceLog then gma.echo(finalMsg) end -- Es muss ein Bessern Weg geben

    if _G.LivePage.Settings.ForceLog then gma.echo(finalMsg) end
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

--#region Utility

function InitPlugin()
    if not SystemCheck() then return end
    lp.IsRunning = true -- Kann entfernt werden wenn alle depend. entfernt sind
    LLog("LivePage " .. lp.Version .. " gestartet.", "M")
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

    -- CHECK 2: ExecutorGroup-Validierung
    for id, data in pairs(lp.DimmerManager.ExecutorGroup) do
        local handle = GetHandle("Executor " .. data.Exec)
        if not handle then
            LLog("Hardware Error: Executor " .. data.Exec .. " (" .. data.Name .. ") fehlt!", 4)
            errors = errors + 1
        end

        -- Check ob zugehöriges Macro Lable existiert
        local mHandle = GetHandle("Macro " .. data.Macro)
        if not mHandle then
            LLog("Config Warning: Macro " .. data.Macro .. " für " .. data.Name .. " nicht vorhanden.", 3)
            warnings = warnings + 1
        end
    end

    -- CHECK 3.1: FadeTime Fader
    if not GetHandle("Executor " .. lp.DimmerManager.fadeTimeFaderName) then
        LLog("Warning: FadeTime Fader nicht gefunden. Nutze Default: " .. lp.DimmerManager.fadeTimeDefault .. "s", 3)
        warnings = warnings + 1
    end

    -- CHECK 3.2: Status Display Macro
    if not GetHandle("Macro " .. lp.MacroSettings.DisplayMacroID) then
        LLog("Warning: Status-Display Macro " .. lp.MacroSettings.DisplayMacroID .. " fehlt!", 3)
        warnings = warnings + 1
    end

    -- CHECK 4: MacroConfig Validierung
    if lp.MacroConfig and lp.MacroSettings.RequireMacroConfig then
        for pageName, pageData in pairs(lp.MacroConfig) do
            if not pageData.actions or #pageData.actions == 0 then
                LLog("Config: Seite '" .. pageName .. "' ist leer.", 3)
                warnings = warnings + 1
            end
        end
    elseif not lp.MacroSettings.RequireMacroConfig then
        LLog("Skipped Macro Config","4")
    else
        LLog("Error: MacroConfig.lua wurde nicht geladen!", 4)
        errors = errors + 1
    end

    -- AUSWERTUNG --
    if errors > 0 then
        MSGBox("Startup Failed", errors .. " kritische Fehler gefunden! Siehe Log.")
        return false
    end

    LLog("Startup-Check erfolgreich: " .. warnings .. " Warnungen ignoriert.", "M")
    return true
end

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

function GetListIndex(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return index
        end
    end
    return nil
end

function PluginDo(Param)
    local sep = "--"
    local operations = StrSplit(Param,sep)
    --Functions
    local function Start() InitPlugin() end
    local function GhostModeToggle() lpS.GhostMode = not lpS.GhostMode end
    local function SupMSGBoxToggle() lpS.SuppressMSGBox = not lpS.SuppressMSGBox end
    local function AutoStartToggle() lpS.AutoStart = not lpS.AutoStart end
    local function Help() LLog("Seperiere mit ".. sep .." um mehrer oder eine Operations auszuführen (für Operations List ".. sep .. "HelpList)",2) end
    --[[local function HelpList() -- HelpList == INOP
        for OpName, _ in pairs(operations) do
            LLog(OpName)
        end
    end ]]--

    local ActionFunctions = {
        ["S"] = Start,
        ["START"] = Start,
        ["GHOSTMODE"] = GhostModeToggle,
        ["SUPMSGBOX"] = SupMSGBoxToggle,
        ["AUTOSTART"] = AutoStartToggle,
        ["HELP"] = Help,
        --["HELPLIST"] = HelpList,
    }
    for _, Iop in ipairs(operations) do
        local op = Iop:gsub("%s+", ""):upper()
        if ActionFunctions[op] then
            ActionFunctions[op]()
        else
            gma.echo("Action " .. op .."nicht gefunden")
        end
    end
end

--#endregion

--#region DimmerManager

-- Dimmer Executor Functions --
function ApplyDimmerValueChange(Target_Exec, Target_Dimmer)
    local execData = EGroup[Target_Exec]
    if not execData then return end
    _G.LivePage.Settings.CurrentInterval = _G.LivePage.Settings.ActiveInterval --Mode = Speeed

    execData.Dimmer = Target_Dimmer
    EvalDimmer()

    local fTime = GetFadeTime() --current

    ExecCmd(string.format("Executor %s At %s Fade %s", execData.Exec, execData.Dimmer, fTime))
    ExecCmd(string.format("Appearance Macro %s /color='%s'", execData.Macro, Color.red))

    DM.IsTrackingFade[Target_Exec] = true
    ExecCmd("CheckFading() " .. Target_Exec .. "; Wait" .. fTime + 0.2) -- fTime + Buffer(0.2s)
    LabelMacro(Target_Exec)
end

function CheckFading(Target_Exec)
    local execData = EGroup[Target_Exec]
    if not Target_Exec or not execData then LLog("CheckFading: Ungültiger Executor!", 3) return end

    local isFading = GetProperty("Executor " .. execData.Exec, 'isFading')

    if isFading == "No" or isFading == nil then
        ExecCmd(string.format("Appearance Macro %s /color='%s'", execData.Macro, Color.grey))
        DM.IsTrackingFade[Target_Exec] = nil -- Tracking beenden
    else
        ExecCmd("CheckFading() " .. Target_Exec .. "; Wait" .. 0.5)
    end
end

function GetFadeTime()
    local handle = GetHandle("Executor " .. DM.fadeTimeFaderName)
    if not handle then return DM.fadeTimeDefault end
    -- Wandelt 0-100% des Faders in Sekunden um
    local faderValue = GetHandleProperty(handle, "fader") or "0"
    return tonumber(faderValue:match("%d+")) / 10 or DM.fadeTimeDefault
end

function EvalSingleDimmer(Target_Exec)
    local val = tonumber(EGroup[Target_Exec].Dimmer) or 0
    if val > 100 then val = 100 end
    if val < 0 then val = 0 end
    EGroup[Target_Exec].Dimmer = tostring(val)
end

function EvalDimmer()
    for key, _ in pairs(EGroup) do
        EvalSingleDimmer(key)
    end
end

function ChangeExecDimmer(Target_Exec, Change_Dimmer)
    Target_Dimmer = EGroup[Target_Exec].Dimmer + Change_Dimmer
    ApplyDimmerValueChange(Target_Exec, Target_Dimmer)
end

function LabelMacro(Target_Exec)
    Macro = EGroup[Target_Exec].Macro
    Dimmer = EGroup[Target_Exec].Dimmer
    Label = EGroup[Target_Exec].Name .. "-" .. Dimmer
    ExecCmd("Label Macro " .. Macro .. " " .. Label)
end

function SetPopUp(T_Exec)
    UserInput = TextInput("Dimmer Wert für " .. EGroup[T_Exec].Name .. " eingeben", EGroup[T_Exec].Dimmer)
    ApplyDimmerValueChange(T_Exec, UserInput)
end

--#endregion

--#region ColorPicking
ColorGroupGroup = {}
ColorGroupNames = {["Name"] = "FaderPage"}
ColorExecColors = {
    normal = {
        blue = {b=100},
        yellow = {r=100,g=100} -- Beispiel 
    }
}
ColorExecOrder = {"r","g","b","a","w","uv"}


function ColorGroupSelect(Name)
    if not ColorGroupNames[Name] then
        LLog("Group Named ".. Name .." not Found", "E")
    end
    ColorGroupGroup[#ColorGroupGroup+1] = Name
end

function ColorGroupDeselect(ungroup) -- if ungroup == true Deselected all execept lastSelected
    local LastSelected
    if ungroup then LastSelected = ColorGroupGroup[#ColorGroupGroup] end
    ColorGroupGroup = {}
    if ungroup then ColorGroupGroup[1] = LastSelected end
end

function SetColorFader(Exec,Value)
    if not GetHandle() then 
        LLog("Fader ".. Exec .." not Found (returned)","E")
        return
    end
    ExecCmd(string.format("Executor %s At %s", Exec, Value))
end

function ApplyColorChange(Fader_Page,Color_Dict,ColorOrder) --Geht alle Attribute in ColorOrder durch
    local faderPosition
    local exec
    local value
    for n, s in ipairs(ColorOrder) do
        value = Color_Dict[s]
        faderPosition = GetListIndex(ColorExecOrder,n)
        exec = string.format("%s.%s", Fader_Page, faderPosition)
        if faderPosition == nil then
            SetColorFader(exec,0)
        elseif GetHandle(exec) then
            SetColorFader(exec,value)
        else
            LLog("ColorFaderHandle ".. exec .." not Found","E")
        end
    end
end

function ApplyGroupColorChanges(Color_Dict)
    local faderPage

    for g in ipairs(ColorGroupGroup) do
        faderPage = ColorGroupNames[g]
        ApplyColorChange(faderPage,Color_Dict,ColorExecOrder) -- ChangeColorOrder Later or Value for ColorName to !normal
    end
end

function PickColor(Color_Name)
    local colorDict
    if ColorExecColors.normal[Color_Name] then
        colorDict = ColorExecColors.normal[Color_Name]
    else
        LLog("Color " .. Color_Name .. "not Found (returned)", "E")
        return
    end
    ApplyGroupColorChanges(colorDict)
end

function PickCustomColor(Custom_Color) -- TODO: CustomColorValidierung
    ApplyGroupColorChanges(Custom_Color)
end



--#endregion
if _G.LivePage.Settings.AutoStart then InitPlugin()
else LLog("LivePage AutoStart deaktiviert. MainPlugin -> InitPlugin", "M") end
return