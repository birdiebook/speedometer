"""Keeps the code and the docs together.

    python tools/kolla_metod.py

Every `METOD Mn` in the code needs a heading `## Mn` in docs/METOD.md, and every
`BESLUT Bn` a heading `## Bn` in docs/BESLUT.md. Run by GitHub Actions.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROT = Path(__file__).resolve().parent.parent


def rubriker(fil: str, prefix: str) -> set[str]:
    text = (ROT / fil).read_text(encoding="utf-8")
    return set(re.findall(rf"^## ({prefix}\d+)\b", text, re.M))


def main() -> int:
    metod = rubriker("docs/METOD.md", "M")
    beslut = rubriker("docs/BESLUT.md", "B")
    fel = []
    filer = [*ROT.glob("SpeedKit/**/*.swift"), *ROT.glob("App/**/*.swift"), ROT / "project.yml"]
    for fil in sorted(filer):
        for n, rad in enumerate(fil.read_text(encoding="utf-8").splitlines(), 1):
            for ref in re.findall(r"METOD (M\d+)", rad):
                if ref not in metod:
                    fel.append(f"{fil.relative_to(ROT)}:{n}: {ref} missing in docs/METOD.md")
            for ref in re.findall(r"BESLUT (B\d+)", rad):
                if ref not in beslut:
                    fel.append(f"{fil.relative_to(ROT)}:{n}: {ref} missing in docs/BESLUT.md")
    print("\n".join(fel) if fel else f"OK ({len(metod)} methods, {len(beslut)} decisions)")
    return 1 if fel else 0


if __name__ == "__main__":
    sys.exit(main())
