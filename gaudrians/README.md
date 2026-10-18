# Animals for Ninja for an Egg

Every animal comes as two files, following the handoff:

- **`<Animal>.html`**: a three.js preview. Open it in a browser to see the animal move.
  - Island animals have two buttons: Idle and Walk (keys 1–2).
  - Guardians have four: Idle, Sleep, Chase and Walk home (keys 1–4).
  - Both have Export OBJ and Export GLB buttons.
  - It uses the same pose maths as the game, so what you see is what you get.
- **`<Animal>Script.lua`**: a self-contained Roblox script. It builds the model from smooth Parts in code, so nothing needs importing, and animates it with `BulkMoveTo`.

The `repo-upload/src/...` folder has the same scripts named and placed for the repo, ready to commit.

Folders are grouped by island: Forest, Beach, CherryBlossom, Snow, Desert, Jungle, Volcano, Candy-Sky.

## Island animals (41)

**Script type:** LocalScript.
**Where in Studio:** StarterPlayer › StarterPlayerScripts › Client › Animals. Make the `Animals` Folder if it isn't there yet.
**Repo copy:** `repo-upload/src/client/Animals/<Animal>.client.luau`

They wander around and stop now and then. They don't sleep or chase.

They run on each player's own client because they're only for looks. With 41 animals moving every frame, running them on the server would lag the game and the network.

**Setup**
1. Put a Part named `<Animal>Spawn` on the island, e.g. `FoxSpawn`. Set it to Anchored, CanCollide off and Transparency 1. You can place several.
2. Optionally, add attributes to each spawn part:
   - `Count` (number, default 2): how many of that animal spawn there.
   - `Radius` (number, default 30): how far they wander from the part, in studs.
3. **Swimmers** (Koi, Dolphin): put their spawn part on the water surface. They stay at that height.
4. **Fliers** (Butterfly, Fire Bat): they float a few studs above the ground.

## Guardians (5): Yeti, Cobra, Gorilla, Dragon, Pegasus

**Script type:** Script.
**Where in Studio:** ServerScriptService › Server › Guardians, next to `GuardianBrain`.
**Repo copy:** `repo-upload/src/server/Guardians/` as `SnowYeti`, `DesertCobra`, `JungleGorilla`, `VolcanoDragon` and `SkyPegasus` `.server.luau`.

Each guardian sleeps on its pad. When someone takes an egg from its island, it chases them and flings them off. Then it carries the egg back and goes back to sleep. This is the same `GuardianBrain` behaviour as the Chicken, Frog and Crab.

**Setup:** its pad is a Part named `YetiSpawn`, `CobraSpawn`, `GorillaSpawn`, `DragonSpawn` or `PegasusSpawn`, in that island's Guardian folder. Speed, leash and catch distance are in `CFG` at the top of each script.

## Changing the look

Edit the `SPEC` table near the top of a script:
- `C` holds the colours.
- `Parts` holds the boxes, written as `{ joint, colour, w, h, d, x, y, z, rx, ry, rz }`.
  - `m = true` mirrors a part to the other side.
  - `r = 0.3` gives a part softer, rounded edges.
- `Scale` is the size in studs.

If you change a script's `SPEC`, the matching `.html` preview won't update by itself. Ask me to regenerate it.
