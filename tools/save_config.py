"""Shared save file names for the Spearhead 2v2 mod."""

from pathlib import Path

SAVE_STEM = "Spearhead_2v2"
REPO_ROOT = Path(__file__).resolve().parent.parent
BASE_SAVE = REPO_ROOT / f"{SAVE_STEM}.base.json"
BUILT_SAVE = REPO_ROOT / f"{SAVE_STEM}.json"
TTS_SAVE = (
    Path.home() / "Documents" / "My Games" / "Tabletop Simulator" / "Saves" / f"{SAVE_STEM}.json"
)
