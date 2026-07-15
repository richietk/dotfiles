#!/usr/bin/env python3
"""Copy a text file of paths, collapsing long runs of image files.

Usage: extract_media_paths.py <path/to/list.txt>

Writes <list>_capped.txt next to the input file: an exact copy of the
original, except that any run of more than 3 consecutive lines sharing
the same jpg/jpeg/png/heic extension is truncated to the first 3 lines
followed by a "(N EXT more...)" summary line. Every other line (any
other extension, or no extension) is passed through unchanged.
"""
import sys
from pathlib import Path

MEDIA_EXTENSIONS = {"jpg", "jpeg", "png", "heic"}
CAP = 3


def media_ext(line):
    ext = Path(line.strip()).suffix.lstrip(".")
    return ext if ext.lower() in MEDIA_EXTENSIONS else None


def cap_runs(lines):
    output = []
    i, n = 0, len(lines)
    while i < n:
        ext = media_ext(lines[i])
        if ext is None:
            output.append(lines[i])
            i += 1
            continue

        j = i
        while j < n and (media_ext(lines[j]) or "").lower() == ext.lower():
            j += 1
        run = lines[i:j]

        output.extend(run[:CAP])
        remaining = len(run) - CAP
        if remaining > 0:
            output.append(f"({remaining} {ext} more...)")
        i = j
    return output


def main():
    if len(sys.argv) != 2:
        print("Usage: extract_media_paths.py <path/to/list.txt>", file=sys.stderr)
        sys.exit(1)

    input_path = Path(sys.argv[1])
    output_path = input_path.with_name(f"{input_path.stem}_capped.txt")

    with input_path.open("r", encoding="utf-8") as f:
        lines = [line.rstrip("\n") for line in f]

    capped = cap_runs(lines)

    with output_path.open("w", encoding="utf-8") as f:
        for line in capped:
            f.write(line + "\n")

    print(f"Wrote {len(capped)} lines (from {len(lines)}) to {output_path}")


if __name__ == "__main__":
    main()
