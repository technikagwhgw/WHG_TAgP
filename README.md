# WHG_TAgP - LivePage System (v0.8.0)

## GrandMA2 Lua Framework für dynamische Show-Steuerung

Dieses Framework ermöglicht eine intelligente Verwaltung von grandMA2 Shows ohne die Ressourcenbelastung einer permanenten Hintergrundschleife (Main-Loop). Es nutzt die MA2-interne Command-Line-Engine, um zeitgesteuerte Aufgaben und Feedback-Logik effizient abzuarbeiten.

## System-Architektur & Globaler Namespace

Das System nutzt den globalen Namespace `_G.LivePage`, um Daten konsistent über Plugins hinweg verfügbar zu machen.

- **Core-Status**: Speichert Version, Laufzeit-Flags (`IsRunning`) und Debug-Modi.
- **Settings**: Zentrale Steuerung von Log-Leveln und Sicherheitsmodi (GhostMode, SuppressMSGBox).
- **MacroSettings**: Konfiguration der Hardware-IDs und Root-Indizes für das physische Feedback.
- **Color-Paletten**: Zentralisierte Hex-Farbcodes für ein konsistentes UI-Design.

### Style Guide (Naming Conventions)

- **GlobalFunction**: `PascalCase`
- **localFunction**: `camelCase`
- **GlobalVariables**: `PascalCase`
- **localVariables**: `camelCase`
- **Argument_Variables**: `Snake_Case`

## LivePage Core-Module

### Global Logging (LLog)

Ein intelligentes Logging-System (`Lazy Log`), das Nachrichten nach Priorität filtert.

- **Log-Level (0-5)**: Filtert von `0 (All)` bis `5 (None)`.
- **Special Prefixes**: Unterstützt `M` (Main) und `G` (Ghost) für schnelles Filtern im Command Line Feedback.
- **ForceLog**: Erzwingt die Ausgabe aller Logs im Echo-Fenster, unabhängig vom System-Level.

### Startup-Sequence (`SystemCheck`)

Ein zentraler Validierungs-Check ersetzt manuelle Tests und verhindert Abstürze bei fehlender Hardware.

- **Executor-Check**: Prüft die Existenz aller hinterlegten Executoren (Dimmer & Zeit-Fader).
- **UI-Validierung**: Verifiziert Steuer-Macros und das Status-Display. (Aktuell INOP)
- **Config-Scan**: Validiert die `MacroConfig.lua` auf Vollständigkeit und Syntax.

## Funktions-Module

### Dimmer Manager (Integriert)

Der Dimmer Manager steuert die Intensitäten der Fixtures und liefert visuelles Feedback über den aktuellen Fade-Zustand.

- **Ereignisbasiertes Fading**: Statt einer CPU-lastigen Loop nutzt das System den Befehl `Wait` in der MA2-Commandline. Nach Ablauf der Fade-Zeit triggert die Konsole selbstständig den Abschluss-Check im Plugin.
- **Visual Feedback**: Macros leuchten während eines Fades **Rot** und kehren nach Abschluss (Fade + 0.2s Puffer) zu **Grau** (Idle) zurück.
- **Dynamische Zeitberechnung**: `GetFadeTime()` liest einen definierten Fader (0-100%) aus und skaliert diesen Wert in Sekunden für den `Fade`-Befehl.

### Macro Interface (UI-Steuerung)

Alle Funktionen für MacroInterface haben einen **Betastatus**.

Das Interface-Modul verknüpft die physischen Buttons der Konsole mit der `MacroConfig.lua`.

- **Page-Morphing**: `ChangePage(name)` wechselt das gesamte Button-Layout, schreibt neue Labels und aktualisiert die Farben.
- **Smart Feedback**: `SyncPageUI` prüft, ob Presets "Active" oder Effekte "Running" sind und färbt die Buttons entsprechend ein.
- **SmartPress**: Experimentelle Erkennung von Short-, Double- und Long-Press Aktionen für erweiterte Button-Belegungen.
- **Helper-Funktionen**: Beinhaltet `RadioSelect` (exklusive Auswahl) und `CycleEffect` (Step-by-Step Umschaltung).

## Datentypen in der MacroConfig

| Typ | Beschreibung | Beispiel |
| :--- | :--- | :--- |
| **String** | Einfacher CMD-Befehl | `"Preset 1.1"` |
| **Table** | Sequenz mit Wartezeiten | `{{cmd="...", wait="0.5"}, ...}` |

## Development & Testing

### GmaDummy Class

Ermöglicht die Entwicklung in Standard-Lua-Editoren (VS Code, etc.) außerhalb der Konsole.

- **Dummy**: Simuliert `gma.cmd`, `gma.show.getobj` und `gma.show.property`.
- **UI-Sim**: Emuliert `textinput` und `msgbox` in der Konsole/Terminal.

## Installation

1. Dateien in den `gma2/library/plugins` Ordner kopieren.
2. `LivePageMain.lua`, `MacroInterface.lua` und `MacroConfig.lua` via XML importieren. (Beta)
3. Den `InitPlugin` Call ausführen oder `AutoStart` in den Settings auf `true` setzen.

> [!Warnung]
> **GhostMode**: Wenn `Settings.GhostMode = true`, werden keine Befehle an die Hardware gesendet. Ideal zum Testen von Logik-Abläufen ohne die Show zu beeinflussen.

*Entwickelt von Aeneas | Version 0.8.0 | WHG Technik AG*
