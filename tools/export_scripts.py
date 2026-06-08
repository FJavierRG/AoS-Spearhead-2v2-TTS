#!/usr/bin/env python3
"""Extract managed Lua scripts from a save JSON into scripts/*.lua."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from save_config import BASE_SAVE, SAVE_STEM

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SOURCE = BASE_SAVE
DEFAULT_MANIFEST = REPO_ROOT / "scripts" / "manifest.json"
DEFAULT_SCRIPTS_DIR = REPO_ROOT / "scripts"


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def find_object_by_guid(objects: list[dict], guid: str) -> dict | None:
    for obj in objects:
        if obj.get("GUID") == guid:
            return obj
        for key in ("ContainedObjects", "ChildObjects"):
            found = find_object_by_guid(obj.get(key) or [], guid)
            if found is not None:
                return found
    return None


def read_embedded_script(data: dict, guid: str) -> str | None:
    if guid == "global":
        return data.get("LuaScript")

    obj = find_object_by_guid(data.get("ObjectStates") or [], guid)
    if obj is None:
        return None
    return obj.get("LuaScript")


def normalize_newlines(text: str) -> str:
    return text.replace("\r\n", "\n").replace("\r", "\n")


def write_lua_export(path: Path, guid: str, object_name: str, script: str) -> None:
    body = normalize_newlines(script).rstrip("\n") + "\n"
    header = (
        f"-- Exported from {SAVE_STEM}.base.json for review only.\n"
        f"-- TTS object: {object_name}\n"
        f"-- GUID: {guid}\n"
        f"-- Source of truth: edit this file, then run `python tools/build.py`\n"
        f"\n"
    )
    path.write_text(header + body, encoding="utf-8", newline="\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="Export embedded Lua scripts into scripts/*.lua.")
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE, help="Save JSON to read from")
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST, help="Script manifest")
    parser.add_argument("--scripts-dir", type=Path, default=DEFAULT_SCRIPTS_DIR, help="Output directory")
    args = parser.parse_args()

    if not args.source.is_file():
        print(f"error: source save not found: {args.source}", file=sys.stderr)
        return 1
    if not args.manifest.is_file():
        print(f"error: manifest not found: {args.manifest}", file=sys.stderr)
        return 1

    data = load_json(args.source)
    manifest = load_json(args.manifest)

    print(f"source: {args.source}")

    for entry in manifest.get("scripts", []):
        guid = entry["guid"]
        file_name = entry["file"]
        object_name = entry.get("object", guid)
        script = read_embedded_script(data, guid)

        if script is None:
            print(f"error: GUID not found in source save: {guid}", file=sys.stderr)
            return 1

        output_path = args.scripts_dir / file_name
        write_lua_export(output_path, guid, object_name, script)
        print(f"  exported {file_name} ({len(script)} bytes embedded)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
