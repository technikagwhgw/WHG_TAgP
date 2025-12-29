# WHG_TAgP - LivePage System

## GrandMA2 Lua Framework für dynamische Show-Steuerung

Dieses Framework ermöglicht eine intelligente, automatisierte Verwaltung von grandMA2 Shows. Es ist modular aufgebaut und verfügt über integrierte Sicherheitsmechanismen wie einen System-Watchdog.

## System-Architektur & Globaler Namespace

Das System nutzt den globalen Namespace `_G.LivePage`, um Daten zwischen verschiedenen Plugins auszutauschen. (Global Config)

- **Core-Status**: Speichert Version, Laufzeit-Flags (`IsRunning`) und Debug-Modi.
- **Watchdog-Config**: Konfiguration der Ausfallsicherheit.
- **Settings**: Zentrale Steuerung von Loop-Intervallen und Log-Leveln.
- **MacroSettings**: Verwaltung der Hardware-IDs für das Feedback.

### Style Guide (Naming Conventions)

- **GlobalFunction**: `PascalCase`
- **localFunction**: `camelCase`
- **GlobalVariables**: `PascalCase`
- **localVariables**: `camelCase`
- **Argument_Variables**: `Pascal_Snake_Case`

## LivePage Core-Module

### Watchdog (System-Recovery)

Ein eigenständiger Sicherheitsmechanismus, der den `MainLoop` überwacht.

- **Status-Überwachung**: Prüft im Intervall (`WatchDog.Interval`), ob der `LastResponse` Zeitstempel aktuell ist.
- **Pedantic Mode**: Frühwarnsystem, das Meldungen ausgibt, bevor die `MaxResponseTime` erreicht ist.
- **ForceCleanUp**: Bei Neustart werden optional Programmer und Page-Reste bereinigt (`ClearAll`, `Blind Off`, etc.).
- **Restart-Limit**: Deckelt die Neustarts (`RestartCountLimit`), um Endlosschleifen bei fatalen Code-Fehlern zu verhindern.

### Global Logging (LLog)

Ein intelligentes Logging-System (`Lazy Log`), das Nachrichten nach Priorität filtert.

- **Log-Level (0-5)**: Von `0 (All)` bis `4 (Error)` und `5 (None)`.
- **Special Prefixes**: Unterstützt `W` (Watchdog) und `M` (Main) für schnelles Filtern im Command Line Feedback.
- **ForceLog**: Erzwingt die Ausgabe aller Logs im Echo-Fenster, unabhängig vom eingestellten Level.

### Status Dashboard (Feedback Macro)

Visualisierung des Systemzustands auf einem definierten Macro (`DisplayMacroID`):

- **Format**: `(*) RUN LIVE F: 2 RST:1`
- **Blinker (*)**: Zeigt die Aktivität des LivePageMain-Schedulers an.
- **Farblogik**:
  - `Grau`: Normaler Live-Betrieb.
  - `Gelb`: Hilfe-Modus aktiv.
  - `Orange`: Watchdog-Eingriff (Restart erfolgt).
  - `Rot`: System gestoppt.

## Funktions-Module

### Dimmer Manager

Verwaltet Executor-Dimmer (`EGroup`) mit automatischer Rückmeldung und Fade-Berechnung.

- **ApplyValueChange**: Setzt Dimmer-Werte mit dynamischer FadeTime-Abfrage.
- **CheckFading**: Überwacht den `isFading` Status eines Executors und ändert die Macro-Farbe (`Grün` = Fertig, `Rot` = Aktiv).
- **EvalDimmer**: Hard-Limitierung aller Werte zwischen 0 und 100%.
- **SetPopUp**: Ermöglicht manuelle Werteingabe über ein Konsole-Popup.

### Macro Interface

Dynamische Verwaltung der Macro-Oberfläche basierend auf der `MacroConfig.lua`.

- **ConvertMacroAddr**: Berechnet die Ziel-ID aus Koordinaten (X:Y) basierend auf einer `MacroRoot`.
- **SelectPage**: Schaltet zwischen verschiedenen Layouts (z.B. "Spot", "Wash") um.
- **ApplyMacroConfig**: Generiert Macros inklusive Multi-Line Commands und Wait-Times.
- **SmartPress**: Erkennt Single-, Double- und Long-Press (0.5s) Eingaben für erweiterte Button-Funktionen.
- **RadioSelect / CycleEffect**: Funktionen zur Erstellung von Radio-Buttons oder Befehls-Zyklen.

## Development & Testing

### GmaDummy Class

Simuliert die grandMA2 Lua API eine lokale Entwicklung Umgebung.

- **Simulierte Funktionen**: `cmd`, `echo`, `feedback`, `textinput`, `gettime`, `sleep`.
- **Objekt-Mocking**: `show.getobj.handle` löst bekannte Namen (z.B. "Group 1") in Dummy-IDs auf.
- **Property-Mocking**: Simuliert Konsole-Eigenschaften wie `isFading`.

### Real-Time Scheduler (Dummy Beta)

Der Dummy enthält eine experimentelle **Event-Loop**, um Timer-Verhalten zu simulieren:

- **Event-Loop**: Verarbeitet die `_tasks` Tabelle realitätsnah.
- **Pcall-Protection**: Verhindert den Absturz des Test-Skripts bei Fehlern innerhalb eines Timers.

--
*Entwickelt von Aeneas | Version 0.5.4*
