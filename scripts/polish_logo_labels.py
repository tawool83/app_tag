#!/usr/bin/env python3
"""Polish logo-tab ARB keys:
- optionRectangle: '직사각형' → '사각'
- optionRoundedRectangle: '라운드 사각형' → '원형'
- labelLogoBackgroundColor: '배경 색상' → '색상'
- Remove hintLogoBackgroundColorDisabled
"""
import json
import pathlib

UPDATES = {
    "ko": {"optionRectangle": "사각", "optionRoundedRectangle": "원형",
           "labelLogoBackgroundColor": "색상"},
    "en": {"optionRectangle": "Square", "optionRoundedRectangle": "Circle",
           "labelLogoBackgroundColor": "Color"},
    "ja": {"optionRectangle": "四角", "optionRoundedRectangle": "丸",
           "labelLogoBackgroundColor": "色"},
    "zh": {"optionRectangle": "方形", "optionRoundedRectangle": "圆形",
           "labelLogoBackgroundColor": "颜色"},
    "es": {"optionRectangle": "Cuadrado", "optionRoundedRectangle": "Círculo",
           "labelLogoBackgroundColor": "Color"},
    "fr": {"optionRectangle": "Carré", "optionRoundedRectangle": "Cercle",
           "labelLogoBackgroundColor": "Couleur"},
    "de": {"optionRectangle": "Quadrat", "optionRoundedRectangle": "Kreis",
           "labelLogoBackgroundColor": "Farbe"},
    "pt": {"optionRectangle": "Quadrado", "optionRoundedRectangle": "Círculo",
           "labelLogoBackgroundColor": "Cor"},
    "vi": {"optionRectangle": "Vuông", "optionRoundedRectangle": "Tròn",
           "labelLogoBackgroundColor": "Màu"},
    "th": {"optionRectangle": "สี่เหลี่ยม", "optionRoundedRectangle": "วงกลม",
           "labelLogoBackgroundColor": "สี"},
}

REMOVE = ["hintLogoBackgroundColorDisabled"]


def main():
    root = pathlib.Path(__file__).resolve().parent.parent / "lib" / "l10n"
    for locale, updates in UPDATES.items():
        path = root / f"app_{locale}.arb"
        if not path.exists():
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        changed = False
        for k, v in updates.items():
            if data.get(k) != v:
                data[k] = v
                changed = True
        for k in REMOVE:
            if k in data:
                del data[k]
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
