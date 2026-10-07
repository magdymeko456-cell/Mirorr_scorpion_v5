#!/usr/bin/env python3
"""Fail when a localized ARB drifts from the English template."""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ARB_DIR = ROOT / "lib" / "l10n"
PLACEHOLDER = re.compile(r"\{[^}]+\}")


def main() -> int:
    template_path = ARB_DIR / "app_en.arb"
    template = json.loads(template_path.read_text(encoding="utf-8"))
    template_keys = {key for key in template if not key.startswith("@")}
    failures: list[str] = []

    for path in sorted(ARB_DIR.glob("app_*.arb")):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as error:
            failures.append(f"{path}: invalid JSON: {error}")
            continue

        locale = data.get("@@locale")
        if locale != path.stem.removeprefix("app_"):
            failures.append(f"{path}: @@locale={locale!r} does not match its filename")

        keys = {key for key in data if not key.startswith("@")}
        for key in sorted(template_keys - keys):
            failures.append(f"{path}: missing key {key}")
        for key in sorted(keys - template_keys):
            failures.append(f"{path}: unknown key {key}")
        for key in sorted(template_keys & keys):
            if not isinstance(data[key], str) or not data[key].strip():
                failures.append(f"{path}: empty or non-string value for {key}")
            elif PLACEHOLDER.findall(template[key]) != PLACEHOLDER.findall(data[key]):
                failures.append(f"{path}: placeholder mismatch for {key}")

    if failures:
        print("ARB LOCALE CHECK: FAILED")
        print("\n".join(failures))
        return 1
    print(f"ARB LOCALE CHECK: PASSED ({len(list(ARB_DIR.glob('app_*.arb')))} locales, {len(template_keys)} keys)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
