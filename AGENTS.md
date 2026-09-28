# AGENTS.md — PaTiDungeon

**Read the suite rules first: [`../../PaTiAdmin/AGENTS.md`](../../PaTiAdmin/AGENTS.md).** They apply here in full
(independence, combat lockdown, no automation, localization, tests, Definition of Done, VALIDATION output).
Addon facts: `../../PaTiAdmin/docs/ARCHITECTURE.md` · open issues: `../../PaTiAdmin/docs/FOLLOW_UPS.md`.

## This addon
- Purpose: instance name/type, group size, combat and leader status.
- SavedVariables: `PaTiDungeonDB` (per character): x, y, locked.
- Secure / combat-sensitive: none (no secure frames).
- Slash commands: `/pd`, `/patidungeon` — test, show, hide, lock, unlock.
- Uses the legacy `PaTiSharedPanel.lua` (FOLLOW_UPS F6).

## Checks
`bash ../../PaTiAdmin/tools/check.sh .` before every commit. Manual WoW tests: `../../PaTiAdmin/docs/TESTING.md`.
