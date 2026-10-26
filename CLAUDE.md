# Brookside Forge — POC

A cozy, top-down pixel-art sim set in post-war Yorkshire. The player inherits a
blacksmith's forge and rebuilds a village community. Think Stardew Valley pacing,
older audience, blacksmithing as the central mechanic.

**This repo is a proof-of-concept, not the game.** The POC proves one thing:
the core loop is fun and tangible. Nothing outside the POC scope below should
be built, scaffolded, or "prepared for" without being asked.

## POC scope (the whole scope)

1. Player moves around a small village tilemap (one exterior scene, one forge interior).
2. Player reads a commission from a notice board ("The farmer needs a scythe").
3. Player gathers ore from a marked node (walk up, press interact, receive item).
4. Player uses the forge: a timing-based hammer mini-game produces the item.
   Quality (poor/good/perfect) depends on mini-game performance.
5. Player delivers the item to one NPC, receives gold, sees a thank-you line.
6. Gold total and inventory persist via a minimal save/load (single JSON file).

### Explicit non-goals (do not build)
- Farming, fishing, beekeeping, combat, day/night, seasons, skill trees
- Multiple NPCs with relationship bars (one NPC, no relationship system)
- Dialogue trees (single-line dialogue boxes only)
- Settings menus, localization, controller support, export pipelines

## Tech

- **Engine:** Godot 4.x, GDScript only (no C#)
- **Resolution:** 640×360 base, integer-scaled, pixel-perfect (snap transforms,
  nearest-neighbour filtering)
- **Art:** Pixel Crawler packs (Anokolisa, itch.io — paid licence) in
  `assets/packs/`, 16×16 tiles, 4-directional character sheets. Sheet layouts
  and frame sizes are documented in `assets/packs/README.md` — consult it
  before wiring up any AnimatedSprite2D or TileSet. If an asset is missing,
  use a labelled ColorRect placeholder and note it in TODO.md; do not generate
  or request custom art.
- **Licensing:** pack assets must not be redistributed. `assets/packs/` is
  gitignored unless this repo is private — never suggest committing raw pack
  files to a public remote.

## Conventions

- Scenes: one scene per logical unit (`player.tscn`, `forge_minigame.tscn`,
  `village.tscn`). Scene-owned scripts named to match.
- Files/folders: snake_case. Classes: PascalCase with `class_name`.
- Typed GDScript everywhere (`var speed: float = 80.0`, typed function signatures).
- Communication between systems via signals, routed through a thin `Events`
  autoload (signal bus). No deep node-path coupling (`get_node("../../..")` is
  a code smell — flag it).
- Game data (items, commissions, recipes) lives in `data/*.json`, loaded by a
  `DataLoader` autoload. No item definitions hard-coded in scripts.
- Player-facing state (inventory, gold) in a `GameState` autoload; saved to
  `user://save.json`.

## Workflow rules

- Work in small vertical increments. One feature per session, committed when
  the human confirms it runs correctly in the editor.
- You cannot see the running game. After implementing, tell the human exactly
  what to run and what to look for. Wait for their report before continuing.
- Headless checks: `godot --headless --check-only path/to/script.gd` for parse
  errors; prefer running this yourself before handing over.
- When you build a system, end with a 3–5 sentence plain-English explanation of
  how it works and why it's structured that way. The human is learning Godot —
  teaching is part of the job.
- If the human asks for something outside POC scope, say so before implementing.
