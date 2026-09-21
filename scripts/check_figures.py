#!/usr/bin/env python3
"""Report figures a deck references but lacks, and files in figs/ no deck uses.

Usage:  python3 scripts/check_figures.py [deck-folder ...]
With no argument every deck is checked. Exit code 1 if any referenced figure is
missing (a case-exact check, so a Linux clone builds too), 0 otherwise. Unused
files are listed but do not fail the check: R scripts, data, and the LaTeX
tables that scripts write are expected to sit in figs/ unreferenced.
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
DECKS = ["01-panel", "02-did", "03-fdid", "04-twfe", "05-modern", "06-synth"]
INCLUDE_RE = re.compile(r"\\includegraphics\*?\s*(?:\[[^\]]*\])?\s*\{([^}]*)\}")
INPUT_RE = re.compile(r"\\input\s*\{(figs/[^}]*)\}")
IMG_EXTS = (".pdf", ".png", ".jpg", ".jpeg", ".eps")
KEEP_EXTS = (".R", ".r", ".tex", ".dta", ".csv", ".rds", ".md")


def strip_comments(text: str) -> str:
    out = []
    for line in text.splitlines():
        i = 0
        while True:
            j = line.find("%", i)
            if j < 0:
                break
            k, n = j - 1, 0
            while k >= 0 and line[k] == "\\":
                n += 1
                k -= 1
            if n % 2 == 1:
                i = j + 1
                continue
            line = line[:j]
            break
        out.append(line)
    return "\n".join(out)


def exists_exact(path: Path) -> bool:
    return path.exists() and path.name in os.listdir(path.parent)


def check(deck: str) -> tuple[list[str], list[str]]:
    folder = REPO / deck
    stem = deck.split("-", 1)[1]
    texts = [strip_comments((folder / f"{stem}.tex").read_text(errors="replace"))]
    if (folder / "preamble.tex").exists():
        texts.append(strip_comments((folder / "preamble.tex").read_text(errors="replace")))
    text = "\n".join(texts)
    refs = {r.strip() for r in INCLUDE_RE.findall(text)}
    refs |= {r.strip()[5:] for r in INPUT_RE.findall(text)}
    figs = folder / "figs"
    missing = []
    used_paths = set()
    for r in sorted(refs):
        cands = [r] if Path(r).suffix else [r + e for e in IMG_EXTS]
        hit = next((figs / c for c in cands if exists_exact(figs / c)), None)
        if hit is None:
            missing.append(r)
        else:
            used_paths.add(hit.resolve())
    unused = []
    for p in sorted(figs.rglob("*")):
        if p.is_file() and p.resolve() not in used_paths and p.suffix in IMG_EXTS:
            unused.append(str(p.relative_to(figs)))
    return missing, unused


def main() -> int:
    decks = sys.argv[1:] or DECKS
    bad = False
    for d in decks:
        missing, unused = check(d)
        print(f"{d}: {'MISSING ' + str(missing) if missing else 'all referenced figures present'}"
              + (f"; unused image files: {unused}" if unused else ""))
        bad = bad or bool(missing)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
