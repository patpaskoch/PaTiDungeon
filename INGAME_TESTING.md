# Ingame Testing – PaTiDungeon

World of Warcraft: Forever
Interface: 16001

Diese Datei dokumentiert ausschließlich Tests im echten WoW-Client.

Automatisierte Tests, CI und Code Review zählen NICHT als Ingame-Verifikation.
Regeln und Eintragen von Ergebnissen: [PaTiAdmin/docs/TESTING.md](https://github.com/patpaskoch/PaTiAdmin/blob/main/docs/TESTING.md#in-game-test-files).

Scope: Instanz (Name, Typ), Gruppengröße, Kampfstatus, Gruppenleitung. Keine Boss-, Loot- oder Dungeonquest-Funktionen.

## Legende

- [ ] offen / noch nicht bestätigt
- [x] vom Owner im echten Client bestätigt
- ❌ FAIL = im echten Client fehlgeschlagen
- 🔧 FIX IMPLEMENTED = Codefix vorhanden, Retest noch offen
- ✅ VERIFIED = erfolgreich im echten Client bestätigt
- MANUAL RETEST REQUIRED = erneuter Test notwendig

## Installation / Laden

- [ ] PT-DUNGEON-001 Fresh Install aus dem Release-ZIP: genau ein Ordner `PaTiDungeon/`, Addon lädt allein
- [ ] PT-DUNGEON-002 PaTiDungeon erscheint in der AddOn-Liste mit Beschreibung
- [ ] PT-DUNGEON-003 Icon in der AddOn-Liste korrekt, keine weiße oder fehlende Textur
- [ ] PT-DUNGEON-004 Login ohne Lua-Fehler
- [ ] PT-DUNGEON-005 `/reload` ohne Lua-Fehler

## Fenster

- [ ] PT-DUNGEON-010 `/pd` bzw. `/patidungeon` blendet das Fenster ein und aus; `/pd show`, `/pd hide`
- [ ] PT-DUNGEON-011 Fenster am Header verschieben (entsperrt)
- [ ] PT-DUNGEON-012 Position bleibt nach `/reload`
- [ ] PT-DUNGEON-013 Lock/Unlock (••• und `/pd lock` / `unlock`): gesperrt nicht verschiebbar
- [ ] PT-DUNGEON-014 Größe (Scale) wirkt
- [ ] PT-DUNGEON-015 Einstellungen öffnen (`/pd settings` und •••) und speichern
- [ ] PT-DUNGEON-016 Collapse/Expand über •••, Zustand bleibt nach `/reload`
- [ ] PT-DUNGEON-017 Test Mode `/pd test` zeigt Beispieldaten
- [ ] PT-DUNGEON-018 Panel-Deckkraft 30–100 %: nur der Hintergrund ändert sich
- [ ] PT-DUNGEON-019 Keine Einrast-Einstellung mehr, Fenster frei verschiebbar
- [ ] PT-DUNGEON-020 `/pd reset` setzt die Position zurück

## SavedVariables

- [ ] PT-DUNGEON-030 Einstellungen bleiben nach `/reload`
- [ ] PT-DUNGEON-031 Einstellungen bleiben nach Relog
- [ ] PT-DUNGEON-032 Update mit alten Einstellungen: Position und Werte bleiben
- [ ] PT-DUNGEON-033 „Standard wiederherstellen“ setzt die Einstellungen zurück

## Sprachen

- [ ] PT-DUNGEON-040 deDE: alle Texte deutsch
- [ ] PT-DUNGEON-041 Sprache enUS in den Einstellungen: nach `/reload` englisch
- [ ] PT-DUNGEON-042 zhCN/zhTW/koKR: Englisch als Rückfall, keine Schlüsselnamen oder Kästchen
- [ ] PT-DUNGEON-043 Keine abgeschnittenen wichtigen Texte (deDE), lange Instanznamen

## Instanz / Gruppe / Kampf

- [ ] PT-DUNGEON-050 Außerhalb einer Instanz: richtige Anzeige (keine Instanz)
- [ ] PT-DUNGEON-051 Dungeon betreten: Name und Typ „Dungeon“ erscheinen
- [ ] PT-DUNGEON-052 Dungeon verlassen: Anzeige wechselt zurück
- [ ] PT-DUNGEON-053 Andere Instanztypen (Schlachtzug, Schlachtfeld) werden richtig benannt, falls getestet
- [ ] PT-DUNGEON-054 Gruppengröße stimmt (solo, Gruppe)
- [ ] PT-DUNGEON-055 Gruppenänderung (Beitritt/Verlassen) aktualisiert die Anzeige
- [ ] PT-DUNGEON-056 Gruppenleitung wird richtig angezeigt, auch nach Leiterwechsel
- [ ] PT-DUNGEON-057 Kampfbeginn: Kampfstatus wechselt
- [ ] PT-DUNGEON-058 Kampfende: Kampfstatus wechselt zurück
- [ ] PT-DUNGEON-059 Nach `/reload` in einer Instanz / Gruppe sofort richtige Anzeige

## Combat / Sicherheit

- [ ] PT-DUNGEON-060 Kein Lua-Fehler im Kampf
- [ ] PT-DUNGEON-061 Keine `ADDON_ACTION_BLOCKED` / `ADDON_ACTION_FORBIDDEN`
- [ ] PT-DUNGEON-062 `taint.log` (`/console taintLog 1`) ohne PaTiDungeon-Eintrag

## Combined

- [ ] PT-DUNGEON-070 Zusammen mit allen PaTi-Addons geladen: kein Lua-Fehler
- [ ] PT-DUNGEON-071 Keine Slash-Command-Kollision: `/pd` und `/patidungeon` antworten nur PaTiDungeon
- [ ] PT-DUNGEON-072 Eigene Einstellungen speichern nur PaTiDungeon-Werte; Fenster erscheint in PaTiSuite
