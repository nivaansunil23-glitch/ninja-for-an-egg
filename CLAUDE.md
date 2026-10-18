# Ninja for an egg — Claude Code project

**Before doing anything, read the hand-off note:** `C:\claude\ninja-vault\hand off.md`
It is the source of truth for what's done, in progress and next. Update it after every change.

Other vault notes (read the ones that matter for the task): `C:\claude\ninja-vault\`
- Stuff we need to do, Egg Systems, Jump Balance, Map Layout, Player and Shops Code,
  Reference Games, Tools Setup, and the `Looks` folder (low poly style, GUI style, island themes).

## This repo
- Roblox egg-collecting game: floating low poly islands, jump upgrades, eggs, pens, shops,
  parkour clouds, guardian animals. Collaborator: Kichu (Team Create).
- GitHub: https://github.com/nivaansunil23-glitch/ninja-for-an-egg (main)
- `src/first` → ReplicatedFirst (loading screen), `src/shared` → ReplicatedStorage.Shared,
  `src/server` → ServerScriptService.Server, `src/client` → StarterPlayerScripts.Client
  (see `default.project.json`).
- `gaudrians/` guardian scripts, `places/` saved place file, `tools/` build scripts,
  `refernce videos/` reference clips.
- Not this game: the parent folder `C:\claude` is a different game (Goon Squad).

## Tools
- Roblox Studio MCP (only works while Studio is open). Rojo 7.7.1 installed but NOT serving
  (Team Create), so edit in Studio through the MCP.
- Blender for low poly models. yt-dlp + FFmpeg for video frames.

## Rules (from the hand-off note)
- git pull before working, push after.
- Everything low poly, smooth flat colors. No brick or grainy materials. No flat/square
  terrain: floating islands like Bubble Gum Sim and Ninja Legends.
- The user does ALL play-testing. Claude never play-tests.
- Work on 1 to 2 tasks at a time, keep replies short, don't over-study videos.
- No pet models, bosses or extra content unless asked.
- When giving code: say the exact script type and where it goes in Studio, give complete scripts.
- Never claim something was tested in Studio unless it actually was.
