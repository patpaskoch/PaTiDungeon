# PaTiDungeon

Instanz-, Gruppen- und Kampfstatus für den WoW-Forever-Client (Interface 16001). Reine Anzeige.

## Funktionen
- Name und Art der Instanz (Dungeon, Schlachtzug, Schlachtfeld …), Gruppengröße, Kampfstatus, ob du die Gruppe leitest
- Menü `•••`: Einstellungen, Sperren/Entsperren, Ein-/Ausklappen, Testmodus, Ausblenden
- Einstellungen: Sprache, Größe, Fenstersperre; Position wird gespeichert

## Befehle
`/pd`, `/patidungeon` — ohne Zusatz ein-/ausblenden; `show`, `hide`, `test`, `lock`, `unlock`, `reset` (Position),
`settings`, `debug`, `version`.

Gemeinsame Oberfläche: PaTiShared UI (eingebettet in `Shared/`, kein separates Addon nötig).
