#!/usr/bin/env python3
"""Add optionRectangle / optionRoundedRectangle keys to all ARB files.
Idempotent."""
import json
import pathlib

NEW = {
    "ko": {"optionRectangle": "직사각형", "optionRoundedRectangle": "라운드 사각형"},
    "en": {"optionRectangle": "Rectangle", "optionRoundedRectangle": "Rounded Rect"},
    "ja": {"optionRectangle": "長方形", "optionRoundedRectangle": "角丸長方形"},
    "zh": {"optionRectangle": "矩形", "optionRoundedRectangle": "圆角矩形"},
    "es": {"optionRectangle": "Rectángulo", "optionRoundedRectangle": "Rect. redond."},
    "fr": {"optionRectangle": "Rectangle", "optionRoundedRectangle": "Rect. arrondi"},
    "de": {"optionRectangle": "Rechteck", "optionRoundedRectangle": "Abger. Rechteck"},
    "pt": {"optionRectangle": "Retângulo", "optionRoundedRectangle": "Ret. arredond."},
    "vi": {"optionRectangle": "Hình chữ nhật", "optionRoundedRectangle": "HCN bo tròn"},
    "th": {"optionRectangle": "สี่เหลี่ยมผืนผ้า", "optionRoundedRectangle": "สี่เหลี่ยมมน"},
}


def main():
    root = pathlib.Path(__file__).resolve().parent.parent / "lib" / "l10n"
    for locale, keys in NEW.items():
        path = root / f"app_{locale}.arb"
        if not path.exists():
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        changed = False
        for k, v in keys.items():
            if k not in data:
                data[k] = v
                changed = True
        if changed:
            path.write_text(
                json.dumps(data, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            print(f"updated: {path.name}")
        else:
            print(f"no change: {path.name}")


if __name__ == "__main__":
    main()
