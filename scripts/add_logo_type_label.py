#!/usr/bin/env python3
"""Add labelLogoType key to all ARB files. Idempotent."""
import json
import pathlib

NEW = {
    "ko": "유형",
    "en": "Type",
    "ja": "種類",
    "zh": "类型",
    "es": "Tipo",
    "fr": "Type",
    "de": "Typ",
    "pt": "Tipo",
    "vi": "Loại",
    "th": "ประเภท",
}

def main():
    root = pathlib.Path(__file__).resolve().parent.parent / "lib" / "l10n"
    for locale, value in NEW.items():
        path = root / f"app_{locale}.arb"
        if not path.exists():
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        if data.get("labelLogoType") != value:
            data["labelLogoType"] = value
            path.write_text(
                json.dumps(data, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            print(f"updated: {path.name}")
        else:
            print(f"no change: {path.name}")


if __name__ == "__main__":
    main()
