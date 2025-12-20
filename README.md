# WHG_TAgP

Grand Ma2 Lua Plugins

## LivePage Dimmer Manager

* Nutzt ein Tabel `EGroup` in dem die Daten der Executor Gespeichert werden
* Verwendet über die Funktionen `ChangeExecDimmer(Target_Executor, Änderungswert)` und `ApplyValueChange(Target_Executor, SetWert)`
* Hilfsfunktion `EvalDimmer()`: Limitiert alle Dimmerwerte auf einen Interval zwischen 0 und 100

## GmaDummy Class

* Simuliert die `gma` Class außerhalb der Entwicklungsumgebung
* Dummy = Weniger Zeit in GMa2 = mehr Zeit für Entwicklung
* Schnelle Logic Test und einfachere Fehler-Findung
