# PaTiDungeon

<img src="assets/icon-128.png" width="96" alt="PaTiDungeon icon">

Instance, group and combat status at a glance, for World of Warcraft: Forever (Interface 16001). Display only.

> Status: 0.1.0, in development, not yet released. Not yet tested in game since the rework.

## Features
- Instance name and type (dungeon, raid, battleground …), group size, combat state, whether you lead the group
- ••• menu: Settings, Lock, Collapse, Test Mode, Hide. Settings: language, scale, lock.
  Languages: English, Deutsch (others fall back to English)

## PaTiSuite

This addon is part of the **PaTiSuite** — a collection of small addons for World of Warcraft: Forever.
Each one is installed on its own and works on its own; none of them is needed by another.

- [PaTiSuite](https://github.com/patpaskoch/PaTiSuite) – optional control panel to show and hide the PaTi windows
- [PaTiHeal](https://github.com/patpaskoch/PaTiHeal) – healing: party frames, heal target, click casting, HoTs, dispels
- [PaTiAuras](https://github.com/patpaskoch/PaTiAuras) – buffs, procs, tracking, group buffs and weapon imbues
- [PaTiTank](https://github.com/patpaskoch/PaTiTank) – tank HUD and aggro monitor
- [PaTiRota](https://github.com/patpaskoch/PaTiRota) – your own skill priority with cooldowns and fixed cast buttons
- [PaTiGroup](https://github.com/patpaskoch/PaTiGroup) – party awareness: tank, healer, roles and the tank's target
- [PaTiLead](https://github.com/patpaskoch/PaTiLead) – lead the group: raid markers, ready check and pull timer
- [PaTiQuest](https://github.com/patpaskoch/PaTiQuest) – selected quest and its objectives
- **PaTiDungeon** – instance, group and combat status *(this addon)*
- [PaTiSocial](https://github.com/patpaskoch/PaTiSocial) – "Party Social": quick emote and message buttons
- [PaTiAlerts](https://github.com/patpaskoch/PaTiAlerts) – one window for open problems

### Goes well with (optional)

- [PaTiQuest](https://github.com/patpaskoch/PaTiQuest) – your selected quest and its objectives
- [PaTiLead](https://github.com/patpaskoch/PaTiLead) – manual group tools: raid markers, ready check, pull timer
- [PaTiSuite](https://github.com/patpaskoch/PaTiSuite) – shows and hides this window together with the other PaTi windows

## Installation
1. Download the release zip (`PaTiDungeon-<version>.zip`).
2. Unpack it and copy the folder `PaTiDungeon` into `World of Warcraft/<client>/Interface/AddOns/`.
3. Start WoW and enable PaTiDungeon in the AddOns list.

## First steps
- Enter a dungeon or join a group — the window updates by itself
- `/pd test` shows example data

## Settings
`/pd settings` or ••• → Settings: language, scale, window lock.
- **Window:** panel opacity (30–100 %)

## Commands
`/pd` or `/patidungeon` — alone: show/hide · `settings` · `test` · `show` · `hide` · `lock` · `unlock` ·
`reset` (position) · `debug` · `version`

## Development

Architecture, tests and engineering rules of the suite: [PaTiAdmin](https://github.com/patpaskoch/PaTiAdmin). PaTiAdmin is not a WoW addon — players do not install it. The shared UI code (PaTiShared) is already embedded in this addon's `Shared/` folder; there is nothing extra to install.

## License
MIT — see [LICENSE](LICENSE). Copyright (c) 2026 Patrick Koch.
