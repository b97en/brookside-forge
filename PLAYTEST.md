# Playtest guide

## Running the build

Open the project in Godot 4.6 and press F5, or from a terminal:

```
godot --path .
```

(Your Godot is at `Downloads\Godot_v4.6.3-stable_win64.exe\`.)

To start from a clean slate, delete the save first:
`%APPDATA%\Godot\app_userdata\Brookside Forge POC\save.json`.
On a fresh start a one-line controls hint appears at the bottom of the screen.

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
- **Did they forge a second item without being asked?** The board now gives
  them a reason to — watch whether they go back to it on their own.
- Where did they get lost or stop — that's the next thing to fix.

## Known soft spots

- Movement speed, mini-game speed/windows are all tunable
  (`scenes/player.gd` SPEED; ForgeMinigame exports in the inspector).
- Commission text, rewards and ore costs live in `data/commissions.json` and
  `data/items.json` — tune pay/cost there, no code changes needed.
- Forged quality is tracked for the most recent item only (one commission at a
  time, so it never matters in play).
- Notice board is placeholder art (see TODO.md).
