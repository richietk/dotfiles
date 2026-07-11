#!/usr/bin/env bash
#
# find-stray-passwords.sh — pull every password out of your rbw-managed
# Bitwarden vault, then scan the home folder (same file-search approach as
# find-stray-emails.sh) for plaintext copies of those passwords sitting in
# notes, configs, old exports, etc.
#
# Requires: rbw (https://github.com/doy/rbw), logged in; jq; ripgrep (rg).
# rbw will prompt you (pinentry/terminal) for your master password if the
# vault is currently locked.
#
# Usage:
#   scripts/find-stray-passwords.sh [root-dir]
#
# Env overrides:
#   MAX_PDF_MB     max PDF size (MB) to text-extract, default 25
#   PDF_TIMEOUT    per-PDF extraction timeout (seconds), default 10
#   MAX_TEXT_SIZE  max size for plain-text files, default 200M (rg syntax)
#   MIN_PW_LEN     skip vault passwords shorter than this, default 6
#                  (short passwords/PINs produce mostly noise matches)
#   NO_SYNC        set to 1 to skip "rbw sync" before reading the vault
#   SHOW_FULL      set to 1 to print full plaintext passwords instead of
#                  masked (first+last char only)
#
# Output format:
#   PATH -> MASKED_PASSWORD  (vault entry: name1, name2)

set -uo pipefail

ROOT="${1:-$HOME}"
JOBS="$(nproc)"
MAX_PDF_MB="${MAX_PDF_MB:-25}"
MAX_PDF_BYTES=$((MAX_PDF_MB * 1024 * 1024))
PDF_TIMEOUT="${PDF_TIMEOUT:-10}"
MAX_TEXT_SIZE="${MAX_TEXT_SIZE:-200M}"
MIN_PW_LEN="${MIN_PW_LEN:-6}"
NO_SYNC="${NO_SYNC:-0}"
SHOW_FULL="${SHOW_FULL:-0}"

for bin in rbw jq rg; do
  command -v "$bin" >/dev/null 2>&1 || { echo "$bin is required but not found in PATH" >&2; exit 1; }
done

HAVE_PDFTOTEXT=0
command -v pdftotext >/dev/null 2>&1 && HAVE_PDFTOTEXT=1

# ---------------------------------------------------------------------------
# Working directory for intermediate files. These hold plaintext passwords,
# so keep them private and scrub them on exit.
# ---------------------------------------------------------------------------
WORKDIR="$(mktemp -d)"
chmod 700 "$WORKDIR"
cleanup() {
  if command -v shred >/dev/null 2>&1; then
    find "$WORKDIR" -type f -exec shred -u -- {} + 2>/dev/null
  fi
  rm -rf -- "$WORKDIR"
}
trap cleanup EXIT INT TERM

MAP_FILE="$WORKDIR/password_map.tsv"     # password<TAB>entry-name
PATTERNS_FILE="$WORKDIR/patterns.txt"    # unique passwords, one per line
RAW_ENTRIES="$WORKDIR/raw_entries.tsv"   # entry-name<TAB>password
RAW_MATCHES="$WORKDIR/raw_matches.tsv"   # path<TAB>password

# ---------------------------------------------------------------------------
# Stage 0: pull unique, non-empty passwords out of the vault via rbw.
# ---------------------------------------------------------------------------

echo "Checking rbw vault status..." >&2
if ! rbw unlocked >/dev/null 2>&1; then
  echo "Vault is locked — check for a pinentry/terminal prompt to unlock it." >&2
  rbw unlock || { echo "Failed to unlock vault" >&2; exit 1; }
fi

if [ "$NO_SYNC" -ne 1 ]; then
  echo "Syncing vault..." >&2
  rbw sync || echo "Warning: rbw sync failed, continuing with local cache" >&2
fi

echo "Reading vault entries..." >&2
mapfile -t LOGIN_IDS < <(rbw list --raw | jq -r '.[] | select(.type == "Login") | .id')

if [ "${#LOGIN_IDS[@]}" -eq 0 ]; then
  echo "No login entries found in vault." >&2
  exit 0
fi

fetch_entry() {
  local id="$1"
  rbw get --raw "$id" 2>/dev/null | jq -r '[.name, (.data.password // "")] | @tsv' 2>/dev/null
}
export -f fetch_entry

printf '%s\n' "${LOGIN_IDS[@]}" | xargs -P "$JOBS" -n 1 bash -c 'fetch_entry "$0"' > "$RAW_ENTRIES"

awk -F'\t' -v minlen="$MIN_PW_LEN" \
  'NF >= 2 && $2 != "" && length($2) >= minlen { print $2 "\t" $1 }' \
  "$RAW_ENTRIES" > "$MAP_FILE"

TOTAL_WITH_PW=$(awk -F'\t' 'NF >= 2 && $2 != ""' "$RAW_ENTRIES" | wc -l)
SKIPPED_SHORT=$((TOTAL_WITH_PW - $(wc -l < "$MAP_FILE")))

if [ ! -s "$MAP_FILE" ]; then
  echo "No entries with a usable (non-empty, >= ${MIN_PW_LEN} char) password found in vault." >&2
  exit 0
fi

cut -f1 "$MAP_FILE" | sort -u > "$PATTERNS_FILE"
PW_COUNT=$(wc -l < "$PATTERNS_FILE")
echo "Loaded $PW_COUNT unique password(s) from ${#LOGIN_IDS[@]} login entries (skipped $SKIPPED_SHORT short/blank)." >&2

# ---------------------------------------------------------------------------
# Directories/files that are noisy, huge, or never contain "real" user data.
# Same list as find-stray-emails.sh, plus rbw's own local vault storage.
# ---------------------------------------------------------------------------
EXCLUDE_DIRS=(
  .git .cache node_modules .venv venv __pycache__
  .npm .cargo .rustup .steam .wine .var Steam .mozilla/firefox/*/storage
  .config/google-chrome .config/chromium .config/BraveSoftware
  Library/Caches
  go/pkg/mod vendor site-packages .yarn .pnpm-store Pods .gradle .m2
  .stack-work .cabal
  .cache/rbw .local/share/rbw .config/rbw
)

INCLUDE_GLOBS=(
  '*.txt' '*.json' '*.csv' '*.tsv' '*.log' '*.md' '*.yml' '*.yaml' '*.config'
  '.env' '.env.*' '*.env'
)

RG_EXCLUDE_GLOBS=()
for d in "${EXCLUDE_DIRS[@]}"; do
  RG_EXCLUDE_GLOBS+=(--glob "!**/$d/**")
done

RG_GLOBS=()
for g in "${INCLUDE_GLOBS[@]}"; do
  RG_GLOBS+=(--glob "$g")
done
RG_GLOBS+=("${RG_EXCLUDE_GLOBS[@]}")

pdf_note="; PDFs skipped (pdftotext not found)"
[ "$HAVE_PDFTOTEXT" -eq 1 ] && pdf_note=" + PDFs (<= ${MAX_PDF_MB}MB, ${PDF_TIMEOUT}s timeout/file)"
echo "Scanning $ROOT using $JOBS parallel workers for stray passwords in text files${pdf_note}..." >&2

# --- Stage A: plain-text file types, single fast multi-threaded rg pass ----
# Uses --json so passwords containing ":" don't break path/match splitting.
text_matches() {
  rg --json \
    --threads "$JOBS" \
    --max-filesize "$MAX_TEXT_SIZE" \
    "${RG_GLOBS[@]}" \
    -o -F -f "$PATTERNS_FILE" \
    "$ROOT" 2>/dev/null |
  jq -r 'select(.type == "match") | .data.path.text as $p | .data.submatches[].match.text as $m | [$p, $m] | @tsv'
}

# --- Stage B: PDFs, extracted to text in parallel across all cores ---------
process_pdf() {
  local f="$1"
  local size
  size=$(stat -c%s -- "$f" 2>/dev/null) || return 0
  if [ "$size" -gt "$MAX_PDF_BYTES" ]; then
    return 0
  fi
  timeout "$PDF_TIMEOUT" pdftotext -q -- "$f" - 2>/dev/null |
    rg -o -F -f "$PATTERNS_FILE" 2>/dev/null |
    while IFS= read -r pw; do
      printf '%s\t%s\n' "$f" "$pw"
    done
}
export -f process_pdf
export PATTERNS_FILE MAX_PDF_BYTES PDF_TIMEOUT

pdf_matches() {
  [ "$HAVE_PDFTOTEXT" -eq 1 ] || return 0
  rg --files -0 --threads "$JOBS" --glob '*.pdf' \
    "${RG_EXCLUDE_GLOBS[@]}" \
    "$ROOT" 2>/dev/null |
  xargs -0 -P "$JOBS" -n 1 bash -c 'process_pdf "$0"'
}

{
  text_matches
  pdf_matches
} > "$RAW_MATCHES"

if [ ! -s "$RAW_MATCHES" ]; then
  echo "No stray passwords found." >&2
  exit 0
fi

# ---------------------------------------------------------------------------
# Dedupe, look up which vault entry(ies) use each password, mask, print.
# ---------------------------------------------------------------------------
SHOW_FULL="$SHOW_FULL" awk -F'\t' -v mapfile="$MAP_FILE" '
BEGIN {
  show_full = ENVIRON["SHOW_FULL"]
  while ((getline line < mapfile) > 0) {
    n = split(line, f, "\t")
    if (n < 2) continue
    pw = f[1]; name = f[2]
    if (!(pw in names)) {
      names[pw] = name
    } else if (index(names[pw], name) == 0) {
      names[pw] = names[pw] ", " name
    }
  }
  close(mapfile)
}
{
  path = $1
  pw = $2
  key = path SUBSEP pw
  if (key in seen) next
  seen[key] = 1

  if (show_full == "1") {
    display = pw
  } else {
    n = length(pw)
    if (n <= 2) {
      display = ""
      for (i = 0; i < n; i++) display = display "*"
    } else {
      mid = ""
      for (i = 0; i < n - 2; i++) mid = mid "*"
      display = substr(pw, 1, 1) mid substr(pw, n, 1)
    }
  }

  entry = (pw in names) ? names[pw] : "?"
  print path "\t" display "\t" entry
}' "$RAW_MATCHES" |
sort -u -t "$(printf '\t')" -k1,1 -k2,2 |
awk -F'\t' '{ print $1 " -> " $2 "  (vault entry: " $3 ")" }'
