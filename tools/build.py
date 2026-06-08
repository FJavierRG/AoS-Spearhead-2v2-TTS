#!/usr/bin/env python3
"""Inject scripts/*.lua into the base save and write the playable mod save."""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from datetime import datetime
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))

from save_config import BASE_SAVE, BUILT_SAVE, TTS_SAVE
DEFAULT_BASE = BASE_SAVE
DEFAULT_OUTPUT = BUILT_SAVE
DEFAULT_MANIFEST = REPO_ROOT / "scripts" / "manifest.json"
DEFAULT_SCRIPTS_DIR = REPO_ROOT / "scripts"
DEFAULT_TTS_SAVE = TTS_SAVE

EXPORT_HEADER_LINES = 5


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def save_json(path: Path, data: dict) -> None:
    with path.open("w", encoding="utf-8") as handle:
        json.dump(data, handle, ensure_ascii=False, separators=(",", ":"))


def read_lua_body(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines(keepends=True)

    if lines and lines[0].startswith("-- Exported from"):
        lines = lines[EXPORT_HEADER_LINES:]

    body = "".join(lines)
    return body.replace("\r\n", "\n").replace("\n", "\r\n")


def find_object_by_guid(objects: list[dict], guid: str) -> dict | None:
    for obj in objects:
        if obj.get("GUID") == guid:
            return obj
        for key in ("ContainedObjects", "ChildObjects"):
            found = find_object_by_guid(obj.get(key) or [], guid)
            if found is not None:
                return found
    return None


def inject_script(data: dict, guid: str, script: str) -> bool:
    if guid == "global":
        data["LuaScript"] = script
        return True

    obj = find_object_by_guid(data.get("ObjectStates") or [], guid)
    if obj is None:
        return False

    obj["LuaScript"] = script
    return True


def deploy_save(output: Path, destination: Path, backup: bool) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    if backup and destination.exists():
        stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = destination.with_name(f"{destination.stem}.backup_{stamp}{destination.suffix}")
        shutil.copy2(destination, backup_path)
        print(f"backup: {backup_path}")
    shutil.copy2(output, destination)
    print(f"deployed: {destination}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Build TS_Save_4.json from base save + Lua scripts.")
    parser.add_argument("--base", type=Path, default=DEFAULT_BASE, help="Base save JSON (scene template)")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="Generated save JSON")
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST, help="Script manifest")
    parser.add_argument("--scripts-dir", type=Path, default=DEFAULT_SCRIPTS_DIR, help="Directory with .lua files")
    parser.add_argument("--deploy", action="store_true", help="Copy output to the local TTS Saves folder")
    parser.add_argument("--deploy-to", type=Path, default=DEFAULT_TTS_SAVE, help="Destination path for --deploy")
    parser.add_argument("--no-backup", action="store_true", help="Skip backup when deploying")
    args = parser.parse_args()

    if not args.base.is_file():
        print(f"error: base save not found: {args.base}", file=sys.stderr)
        return 1
    if not args.manifest.is_file():
        print(f"error: manifest not found: {args.manifest}", file=sys.stderr)
        return 1

    manifest = load_json(args.manifest)
    data = load_json(args.base)

    print(f"base:   {args.base}")
    print(f"output: {args.output}")

    for entry in manifest.get("scripts", []):
        file_name = entry["file"]
        guid = entry["guid"]
        script_path = args.scripts_dir / file_name

        if not script_path.is_file():
            print(f"error: missing script file: {script_path}", file=sys.stderr)
            return 1

        body = read_lua_body(script_path)
        if not inject_script(data, guid, body):
            print(f"error: GUID not found in base save: {guid} ({file_name})", file=sys.stderr)
            return 1

        print(f"  injected {file_name} -> {guid} ({len(body)} bytes)")

    save_json(args.output, data)
    print(f"built: {args.output} ({args.output.stat().st_size} bytes)")

    if args.deploy:
        deploy_save(args.output, args.deploy_to, backup=not args.no_backup)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
