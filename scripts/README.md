# Lua Scripts

These files are the **source of truth** for mod Lua logic. Tabletop Simulator does not load them directly.

## Build workflow

```bash
python tools/build.py
```

This reads `Spearhead_2v2.base.json` (scene template) and injects every script listed in `manifest.json`, producing `Spearhead_2v2.json`.

To also copy the result into your local TTS Saves folder:

```bash
python tools/build.py --deploy
```

## Other commands

Import a save exported from TTS back into the base template (positions, meshes, new objects):

```bash
python tools/import_base.py
python tools/build.py
```

Pull embedded Lua from the base save into these files (reverse sync):

```bash
python tools/export_scripts.py
```

## Managed scripts

| File | TTS object | GUID |
| --- | --- | --- |
| `global.lua` | Global | `global` |
| `spearhead_scoresheet_814d2d.lua` | Spearhead Scoresheet | `814d2d` |
| `aura_indicator_7cdc5a.lua` | Aura Indicator | `7cdc5a` |
| `auto_player_promoter_533765.lua` | Auto Player Promoter | `533765` |
| `blue_dice_roller_4e0e0b.lua` | Blue Kustom 40k Dice Roller Mk3 | `4e0e0b` |
| `blue_dice_table_a84ed2.lua` | Blue Dice Table | `a84ed2` |
| `red_dice_roller_beae28.lua` | Red Kustom 40k Dice Roller Mk3 | `beae28` |
| `red_dice_table_c57d70.lua` | Red Dice Table | `c57d70` |
| `bubble_position_helper_86398e.lua` | Bubble & Position Helper | `86398e` |
| `injection_detector_5c328f.lua` | Injection Detector | `5c328f` |

Other Lua embedded in the save (overlay buttons, workshop tokens, etc.) stays in `Spearhead_2v2.base.json` only.
