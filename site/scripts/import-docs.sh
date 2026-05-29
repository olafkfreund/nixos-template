#!/usr/bin/env bash
# Import every Markdown file from the repository docs/ folder into the Jekyll
# site as a styled page. Runs at build time (in CI) so docs/ stays the single
# source of truth — generated pages are NOT committed.
#
# Usage: site/scripts/import-docs.sh <src-docs-dir> <dest-dir>
#   e.g. site/scripts/import-docs.sh docs site/docs
#
# For each docs/NAME.md it writes dest/NAME.md with:
#   - Jekyll front matter (layout: page, title from the first H1, stable permalink)
#   - the body wrapped in {% raw %}..{% endraw %} so literal Liquid-looking text
#     (e.g. GitHub Actions ${{ ... }} expressions) is never interpreted
#   - intra-doc links rewritten from *.md to *.html so they resolve between pages

set -euo pipefail

SRC="${1:-docs}"
DEST="${2:-site/docs}"

if [ ! -d "$SRC" ]; then
  echo "import-docs: source dir '$SRC' not found" >&2
  exit 1
fi

mkdir -p "$DEST"
count=0

for f in "$SRC"/*.md; do
  [ -e "$f" ] || continue
  base="$(basename "$f" .md)"

  # Skip the docs index itself — the site has its own /documentation/ listing.
  if [ "$base" = "README" ]; then
    continue
  fi

  # Title: first level-1 heading, else the file name.
  title="$(grep -m1 '^# ' "$f" 2>/dev/null | sed 's/^# *//' | tr -d '"' || true)"
  if [ -z "$title" ]; then
    title="$base"
  fi

  out="$DEST/$base.md"
  {
    printf -- '---\n'
    printf 'layout: page\n'
    printf 'title: "%s"\n' "$title"
    printf 'permalink: /docs/%s.html\n' "$base"
    printf -- '---\n'
    printf '{%% raw %%}\n'
    # Drop the first H1 (the layout already renders the title), then rewrite links:
    #  - ../PATH (escapes docs/) -> GitHub blob URL so it still resolves
    #  - between docs: (X.md) / (./X.md) / (docs/X.md) -> (X.html); keep #anchor
    awk 'BEGIN{dropped=0} /^# /&&!dropped{dropped=1;next} {print}' "$f" | sed -E \
      -e 's@\]\(\.\./([A-Za-z0-9._/-]+)\)@](https://github.com/olafkfreund/nixos-template/blob/main/\1)@g' \
      -e 's@\]\(\./([A-Za-z0-9._-]+)\.md(#[^)]*)?\)@](\1.html\2)@g' \
      -e 's@\]\(docs/([A-Za-z0-9._-]+)\.md(#[^)]*)?\)@](\1.html\2)@g' \
      -e 's@\]\(([A-Za-z0-9._-]+)\.md(#[^)]*)?\)@](\1.html\2)@g'
    printf '\n{%% endraw %%}\n'
  } > "$out"

  count=$((count + 1))
done

echo "import-docs: generated $count doc page(s) in $DEST"
