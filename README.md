# Age of Sigmar Spearhead 2v2 TTS

Tabletop Simulator mod for Spearhead 2v2.

## What's in the repo

| Path | Purpose |
| --- | --- |
| `Spearhead_2v2.base.json` | Scene template (objects, positions, meshes). Committed. |
| `scripts/*.lua` | Mod Lua source of truth. Committed. |
| `scripts/manifest.json` | Maps each `.lua` file to its TTS object GUID. |
| `tools/build.py` | Builds the playable save from base + scripts. |
| `Spearhead_2v2.json` | **Generated locally.** Not committed. |

Includes:
- Modified 2v2 board overlays and deployment/terrain zones.
- Updated scoresheet for 2v2 scoring.
- Four-player token, tactics, profile, and faction points layout.
- Simplified environment for multiple players at table.
- Custom 1D3 quick-roll button and saved D3 object.

## Quick start

```bash
python tools/build.py --deploy
```

Then load **Spearhead 2v2** in Tabletop Simulator (file: `Spearhead_2v2.json` in your Saves folder if you used `--deploy`).

Requirements: Python 3.9+ (stdlib only).

## Workflows

**Change Lua logic**

1. Edit files in `scripts/`.
2. Run `python tools/build.py --deploy`.
3. Reload the save in TTS.

**Change scene layout** (move objects, edit meshes, add pieces in TTS)

1. Edit in TTS and save as `Spearhead_2v2.json`.
2. Run `python tools/import_base.py` to update `Spearhead_2v2.base.json`.
3. Run `python tools/build.py --deploy`.
4. Commit `Spearhead_2v2.base.json` (not the generated save).

**Pull Lua from base into scripts/** (e.g. after editing in TTS script editor)

```bash
python tools/export_scripts.py
```

## Steam Workshop

https://steamcommunity.com/sharedfiles/filedetails/?id=3733181881
