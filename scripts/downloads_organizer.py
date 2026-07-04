#!/usr/bin/env python3
"""
Organize ~/Downloads, ~/Documents, and ~/Music.

Downloads (non-recursive):
  1. Deduplicate same-stem files (browser copy pattern: 'file (1).pdf')
       identical  → delete the copy
       different  → rename copy to stem_duplicate.ext
  2. Delete files whose extension is exactly .parts
  3. Sort by keyword / extension (see tables below).
     Multi-match → prompt user.

Documents (non-recursive):
  Same keyword and extension checks as Downloads, minus iso/exe and csv/odp/xlsx
  (those are Downloads-only since they'd be no-ops or already handled).

Music (recursive):
  .webm and .m4a → Music/music_videos/ with relative path preserved.
  e.g. Music/english/dave/song.m4a → Music/music_videos/english/dave/song.m4a

Destination table (all keyword/archive dests live in ~/Documents):
  Keyword "cv/resume/takacs/…"   → Documents/personal_docs
  Keyword "course/semester/…"    → Documents/studies
  Keyword "key/backup/…"         → Documents/potentially_sensitive
  .apkg/.bak/.zip/.tgz/.gz       → Documents/archive
  .iso/.exe          (DL only)   → Documents/isoexe
  .mp3/.opus                     → ~/Music
  .mp4/.mkv                      → ~/Videos
  .csv/.odp/.xlsx    (DL only)   → ~/Documents
  .png/.jpg                      → ~/Pictures
  .torrent                       → Downloads/torrent_files

Fallbacks (only when nothing above matched):
  .sh/.py/.service               → Documents/unidentifiedscripts
  .pdf                           → Documents/unidentified_pdfs

Usage:
  python3 ~/dotfiles/scripts/downloads_organizer.py
"""

import re
import sys
import shutil
from pathlib import Path

HOME      = Path.home()
DOWNLOADS = HOME / "Downloads"
DOCUMENTS = HOME / "Documents"
MUSIC     = HOME / "Music"
VIDEOS    = HOME / "Videos"
PICTURES  = HOME / "Pictures"

KEYWORD_CATS: dict[str, list[str]] = {
    "personal_docs":         ["cv", "resume", "takacs", "biztositas", "versicherung", "melde"],
    "studies":               ["course", "semester", "gpa", "msc", "enrollment"],
    "potentially_sensitive": ["key", "backup", "codes", "bitwarden", "password"],
}

ARCHIVE_EXTS  = frozenset({".apkg", ".bak", ".zip", ".tgz", ".gz"})
ISO_EXE_EXTS  = frozenset({".iso", ".exe"})
SCRIPT_EXTS   = frozenset({".sh", ".py", ".service"})
MUSIC_VID_EXTS = frozenset({".webm", ".m4a"})

# Extension → absolute destination (both Downloads and Documents)
EXT_DEST: dict[str, Path] = {
    ".mp3": MUSIC,  ".opus": MUSIC,
    ".mp4": VIDEOS, ".mkv":  VIDEOS,
    ".png": PICTURES, ".jpg": PICTURES,
}

# Extension → absolute destination (Downloads only; would be no-ops from Documents)
EXT_DEST_DL_ONLY: dict[str, Path] = {
    ".csv": DOCUMENTS, ".odp": DOCUMENTS, ".xlsx": DOCUMENTS,
}

# All destination subdirs that live inside ~/Documents (skip when iterating Documents)
DOCS_LOCAL_SKIP = frozenset({
    "personal_docs", "studies", "potentially_sensitive",
    "archive", "isoexe", "unidentifiedscripts", "unidentified_pdfs",
})


# ─── helpers ────────────────────────────────────────────────────────────────

def _norm_stem(stem: str) -> str:
    """Strip browser copy-suffix: 'report (2)' → 'report'."""
    return re.sub(r"\s+\(\d+\)$", "", stem)


def _identical(a: Path, b: Path) -> bool:
    if a.stat().st_size != b.stat().st_size:
        return False
    BUF = 1 << 16
    with open(a, "rb") as fa, open(b, "rb") as fb:
        while True:
            ca, cb = fa.read(BUF), fb.read(BUF)
            if ca != cb:
                return False
            if not ca:
                return True


def _safe_move(src: Path, dest_dir: Path) -> None:
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest = dest_dir / src.name
    if dest.resolve() == src.resolve():
        return
    if dest.exists():
        i = 1
        while dest.exists():
            dest = dest_dir / (
                f"{src.stem}_{i}{src.suffix}" if src.is_file() else f"{src.name}_{i}"
            )
            i += 1
    try:
        shutil.move(str(src), str(dest))
    except OSError as exc:
        print(f"  ERROR moving {src.name}: {exc}", file=sys.stderr)
        return
    print(f"  Moved  {src.name}  →  {dest}")


def _ask(item: Path, options: list[tuple[str, Path]]) -> tuple[str, Path] | None:
    print(f"\n  '{item.name}' matches multiple categories:")
    for i, (label, dest) in enumerate(options, 1):
        print(f"    {i}) {label:<28} →  {dest}")
    print("    s) Skip")
    while True:
        ans = input("  Choice: ").strip().lower()
        if ans == "s":
            return None
        if ans.isdigit() and 1 <= int(ans) <= len(options):
            return options[int(ans) - 1]
        print("  Invalid — try again.")


# ─── core steps ─────────────────────────────────────────────────────────────

def deduplicate(folder: Path) -> None:
    """Handle browser-created filename duplicates (non-recursive)."""
    groups: dict[tuple, list[Path]] = {}
    for p in folder.iterdir():
        if not p.is_file():
            continue
        key = (_norm_stem(p.stem).lower(), p.suffix.lower())
        groups.setdefault(key, []).append(p)

    def _rank(p: Path) -> tuple[int, int]:
        m = re.search(r"\s+\((\d+)\)$", p.stem)
        return (1, int(m.group(1))) if m else (0, 0)

    for files in groups.values():
        if len(files) < 2:
            continue
        files.sort(key=_rank)
        original = files[0]
        print(f"\n  Duplicate group: '{original.name}'")
        for dup in files[1:]:
            try:
                same = _identical(original, dup)
            except OSError as exc:
                print(f"    ERROR reading {dup.name}: {exc}", file=sys.stderr)
                continue
            if same:
                print(f"    Identical → deleting  {dup.name}")
                try:
                    dup.unlink()
                except OSError as exc:
                    print(f"    ERROR: {exc}", file=sys.stderr)
            else:
                new_name = f"{dup.stem}_duplicate{dup.suffix}"
                try:
                    dup.rename(dup.parent / new_name)
                except OSError as exc:
                    print(f"    ERROR renaming {dup.name}: {exc}", file=sys.stderr)
                    continue
                print(f"    Different → renamed   {dup.name}  →  {new_name}")


def delete_parts(folder: Path) -> None:
    """Delete files whose suffix is exactly .parts (not e.g. script_parts.py)."""
    for p in folder.iterdir():
        if p.is_file() and p.suffix.lower() == ".parts":
            try:
                p.unlink()
                print(f"  Deleted  {p.name}")
            except OSError as exc:
                print(f"  ERROR deleting {p.name}: {exc}", file=sys.stderr)


def _categories(item: Path, from_downloads: bool) -> list[tuple[str, Path]]:
    """
    Return (label, dest) pairs for the item.
    Primary hits are returned first; if none match, fallback hits are returned.
    All keyword/archive destinations live in ~/Documents regardless of source folder.
    """
    primary: list[tuple[str, Path]] = []
    name_lc = item.name.lower()
    ext = item.suffix.lower() if not item.is_dir() else ""

    # Keyword categories → always Documents/cat
    for cat, kws in KEYWORD_CATS.items():
        if any(kw in name_lc for kw in kws):
            primary.append((cat, DOCUMENTS / cat))

    # Archive → always Documents/archive
    if ext in ARCHIVE_EXTS:
        primary.append(("archive", DOCUMENTS / "archive"))

    # iso/exe → Documents/isoexe (Downloads only per spec)
    if from_downloads and ext in ISO_EXE_EXTS:
        primary.append(("isoexe", DOCUMENTS / "isoexe"))

    # Media → absolute paths
    if ext in EXT_DEST:
        d = EXT_DEST[ext]
        primary.append((d.name, d))

    # csv/odp/xlsx → Documents (no-op if already in Documents)
    if from_downloads and ext in EXT_DEST_DL_ONLY:
        d = EXT_DEST_DL_ONLY[ext]
        primary.append((d.name, d))

    # Torrent → Downloads/torrent_files
    if ext == ".torrent":
        primary.append(("torrent_files", DOWNLOADS / "torrent_files"))

    # Collapse duplicate destinations (e.g. two keywords both resolve to personal_docs)
    seen: set[Path] = set()
    deduped: list[tuple[str, Path]] = []
    for h in primary:
        if h[1] not in seen:
            seen.add(h[1])
            deduped.append(h)

    # Fallbacks — only when nothing above matched
    if not deduped:
        if ext in SCRIPT_EXTS:
            deduped.append(("unidentifiedscripts", DOCUMENTS / "unidentifiedscripts"))
        elif ext == ".pdf":
            deduped.append(("unidentified_pdfs", DOCUMENTS / "unidentified_pdfs"))

    return deduped


def organize(folder: Path, from_downloads: bool) -> None:
    """Sort all top-level items in folder into their matching category."""
    if not folder.exists():
        print(f"  Folder not found: {folder}")
        return

    # Skip destination dirs that live inside THIS folder to avoid moving them into themselves.
    # All keyword/archive dests are in Documents now, so Downloads only needs torrent_files.
    if folder == DOWNLOADS:
        local_skip = frozenset({"torrent_files"})
    else:
        local_skip = DOCS_LOCAL_SKIP

    for item in list(folder.iterdir()):
        if item.is_dir() and item.name in local_skip:
            continue
        hits = _categories(item, from_downloads)
        if not hits:
            continue
        if len(hits) == 1:
            _safe_move(item, hits[0][1])
        else:
            choice = _ask(item, hits)
            if choice:
                _safe_move(item, choice[1])


def organize_music(music_folder: Path) -> None:
    """
    Recursively move .webm and .m4a into Music/music_videos/,
    preserving the relative sub-path.
    Music/english/dave/song.m4a → Music/music_videos/english/dave/song.m4a
    """
    if not music_folder.exists():
        print(f"  Folder not found: {music_folder}")
        return

    music_videos = music_folder / "music_videos"

    for item in list(music_folder.rglob("*")):
        if not item.is_file():
            continue
        if item.suffix.lower() not in MUSIC_VID_EXTS:
            continue
        # Skip files already inside music_videos/
        try:
            item.relative_to(music_videos)
            continue
        except ValueError:
            pass
        rel = item.relative_to(music_folder)
        _safe_move(item, music_videos / rel.parent)


# ─── main ───────────────────────────────────────────────────────────────────

def main() -> None:
    SEP = "─" * 60

    print(SEP)
    print("Step 1 — Deduplicating ~/Downloads")
    print(SEP)
    if not DOWNLOADS.exists():
        print("  ~/Downloads not found, skipping.")
    else:
        deduplicate(DOWNLOADS)

    print(f"\n{SEP}")
    print("Step 2 — Deleting .parts files in ~/Downloads")
    print(SEP)
    if DOWNLOADS.exists():
        delete_parts(DOWNLOADS)

    print(f"\n{SEP}")
    print("Step 3 — Organizing ~/Downloads")
    print(SEP)
    organize(DOWNLOADS, from_downloads=True)

    print(f"\n{SEP}")
    print("Step 4 — Organizing ~/Documents")
    print(SEP)
    organize(DOCUMENTS, from_downloads=False)

    print(f"\n{SEP}")
    print("Step 5 — Moving .webm/.m4a in ~/Music → music_videos/")
    print(SEP)
    organize_music(MUSIC)

    print("\nDone.")


if __name__ == "__main__":
    main()
