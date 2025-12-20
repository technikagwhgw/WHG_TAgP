# WHG_TAgP

Grand Ma2 Lua Plugins

## Vorwort

In dieses README wird vorerst die Documentation der Plugins kommen. Ich werde versuchen das es so verständlich wie möglich wird diese Plugins zu nutzen und zu modifieziern.  
– Aeneas

## LivePage

### Dimmer Manager

#### DM Zusammenfassung

Basis Plugin/Utility für Projekt LivePage. Verwaltetet Executor Dimmer mit Hilfe von Macros und einem FadeTineFader. Nutzt ein Tabel der Alle Executor und deren Attribute Enthält.

#### DM Funktionen

* `ApplyValueChange(T_Exec, T_Dimmer)`: Setz `Target_Exec` auf `Target_Dimmmer` mit Fade des FadeTimeFaders.
* `ChangeExecDimmer(T_Exec, C_Dimmer)`: Ändert `Dimmer` von `Target_Exec` um `Change_Dimmer`.
* `FadeTime()`: Übernimmt den Aktuellen Wert des `FadeTimeFader`.
* `EvalDimmer()`: Limitiert alle Executor Dimmerwerte auf ein Minumum bzw. Maximum von 0 bzw. 100.
* `LabelMacro(T_Exec)`: Ändert das Label des DimmerRoot Macros auf von `Target_Exec` den `Target_Exec.Name` und Aktuellen Dimmerwert.
* `SetPopUp(T_Exec)`: Öffnet ein PopUp für die Eingabe von einem Spezifischen Dimmer Wert für `Target_Exec`.
* `CheckFading(T_Exec)`: Ändert die Farbe wenn der Fade Abgeschlossen ist wider auf Grün mit Hilfe des Timer Schedulers

## GmaDummy Class

### GD Zusammenfassung

Eine Simmulierung der Echten gma Classe um Entwicklung zubeschleundigen und local zu testen ohne die GMa2 Umgebung. Gibt meistens einfach die Argumente mit dem Namen der Funktion aus. (siehe unten)

### GD Funktionen

* cmd(text) -> GMA_CMD >> `text`
* echo(text) -> GMA_ECHO >> `text`
* textinput(title,default) -> GMA_INPUT_PROMPT [`title`]: Default is `default`
* timer(func,delay,count) -> GMA_TIMER: Scheduled function `func` to run every `delay` s `count` times
* sleep(seconds) -> "GMA_SLEEP: Waiting `seconds` s
* gettime -> OS Time
* gui.msgbox(title,text) -> GMA_MSGBOX [`title`]:`text`
* gui.confirm(title,text) -> GMA_CONFIRM [`title`]:`text`
* getvar(varname) -> GMA_GETVAR: Requesting $`varname`  (return dummy value 1)
* setvar(varname,value) -> GMA_SETVAR: $`varname` set to `value`
