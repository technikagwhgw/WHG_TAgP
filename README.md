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

### Import

Platziere die Plugins in den GMA Plugins Ordner.
Führe Befehle: `Import "LivePage_Import" At Plugin 2` aus.
Fertig.

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

#### Performance-Schaltung (Eco-Mode)

Das System steuert die CPU-Last der Konsole nun dynamisch über zwei Intervalle:

- **ActiveInterval (0.5s)**: Hohe Präzision, wenn Fader laufen oder User-Interaktionen stattfinden.
- **EcoInterval (1.5s)**: Stromsparender Modus im Leerlauf zur Entlastung der NPU/CPU.
- **Trigger**: Jede Dimmer-Änderung oder aktive Fades schalten das System sofort in den High-Speed-Modus.

#### Smart Startup-Sequence (`SystemCheck`)

Ein zentraler Validierungs-Check vor dem Systemstart ersetzt die alten Einzelfunktionen (`ExecTest`, `ValidateConfig`).

- **Hardware-Check**: Prüft die Existenz aller hinterlegten Executoren und des Fade-Time-Faders.
- **Macro-Validierung**: Verifiziert, dass alle Steuer-Macros und das Status-Display vorhanden sind.
- **Config-Check**: Scannt die `MacroConfig.lua` auf Syntaxfehler oder leere Seiten (`#pageData.actions == 0`).

## Funktions-Module

### Dimmer Manager

#### DM Funktionen

- `ApplyValueChange(T_Exec, T_Dimmer)`: Setzt den Ziel-Wert und triggert die Performance-Schaltung auf Aktiv. Nutzt nun einen Sicherheits-Buffer von 0.2s nach der Fadezeit für den Status-Check.
- `FlashExecutor(T_Exec, FlashDuration)`: Blitzt einen Executor sofort auf 100% und kehrt nach Ablauf der Dauer (Default 0.5s) zum vorherigen Wert zurück. Färbt das Macro währenddessen Gold.
- `CheckFading(T_Exec)`: Hochperformanter Status-Check via `gma.timer`. Reaktiviert sich selbstständig, falls ein Fade durch manuellen Eingriff verlängert wurde.
- `GetFadeTime()`: Holt die aktuelle Zeit des Master-Faders (0-100% skaliert auf Sekunden).
- `LabelMacro(T_Exec)`: Dynamische Beschriftung der Buttons (Name + aktueller Dimmerwert).

### Macro Interface (UI & Page Management)

Das Interface-Modul steuert die physischen Macros auf der grandMA2 und verknüpft diese mit der `MacroConfig.lua`.

#### Hauptfunktionen

- `ChangePage(pageName)`: Der zentrale Befehl für den Seitenwechsel. Aktualisiert automatisch Labels und triggert den UI-Sync.
- `UpdateMacroLabels(pageName)`: Schreibt die Namen aus der Konfiguration auf die Buttons. Bereinigt automatisch ungenutzte Slots.
- `SyncPageUI(pageName)`: Kern des Page-Morphings. Prüft für jeden Button den Status der hinterlegten `syncID` und setzt die Appearance (Farbe).
- `IsContentActive(type, id)`: Hardware-Abfrage an die MA2. Erkennt, ob Presets "Active" im Programmer sind oder Effekte "Running" im Playback.

#### Zusatzfunktionen

- **ConvertMacroAddr**: Berechnet die Ziel-ID aus Koordinaten (X:Y) basierend auf einer `MacroRoot`.
- **SmartPress**: Erkennt Single-, Double- und Long-Press (0.5s) Eingaben für erweiterte Button-Funktionen.
- **RadioSelect / CycleEffect**: Funktionen zur Erstellung von Radio-Buttons oder Befehls-Zyklen.

#### Unterstützte Datentypen in der Config

| Typ | Beschreibung | Beispiel |
| :--- | :--- | :--- |
| **String** | Einfacher CMD-Befehl | `"Preset 1.1"` |
| **Table** | Sequenz mit Wartezeiten | `{{cmd="...", wait="0.5"}, ...}` |

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

## Dokumentations- & Hilfe-System

Um die Bedienung für die Technik-AG zu erleichtern, verfügt das Framework über ein zweistufiges Hilfesystem. Es kombiniert technische Daten aus der Konfiguration mit verständlichen Erklärungen zu den internen Funktionen.

### LpHelp Python-Tool

Das Tool `LpHelp.py` ist ein externer Helfer, der parallel zur Show oder während der Programmierung am PC genutzt werden kann.

- **Single Source of Truth**: Das Skript liest direkt die `MacroConfig.lua` und die `DOKU.txt` ein. Änderungen an der Konfiguration sind sofort in der Hilfe sichtbar.
- **Intelligente Suche**: Sucht nach Stichworten in Namen, Positionen und Hilfetexten.
- **System-Erklärungen**: Importiert Prosa-Texte aus der `DOKU.txt`, um komplexe Logik (wie den Watchdog) verständlich zu machen.

**Nutzung:**

```bash
python LpHelp.py
Gib einfach ein Schlagwort wie "Dimmer", "Watchdog" oder "Macro" ein.

Dokumentations-Struktur (DOKU.txt)
In der DOKU.txt werden die internen Module detailliert beschrieben. Jeder Abschnitt beginnt mit ###, gefolgt vom Modulnamen.
```

> [IMPORTANT]
> **Startup-Fehler**: Sollte das System beim Start rot leuchten oder eine MessageBox zeigen, wurde ein kritischer Hardware-Fehler gefunden (z.B. Executor gelöscht). Prüfe das Command Line Feedback für Details der `Startup-Sequence`.

## Version 0.6.x Highlights

- **Page-Morphing & Sync**: Dynamisches UI-Feedback. Macros zeigen durch Farben (`ActiveColor`) an, ob Presets oder Effekte in der Konsole bereits aktiv sind.
- **Smart Startup-Sequence**: Zentraler `SystemCheck()` validiert Hardware (Executoren), Macros und die `MacroConfig.lua` vor dem Start.
- **Dynamic Performance**: CPU-schonender "Eco-Mode" (1.5s Tick) im Leerlauf und automatischer "High-Performance" Modus (0.5s Tick) bei Aktivität.
- **Safe Execution**: Vollständige Trennung von Logik und Daten zur Vermeidung von Typ-Fehlern (`string|table` Fix).

--
*Entwickelt von Aeneas | Version 0.6.4*
