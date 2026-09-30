# Changelog

Format: `## [Unreleased]` / `## [x.y.z] - YYYY-MM-DD` with Added, Changed, Fixed, Removed, Known Issues.
History before this file: `git log`.

## [Unreleased]
### Added
- Window settings (PaTiShared): panel opacity 30–100 % (default 75 %, the header stays opaque) and snapping to other
  PaTi windows while dragging (on by default; never in combat). The window registers itself for the optional
  PaTiSuite control panel, which shows/hides it with this addon's own rules.
- AddOns list icon from the PaTiSuite icon set (`Media/icon.tga`, `## IconTexture`); platform images in `assets/`.
- MIT license (`LICENSE`, not part of the release zip).
- PaTiShared window with ••• menu (Settings, Lock/Unlock, Collapse/Expand, Test Mode, Hide), settings modal
  (language, scale, lock), `/pd settings, reset, debug, version`; `/pd` alone shows/hides the window.
- English texts, German translation; instance types are shown with a translated name instead of the raw API word.
### Changed
- AddOns list description in English with a German translation (`## Notes-deDE`); README rewritten for players
  (features, installation, first steps, commands, known limitations).
- New PaTiShared look instead of the legacy panel (gear, chevron, close button).
- Settings in PaTiDungeonDB get a schema; the 0.1.0 position and lock state are kept.
### Fixed
- The addon did not load: the TOC listed both Lua files on one line with a literal `` `r`n `` between them.
- Instance name, type, group size and flags are checked for restricted (secret) values before use (`Logic.Status`).
- Saving defaults into the saved variables on every login (`x = x or -330`) is gone.
### Removed
- `PaTiSharedPanel.lua` (legacy shared panel global).
### Known Issues
- Not tested in game yet (instance/zone changes, group changes, combat).
