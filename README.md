# WHG_TAgP

Grand Ma2 Lua Plugins

## Prologue

### Vorwort

In dieses README wird vorerst die Documentation der Plugins kommen. Ich werde versuchen das es so verständlich wie möglich wird diese Plugins zu nutzen und zu modifieziern.  
– Aeneas

### Style Guide

- GlobalFunction = PascalCase
- localFunction = camelCase
- GlobalVariables = PascalCase
- localVariables = camelCase
- Argument_Variables = Pascal_Snake_Case
- Classes = PascalCase
- Classes.Sub = camalCase/PascalCase

Class gmaDummy ausgenommen.

## LivePage

### Dimmer Manager

#### DM Zusammenfassung

Basis Plugin/Utility für Projekt LivePage. Verwaltetet Executor Dimmer mit Hilfe von Macros und einem FadeTineFader. Nutzt ein Group aller Executor und deren Attribute.

#### DM Funktionen

- `ApplyValueChange(T_Exec, T_Dimmer)`: Setz `Target_Exec` auf `Target_Dimmmer` mit Fade des FadeTimeFaders.
- `ChangeExecDimmer(T_Exec, C_Dimmer)`: Ändert `Dimmer` von `Target_Exec` um `Change_Dimmer`.
- `FadeTime()`: Übernimmt den Aktuellen Wert des `FadeTimeFader`.
- `EvalDimmer()`: Limitiert alle Executor Dimmerwerte auf ein Minumum bzw. Maximum von 0 bzw. 100.
- `LabelMacro(T_Exec)`: Ändert das Label des DimmerRoot Macros auf von `Target_Exec` den `Target_Exec.Name` und Aktuellen Dimmerwert.
- `SetPopUp(T_Exec)`: Öffnet ein PopUp für die Eingabe von einem Spezifischen Dimmer Wert für `Target_Exec`.
- `CheckFading(T_Exec)`: Ändert die Farbe wenn der Fade Abgeschlossen ist wider auf Grün mit Hilfe des Timer Schedulers.
- `ExecTest()`: Testet ob die Objekte in EGroup in GMA vorhanden sind.

## GmaDummy Class

### GD Zusammenfassung

Eine Simmulierung der Echten gma Classe um Entwicklung zubeschleundigen und local zu testen ohne die GMa2 Umgebung. Gibt meistens einfach die Argumente mit dem Namen der Funktion aus. (siehe unten)

### GD Funktionen

- cmd(text) -> GMA_CMD >> `text`
- echo(text) -> GMA_ECHO >> `text`
- textinput(title,default) -> GMA_INPUT_PROMPT [`title`]: Default is `default`
- timer(func,delay,count) -> GMA_TIMER: Scheduled function `func` to run every `delay` s `count` times
- sleep(seconds) -> "GMA_SLEEP: Waiting `seconds` s
- gettime -> OS Time
- gui.msgbox(title,text) -> GMA_MSGBOX [`title`]:`text`
- gui.confirm(title,text) -> GMA_CONFIRM [`title`]:`text`
- show.getvar(varname) -> GMA_GETVAR: Requesting $`varname`  (return dummy value 1)
- show.setvar(varname,value) -> GMA_SETVAR: $`varname` set to `value`
- show.getobj.handle(name) -> Wandlet Objekt Namen in GMA Handle um (*.handle("Exsample_Exec") -> 14203456).
- show.getobj.label(handle) -> Returned den String des Labels eines Handles.
- show.property.get(handle,prop) -> Returned den Zustand oder Wert einer Eigenschaft eines Handles.

## Macro Interface

### MI Zusammenfassung

Basis Plugin/Utility für Projekt LivePage. Verwaltetet die Macros der LivePage mit Hilfe der Macro Config.

### MI Funktionen

- `ConvertMacroAddr(Macro_Addr)`: Wandelt eine `MacroAddresse` im Format X:Y und ein `MacroRoot` in eine Macro ID um.
- `SelectPage(PageName)`: Wendet die Config einer Page auf die LivePage.

### MI Config

Beispiel Konfiguration:

 `MacroConfig["Spot"] = {`  
 `color = Color.cyan,`  
 `actions = {[1] = {`  
 `name = "Gobo Wheel",`  
 `cmd = "Attribute 'Gobo1' At +10",`  
 `pos = "2:7"}`  
 `} }`
