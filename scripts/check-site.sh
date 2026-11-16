#!/usr/bin/env bash
# Checks a built site (default ./public) for the files and tags search engines and link
# previews need, that every third-party script is pinned with an integrity hash, and that
# every link in llms.txt resolves to a built page.
#   scripts/check-site.sh [PUBLIC_DIR]
set -euo pipefail

public="${1:-public}"
base="https://kubemoot.org/"
fail=0

bad() {
  echo "check-site: $*" >&2
  fail=1
}

for f in index.html 404.html robots.txt sitemap.xml llms.txt social/kubemoot.png; do
  [[ -s "$public/$f" ]] || bad "missing or empty: $f"
done

grep -q '^Sitemap: https://kubemoot.org/sitemap.xml' "$public/robots.txt" 2>/dev/null ||
  bad "robots.txt does not point at the sitemap"
if grep -o '<loc>[^<]*</loc>' "$public/sitemap.xml" 2>/dev/null | grep -qv '<loc>https://kubemoot.org/'; then
  bad "sitemap.xml has a URL outside https://kubemoot.org/"
fi

# The home page and the quickstart carry the description, share, and canonical tags.
for page in index.html docs/introduction/quickstart/index.html; do
  # Minified HTML drops attribute quotes, so each pattern allows them.
  for tag in 'name="?description"? content="?[^ >]' 'property="?og:title' 'property="?og:description' \
    'property="?og:image"? content="?https://kubemoot.org/social/kubemoot.png' 'property="?og:url' 'property="?og:type' \
    'name="?twitter:card"? content="?summary_large_image' 'rel="?canonical"? href="?https://kubemoot.org/'; do
    grep -qE -- "$tag" "$public/$page" 2>/dev/null || bad "$page lacks: $tag"
  done
done

# Third-party scripts must be pinned: an exact version in the URL and an integrity hash.
# Docsy loads jQuery and lunr this way. An unpinned URL (@latest, a
# bare package name) or a script without integrity fails.
while read -r tag; do
  [[ -n "$tag" ]] || continue
  [[ "$tag" =~ integrity=\"?sha(256|384|512)- ]] || bad "a built page loads a script without an integrity hash: $tag"
  [[ "$tag" =~ [@-][0-9]+\.[0-9]+\.[0-9]+ ]] || bad "a built page loads a script without an exact version: $tag"
done < <(find "$public" -name '*.html' -print0 | xargs -0 cat 2>/dev/null |
  tr '\n' ' ' | grep -oE '<script[^>]*src="?(https?:)?//[^" >]+[^>]*>' |
  grep -vE 'src="?(https:)?//kubemoot\.org/' | sort -u)

# Every llms.txt link maps to a built page or file.
count=0
while read -r url; do
  path="${url#"$base"}"
  path="${path%%#*}"
  if [[ -f "$public/$path" || -f "$public/${path}index.html" ]]; then
    count=$((count + 1))
  else
    bad "llms.txt links to a page that is not built: $url"
  fi
done < <(grep -o '](https://kubemoot.org/[^)]*)' "$public/llms.txt" 2>/dev/null | sed 's/^](//; s/)$//')
((count > 0)) || bad "llms.txt has no links to the site"

((fail == 0)) || exit 1
echo "check-site: ok ($count llms.txt links resolve)"
