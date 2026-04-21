#!/usr/bin/env python3
"""Replace labelLogoBackgroundBorder with labelLogoBackgroundColor in ARB files,
and add actionLogoBackgroundReset + hintLogoBackgroundColorDisabled, and remove
the old border-specific keys if present. Idempotent.
"""
import json
import pathlib

# new key translations
NEW = {
    "ko": {
        "labelLogoBackgroundColor": "배경 색상",
        "actionLogoBackgroundReset": "기본값",
        "hintLogoBackgroundColorDisabled": "배경을 선택하면 활성화됩니다",
    },
    "en": {
        "labelLogoBackgroundColor": "Background Color",
        "actionLogoBackgroundReset": "Default",
        "hintLogoBackgroundColorDisabled": "Select a background to enable",
    },
    "ja": {
        "labelLogoBackgroundColor": "背景の色",
        "actionLogoBackgroundReset": "デフォルト",
        "hintLogoBackgroundColorDisabled": "背景を選択すると有効になります",
    },
    "zh": {
        "labelLogoBackgroundColor": "背景颜色",
        "actionLogoBackgroundReset": "默认",
        "hintLogoBackgroundColorDisabled": "选择背景以启用",
    },
    "es": {
        "labelLogoBackgroundColor": "Color de fondo",
        "actionLogoBackgroundReset": "Predeterminado",
        "hintLogoBackgroundColorDisabled": "Seleccione un fondo para habilitar",
    },
    "fr": {
        "labelLogoBackgroundColor": "Couleur de fond",
        "actionLogoBackgroundReset": "Défaut",
        "hintLogoBackgroundColorDisabled": "Sélectionnez un fond pour activer",
    },
    "de": {
        "labelLogoBackgroundColor": "Hintergrundfarbe",
        "actionLogoBackgroundReset": "Standard",
        "hintLogoBackgroundColorDisabled": "Hintergrund auswählen zum Aktivieren",
    },
    "pt": {
        "labelLogoBackgroundColor": "Cor do fundo",
        "actionLogoBackgroundReset": "Padrão",
        "hintLogoBackgroundColorDisabled": "Selecione um fundo para ativar",
    },
    "vi": {
        "labelLogoBackgroundColor": "Màu nền",
        "actionLogoBackgroundReset": "Mặc định",
        "hintLogoBackgroundColorDisabled": "Chọn nền để kích hoạt",
    },
    "th": {
        "labelLogoBackgroundColor": "สีพื้นหลัง",
        "actionLogoBackgroundReset": "ค่าเริ่มต้น",
        "hintLogoBackgroundColorDisabled": "เลือกพื้นหลังเพื่อเปิดใช้งาน",
    },
}

# old keys to remove (since they represented the border feature that was reinterpreted)
OLD_KEYS = [
    "labelLogoBackgroundBorder",
    "actionLogoBorderNone",
    "hintLogoBackgroundBorderDisabled",
]


def main():
    root = pathlib.Path(__file__).resolve().parent.parent / "lib" / "l10n"
    for locale, keys in NEW.items():
        arb_path = root / f"app_{locale}.arb"
        if not arb_path.exists():
            print(f"skip (missing): {arb_path}")
            continue
        data = json.loads(arb_path.read_text(encoding="utf-8"))
        changed = False
        # remove old keys
        for k in OLD_KEYS:
            if k in data:
                del data[k]
                changed = True
        # add new keys (if not present)
        for k, v in keys.items():
            if k not in data:
                data[k] = v
                changed = True
        if changed:
            arb_path.write_text(
                json.dumps(data, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            print(f"updated: {arb_path.name}")
        else:
            print(f"no change: {arb_path.name}")


if __name__ == "__main__":
    main()
