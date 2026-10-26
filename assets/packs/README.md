# Asset packs — sheet layout reference

Pixel Crawler packs by Anokolisa (itch.io, paid licence). **Do not redistribute.**
These files are committed only because the repo is private. Original zips and
unused packs live in `_archive/`, which has a `.gdignore` so Godot doesn't
import them (it is still in git).

**Globals:**
- Tile grid: **16×16** everywhere.
- Character sheets are single-row strips, one file per facing direction:
  `*_Down-Sheet.png`, `*_Side-Sheet.png`, `*_Up-Sheet.png`.
- **All `Side` sheets face RIGHT** (verified visually). Use `flip_h = true` for left.
- Frame count = sheet width ÷ frame width. All numbers below verified from PNG headers.
- Watch out: some paths contain spaces and apostrophes (`Npc's`, `Fire Weapons`).

## free_pack/

### Player character — `Entities/Characters/Body_A/Animations/`
Frames are **64×64** (the visible sprite is roughly 16×24, centred, with
generous transparent padding — collision shapes should be much smaller than the frame).

| Animation | Frames | Sheet size | POC use |
|---|---|---|---|
| `Idle_Base` | 4 | 256×64 | player idle |
| `Walk_Base` | 6 | 384×64 | player walk |
| `Run_Base` | 6 | 384×64 | optional |
| `Carry_Idle` | 4 | 256×64 | carrying ore/items |
| `Carry_Walk`, `Carry_Run` | 6 | 384×64 | carrying ore/items |
| `Crush_Base` | 8 | 512×64 | hammer-swing candidate |
| `Collect_Base` | 8 | 512×64 | ore gathering |
| `Hit_Base` | 4 | 256×64 | — |
| `Death`, `Fishing`, `Pierce`, `Slice`, `Watering` | 8 | 512×64 | not needed |

Quirk: `Pierce_Base` names its up-facing sheet `Pierce_Top-Sheet.png`, not `_Up`.

### NPCs — `Entities/Npc's/{Knight, Rogue, Wizzard}/`
- `Idle/Idle-Sheet.png`: 4 frames of **32×32** (128×32).
- `Run/Run-Sheet.png`: 6 frames of **64×64** (384×64) — note the frame size
  *differs* from idle. The POC's farmer NPC only needs an idle.
- No down/side/up variants — single facing only.

### Tilesets — `Environment/Tilesets/` (all 16×16 grid)
- `Floors_Tiles.png` (400×416) — grass/dirt/paths
- `Wall_Tiles.png` (400×400), `Wall_Variations.png` (256×480)
- `Water_tiles.png` (400×400)
- `Dungeon_Tiles.png` (400×400)

### Buildings — `Environment/Structures/Buildings/`
`Floors.png`, `Walls.png`, `Roofs.png`, `Props.png`, `Shadows.png` — use for
the forge building exterior in the village.

### Stations — `Environment/Structures/Stations/`
- **Anvil/**: `Anvil.png` (272×160) holds static anvil variants — use this for
  the POC. `Anvil_01..03-Sheet.png` are large multi-row animation sheets
  (512×400 and up); frame size **unverified** — inspect in the editor before slicing.
- **Furnace/**: `Furnace.png` (192×384) static variants; `Iron/Stone/Bricks_*-Sheet.png`
  animated upgrade tiers (64×96–96×128), frame size **unverified**.
- **Bonfire/**: `Fire_01-Sheet.png`, `Fire_02-Sheet.png`, `Smoke-Sheet.png` —
  best candidates for the animated forge fire.
- Also: Alchemy, Cooking Station, Sawmill, Workbench (not needed for POC).

### Props — `Environment/Props/Static/`
- `Resources.png` (400×400): **coal/ore piles top-left**, ingots, gems, logs —
  source for the ore node contents and item icons.
- `Rocks.png` (208×304): boulder clusters in brown and grey — ore node body.
- `Furniture.png` (800×864), `Tools.png` (400×400), `Farm.png`, `Vegetation.png`,
  `Dungeon_Props.png`, `Shadows.png`.
- Trees: `Trees/Model_01..03/Size_02..05.png` (various sizes, no animation).
- `Props/Animated/Pan_*-Sheet.png` — animated water pans.

### Also at pack root
`Icons/` (item icons) and `Weapons/` (Bone/Hands/Wood) — possible inventory icons.

## forge/

- `Assets/Tiles.png` (400×400, 16×16) — **forge interior tileset** (stone,
  lava-glow accents). The main reason this pack is here.
- `Weapons/Fire Weapons/Fire Weapons.png` — glowing forged-weapon sprites,
  stand-ins for forged-item art until custom sprites exist.
- `Enemy/` (stone golems) and `Social/` (cover art) — not needed.
- `Terms.txt` — licence terms, worth a skim.

## cave/

- `Assets/Tiles.png` (272×304, 16×16) — cave/mine tileset, for dressing the
  ore-gathering corner of the map.
- `Assets/Props.png` (384×256) — **mushrooms only, no ore props** (verified
  visually). Ore comes from free_pack `Resources.png`/`Rocks.png`.
- `Enemies/` (fungus mobs), `Weapons/` — not needed.
