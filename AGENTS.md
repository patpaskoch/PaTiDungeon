# AGENTS.md — PaTiDungeon

**Read the suite rules first: [`../../PaTiAdmin/AGENTS.md`](../../PaTiAdmin/AGENTS.md).** They apply here in full.
Addon facts: `../../PaTiAdmin/docs/ARCHITECTURE.md` · open issues: `../../PaTiAdmin/docs/FOLLOW_UPS.md`.

## This addon
- Purpose: instance name/type. Display only. Group lines and combat state removed (owner 2026-10-17: PaTiGroup shows the people, WoW shows combat).
- Files: `Logic.lua` (settings, status normalisation; pure, tested) · `PaTiDungeon.lua` (API adapter `readStatus`,
  window, settings, commands, events) · `Locales/` · `Shared/` (PaTiShared, synced — never edit).
- SavedVariables: `PaTiDungeonDB` (per character), schema 1: x, y (+ point/relativePoint once dragged), locked, collapsed, scale, language.
- Secure / combat-sensitive: none. Events are rare (login, zone changes), so a full repaint is fine.
- API flags may be true/false or 1/nil depending on the client — `Logic.Status` accepts both.
- No boss data, loot lists or other dungeon features in this addon without an owner decision.
- Slash commands: `/pd`, `/patidungeon`.

## Checks
`bash ../../PaTiAdmin/tools/check.sh .` before every commit. Manual WoW tests: `../../PaTiAdmin/docs/TESTING.md`.
