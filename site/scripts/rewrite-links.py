#!/usr/bin/env python3
"""Rewrite Markdown links in an imported doc (reads stdin, writes stdout).

Rules (DOCS_SRC env points at the repo docs/ folder):
  - ../PATH (escapes docs/)        -> GitHub blob URL
  - (X.md) / (./X.md) / (docs/X.md):
        target doc exists in DOCS_SRC -> X.html   (resolves between site pages)
        target doc missing           -> GitHub blob URL (never an on-site 404)
  - http(s):, mailto:, #anchor      -> left unchanged
A trailing #anchor is preserved in all cases.
"""
import os
import re
import sys

DOCS = os.environ.get("DOCS_SRC", "docs")
BLOB = "https://github.com/olafkfreund/nixos-template/blob/main"
LINK = re.compile(r"\]\(([^)\s]+)\)")


def rewrite(target: str) -> str:
    frag = ""
    if "#" in target:
        target, frag = target.split("#", 1)
        frag = "#" + frag

    if target.startswith(("http://", "https://", "mailto:", "/")) or target == "":
        return f"]({target}{frag})"

    # Links that escape the docs/ folder -> point at the repo source.
    if target.startswith("../"):
        return f"]({BLOB}/{target.lstrip('./')}{frag})"

    if target.endswith(".md"):
        name = target[3:] if target.startswith("./") else target
        name = name[5:] if name.startswith("docs/") else name
        base = os.path.basename(name)
        if os.path.isfile(os.path.join(DOCS, base)):
            return f"]({base[:-3]}.html{frag})"
        # Unknown doc: send readers to the repo instead of a dead site page.
        return f"]({BLOB}/docs/{base}{frag})"

    return f"]({target}{frag})"


sys.stdout.write(LINK.sub(lambda m: rewrite(m.group(1)), sys.stdin.read()))
