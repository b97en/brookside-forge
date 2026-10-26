# Playtest guide

## Running the build

Open the project in Godot 4.6 and press F5, or run `godot --path .` from the
repo root.

To start from a clean slate, delete the save file first:

- Windows: `%APPDATA%\Godot\app_userdata\Brookside Forge POC\save.json`
- Linux: `~/.local/share/godot/app_userdata/Brookside Forge POC/save.json`

A fresh start shows a one-line controls hint at the bottom of the screen.

## The loop under test

1. Walk to the **notice board** (left of the crossroads), press **E** — a
   commission appears top-right, including what it needs (e.g. "2 Iron Ore").
2. Walk **east** past the farmer to the **ore rock**, press **E** — the smith
   swings at the rock and "+1 Iron Ore" floats up. Repeat until you have enough.
3. Walk up the path into the **forge** (E at the door), then **E at the anvil**.
   The anvil tells you what's missing if you're short.
4. The hammer mini-game: press **SPACE** when the marker crosses the glowing
   centre. Four strikes, counted in the panel; the marker runs in from
   alternating sides. Quality shows at the end.
5. Leave, deliver to the **farmer** on the road (E) — gold, thank-you line.
6. Back to the board: it posts the **next** job (scythe → horseshoes → gate
   hinges, then round again). Each needs a different amount of ore and pays
   differently.
7. Quit and reopen: gold, inventory and which jobs are done should persist.

## What to watch for (don't explain the game first!)

- Do they find the notice board and understand E-prompts unaided?
- **Did they smile during the mini-game?** (the POC's success metric)
- **Did they forge a second item without being asked?** The board always has
  a next job, so watch whether they go back to it on their own.
- Where did they get lost or stop — that's the next thing to fix.

## Tuning after a session

- Movement speed is `SPEED` in `scenes/player.gd`. Mini-game strike count,
  speed and timing windows are exports on the ForgeMinigame node.
- Commission text, rewards and ore costs live in `data/commissions.json` and
  `data/items.json`, so no code changes are needed.
- Only the most recent forged item's quality is tracked. There's one commission
  at a time, so this never matters in play.

Known art and audio gaps are listed in [TODO.md](TODO.md).
