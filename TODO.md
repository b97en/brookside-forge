# TODO

## Session 9 art audit (what the packs cover vs. genuine gaps)

**Covered by owned packs (no custom art needed):**
- Anvil station — free_pack `Stations/Anvil/Anvil.png` (in use)
- Furnace + forge fire — free_pack `Stations/Furnace` + `Bonfire/Fire_01-Sheet` (in use)
- Ore node — free_pack `Props/Static/Rocks.png` (in use)
- Player, NPC, village/interior tiles — in use

**Genuine gaps (custom art candidates, strictly optional for the POC):**
- **Notice board sprite** — nothing suitable in free_pack Props/Tools.
  Currently a ColorRect-assembled placeholder in `scenes/notice_board.tscn`
  that reads acceptably. To replace: ~32x28 px, palette matched to free_pack
  browns; drop into the tscn as a Sprite2D and delete the ColorRects.
- **Forged item sprites** (scythe, horseshoes, gate hinges; later the katana-influenced blades) —
  the East-meets-West objects no fantasy pack has. Inventory is text-only in
  the POC, so this only matters if we add an "item get" popup or delivery
  visual. `forge/Weapons/Fire Weapons.png` works as a stand-in for blades.

## Other

- WAV SFX are procedurally generated placeholders (tools session 8 PowerShell).
  Replace with Kenney/freesound picks if they grate — check licences.

## Session 11 (loop extension) — follow-ups

- Mining uses the free_pack `Collect_Base` swing. If a proper pick-swing
  reads better, `Crush_Base` (8 frames, same layout) is a drop-in: change the
  `player_animation` export on `scenes/ore_node.tscn` and add the frames to
  `scenes/player.tscn` the same way as `collect_*`.
- The ore rock is still infinite and instant apart from the swing. If
  playtesters never leave the rock, add a short "picked clean" cooldown.
