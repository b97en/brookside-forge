# Brookside Forge POC — Session Plan

Ten Claude Code sessions over roughly two weeks. Each session is one sitting
(60–120 min of your time), ends with a working build and a git commit. If a
session overruns, stop and split it — don't push into untested territory.

**Model discipline:** default to Sonnet or Opus (`/model`) for implementation.
Switch to Fable 5 only where marked ★ — architecture decisions and genuinely
stuck debugging. Fable 5 draws down your allowance at roughly double the rate,
and most of this plan is bread-and-butter 2D work.

**Your role each session:** run the scene in the Godot editor when Claude hands
over, report what you see (or paste the error), and read the explanation Claude
gives at the end. If you can't explain how the session's system works in two
sentences, ask before moving on.

---

## Session 0 — Setup (you, mostly — ~1 hour, minimal Claude)

- Install Godot 4.x, create the project at 640×360 with viewport stretch,
  integer scaling, nearest-neighbour texture filtering.
- `git init`, add `.gitignore` for Godot. **Make the repo private**, or
  gitignore `assets/packs/` — your Pixel Crawler licence won't permit
  redistributing the raw assets publicly.
- Unpack the Pixel Crawler packs you'll actually use into `assets/packs/`
  (likely: base/free pack for characters and village, Forge, Mines/Caves).
  Leave the rest out — every imported sprite sheet slows the editor and
  tempts scope creep.
- Write a short `assets/packs/README.md`: tile size (16×16), character sheet
  frame dimensions, and where key sprites live. Ten minutes of your time that
  saves Claude guessing sheet layouts in every later session.
- Place `CLAUDE.md` in the repo root.

*Why you do this one manually: project creation is point-and-click in the
editor, and skimming your own asset library is how you find out what you
actually own — which directly shapes Sessions 2, 4, and 9.*

## Session 1 — Player movement

- Player scene: AnimatedSprite2D from the asset pack, CollisionShape2D,
  4-direction movement with idle/walk animations.
- Input map (WASD + arrows), camera follows player.
- **Done when:** character walks around an empty scene, animations match
  direction, movement feels right at ~80 px/s (tune to taste).

## Session 2 — Village tilemap

- Build `village.tscn` with TileMapLayers from the asset pack: ground, paths,
  a forge building exterior, collision on obstacles.
- Keep it small — a single screen and a half. Mood over square footage.
- **Done when:** you can walk a village that already *looks* like Brookside,
  and can't walk through walls.
- **Checkpoint:** Pixel Crawler leans fantasy-dungeon. Look at the finished
  village and judge honestly — does it read "melancholy post-war Yorkshire"
  or "generic dungeon town"? Either answer is fine for the POC, but record
  the verdict: it determines whether the full game can ship on these packs
  or needs an art budget later.

## Session 3 — Interaction system ★ (design only)

- ★ Spend 10 minutes with Fable 5 agreeing the architecture: Interactable
  component (Area2D), "Press E" prompt, Events signal bus. This pattern carries
  the whole game, so get it right once.
- Then switch back to Sonnet/Opus to implement: ore node (interact → item
  appears in inventory array), forge door (interact → scene change to interior).
- **Done when:** prompts appear near objects, E does the thing, inventory
  prints to console.

## Session 4 — Forge interior + mini-game shell

- `forge_interior.tscn`: small room, anvil, forge fire, exit back to village.
- Mini-game scene skeleton: opens when interacting with the anvil (with ore in
  inventory), closes on completion, emits a `forging_complete` signal.
- **Done when:** you can enter the forge, open an empty mini-game panel, close
  it, and leave.

## Session 5 — The hammer mini-game ★

- The heart of the POC, worth your best tools and most iteration.
- v1 mechanic: a marker oscillates across a bar; press Space to strike; 3–5
  strikes per item; accuracy of strikes → poor/good/perfect quality result.
- ★ If v1 feels flat after you've actually played it, use Fable 5 to explore
  variants (heat window that decays, rhythm-based strikes, multi-stage
  draw-out/quench). Iterate on *feel*: timing windows, strike feedback.
- **Done when:** forging is something you voluntarily do twice.

## Session 6 — Commission loop

- `data/commissions.json` and `data/items.json` via DataLoader.
- Notice board (interactable): shows one active commission. Farmer NPC
  (static, one idle animation) accepts the matching item, pays gold scaled by
  quality, says one line.
- **Done when:** board → ore → forge → deliver → gold runs end to end.

## Session 7 — UI pass

- Gold counter, minimal inventory display, dialogue box for NPC lines,
  commission card UI. Use the asset pack's UI sprites or simple 9-patch panels.
- **Done when:** you never need the console to know game state.

## Session 8 — Save/load + juice

- `GameState` serialises gold/inventory/commission state to `user://save.json`;
  load on launch.
- Juice: forge spark particles (CPUParticles2D), hammer-strike sound, ambient
  forge crackle, screen shake on perfect strikes. Free SFX: freesound.org,
  Kenney audio packs (check licences).
- **Done when:** quit/reopen keeps your gold, and striking the anvil is
  *satisfying*.

## Session 9 — Custom art (the earned one)

- First, audit: the Pixel Crawler Forge pack likely already covers the anvil,
  fire, and tools. If it does, this session shrinks or vanishes — that's a win,
  not a loss.
- Custom work only for genuine gaps: most likely the forged *items* themselves
  (a Yorkshire scythe, a katana-influenced blade — the East-meets-West objects
  no fantasy pack will have) and any quintessentially-Yorkshire touches.
  Aseprite by hand, or Pixel Lab matched to the Pixel Crawler palette — either
  is fine at this scale.
- Strict timebox: one session. If it's not done, the pack placeholder ships
  in the POC.
- **Done when:** the items you forge look like *your* game's items.

## Session 10 — Playtest build

- Fix anything broken, then put the build in front of 2–3 people (your GDD's
  own success metric). Watch them play the loop without explaining anything.
- The POC question to answer: did they smile during the mini-game, and did
  they forge a second item without being asked?

---

## Budget guardrails

- Run `/usage` at the start of each session; if a session burns unusually fast,
  check whether you've drifted onto Fable 5 for routine work.
- Expect Sessions 3 and 5 to be the expensive ones. That's correct — they're
  where the design risk lives.
- If you exhaust the month's allowance before Session 10, the remaining
  sessions (7–10) are the most Godot-learnable ones — finishing them yourself
  with Pro-level usage is a feature, not a failure.
