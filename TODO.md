# TODO

## Open question: art direction

Pixel Crawler leans fantasy-dungeon, and the village reads more fantasy than
post-war Yorkshire. That's fine for the POC, but it decides whether the full
game can ship on these packs or needs an art budget.

## Art gaps

The owned packs already cover the anvil, furnace and forge fire, ore rock,
player, NPC, and village and interior tiles. The remaining gaps are
optional for the POC:

- **Notice board sprite.** Nothing suitable in free_pack Props/Tools. It's
  currently built from ColorRects in `scenes/notice_board.tscn` and reads
  acceptably. To replace it, make a ~32×28 px sprite in the free_pack browns,
  add it as a Sprite2D and delete the ColorRects.
- **Forged item sprites** (scythe, horseshoes, gate hinges, and later the
  katana-influenced blades). No fantasy pack has these East-meets-West objects.
  Inventory is text-only, so this only matters if we add an "item get" popup
  or a delivery visual. `forge/Weapons/Fire Weapons/Fire Weapons.png` works as
  a stand-in for blades.

## Audio

- The WAV SFX in `assets/audio/` are procedurally generated placeholders (from
  a one-off PowerShell script in session 8, not kept in the repo). Swap in
  Kenney or freesound picks if they grate, and check the licences.

## Gameplay follow-ups

- Mining uses the free_pack `Collect_Base` swing. If a proper pick-swing reads
  better, `Crush_Base` (8 frames, same layout) is a drop-in: change the
  `player_animation` export on `scenes/ore_node.tscn` and add the frames to
  `scenes/player.tscn` the same way as `collect_*`.
- The ore rock never runs out, and mining is instant apart from the swing. If
  playtesters never leave the rock, add a short "picked clean" cooldown.
