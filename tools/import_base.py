#!/usr/bin/env python3
"""Replace the base save from a TTS save export."""

from __future__ import annotations

import argparse
import shutil
import sys
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from save_config import BASE_SAVE, TTS_SAVE

DEFAULT_BASE = BASE_SAVE
DEFAULT_SOURCE = TTS_SAVE


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Update the base save from a save exported by Tabletop Simulator."
    )
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE, help="Source save JSON")
    parser.add_argument("--base", type=Path, default=DEFAULT_BASE, help="Base save to overwrite")
    parser.add_argument("--no-backup", action="store_true", help="Skip backup of the current base save")
    args = parser.parse_args()

    if not args.source.is_file():
        print(f"error: source save not found: {args.source}", file=sys.stderr)
        return 1

    if args.base.exists() and not args.no_backup:
        stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = args.base.with_name(f"{args.base.stem}.backup_{stamp}{args.base.suffix}")
        shutil.copy2(args.base, backup_path)
        print(f"backup: {backup_path}")

    shutil.copy2(args.source, args.base)
    print(f"updated base: {args.base} ({args.base.stat().st_size} bytes)")
    print("next step: python tools/build.py")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
