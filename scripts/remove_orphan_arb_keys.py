#!/usr/bin/env python3
"""Remove orphan ARB keys from all locales. Idempotent."""
import json
import pathlib

ORPHAN_KEYS = [
    "labelLogoTabShow",  # Removed after Act-5 (Switch 제거)
]


def main():
    root = pathlib.Path(__file__).resolve().parent.parent / "lib" / "l10n"
    for path in sorted(root.glob("app_*.arb")):
        data = json.loads(path.read_text(encoding="utf-8"))
        removed = [k for k in ORPHAN_KEYS if k in data]
        if not removed:
            print(f"no change: {path.name}")
            continue
        for k in removed:
            del data[k]
        path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"updated: {path.name} (removed {removed})")


if __name__ == "__main__":
    main()
