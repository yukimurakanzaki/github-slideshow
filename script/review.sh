#!/usr/bin/env bash
# review.sh — surface decisions flagged as REVIEW DUE
#
# Usage:
#   ./script/review.sh            # show all REVIEW DUE items
#   ./script/review.sh --all      # show all decisions regardless of status
#   ./script/review.sh --mark <n> # mark item number <n> as REVIEWED (clears flag)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CSV="$REPO_ROOT/memory/decisions.csv"

if [[ ! -f "$CSV" ]]; then
  echo "No decisions file found at $CSV"
  exit 1
fi

MODE="due"
MARK_NUM=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)    MODE="all"; shift ;;
    --mark)   MODE="mark"; MARK_NUM="$2"; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

# ── display flagged / all decisions ──────────────────────────────────────────

if [[ "$MODE" == "due" || "$MODE" == "all" ]]; then
  python3 - "$CSV" "$MODE" <<'PYEOF'
import csv, sys

src, mode = sys.argv[1], sys.argv[2]

RESET  = "\033[0m"
BOLD   = "\033[1m"
RED    = "\033[31m"
YELLOW = "\033[33m"
CYAN   = "\033[36m"
GREEN  = "\033[32m"

STATUS_COLOR = {
    "REVIEW DUE": RED + BOLD,
    "PENDING":    YELLOW,
    "REVIEWED":   GREEN,
}

with open(src, newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    rows = list(reader)

target = [r for r in rows if mode == "all" or r.get("status", "").strip() == "REVIEW DUE"]

if not target:
    if mode == "due":
        print("No decisions flagged for review.")
    else:
        print("No decisions logged yet.")
    sys.exit(0)

label = "DECISIONS FLAGGED FOR REVIEW" if mode == "due" else "ALL DECISIONS"
print(f"\n{BOLD}{CYAN}{'─'*60}{RESET}")
print(f"{BOLD}{CYAN}  {label}{RESET}")
print(f"{BOLD}{CYAN}{'─'*60}{RESET}\n")

for i, row in enumerate(target, 1):
    status = row.get("status", "").strip()
    color  = STATUS_COLOR.get(status, "")
    print(f"{BOLD}[{i}] {row.get('date','')}  —  {color}{status}{RESET}")
    print(f"    {BOLD}Decision:{RESET}         {row.get('decision','')}")
    print(f"    {BOLD}Reasoning:{RESET}        {row.get('reasoning','')}")
    print(f"    {BOLD}Expected outcome:{RESET} {row.get('expected_outcome','')}")
    print(f"    {BOLD}Review due:{RESET}       {row.get('review_date','')}")
    print()

if mode == "due":
    print(f"To mark an item reviewed:  ./script/review.sh --mark <number>")
PYEOF
fi

# ── mark an item as REVIEWED ──────────────────────────────────────────────────

if [[ "$MODE" == "mark" ]]; then
  if [[ -z "$MARK_NUM" ]] || ! [[ "$MARK_NUM" =~ ^[0-9]+$ ]]; then
    echo "Usage: ./script/review.sh --mark <row-number>" >&2
    exit 1
  fi

  python3 - "$CSV" "$MARK_NUM" <<'PYEOF'
import csv, sys

src, num = sys.argv[1], int(sys.argv[2])

with open(src, newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    fieldnames = reader.fieldnames
    rows = list(reader)

due = [r for r in rows if r.get("status","").strip() == "REVIEW DUE"]

if num < 1 or num > len(due):
    print(f"Error: item {num} not found in REVIEW DUE list (there are {len(due)} flagged items).", file=sys.stderr)
    sys.exit(1)

target = due[num - 1]
target["status"] = "REVIEWED"
decision_text = target.get("decision","")

import tempfile, os
tmp = src + ".tmp"
with open(tmp, "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(rows)
os.replace(tmp, src)

print(f"Marked as REVIEWED: {decision_text}")
PYEOF
fi
