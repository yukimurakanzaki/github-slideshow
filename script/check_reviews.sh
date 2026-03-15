#!/usr/bin/env bash
# check_reviews.sh — daily cron job that flags decisions whose review date has arrived.
#
# Cron setup (run daily at 08:00):
#   0 8 * * * /path/to/repo/script/check_reviews.sh >> /path/to/repo/memory/check_reviews.log 2>&1
#
# What it does:
#   - Reads memory/decisions.csv
#   - For any row whose review_date <= today and status is PENDING, sets status to REVIEW DUE
#   - Writes the updated CSV in-place
#   - Prints a summary of newly flagged items

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CSV="$REPO_ROOT/memory/decisions.csv"

if [[ ! -f "$CSV" ]]; then
  echo "$(date -Iseconds) [check_reviews] decisions.csv not found at $CSV — nothing to do."
  exit 0
fi

TODAY="$(date +%Y-%m-%d)"
FLAGGED=0
TMPFILE="$(mktemp)"

# ── parse CSV with awk, flag overdue rows ─────────────────────────────────────
# Column indices (1-based): date=1 decision=2 reasoning=3 expected_outcome=4 review_date=5 status=6
# We use a small Python script for robust CSV handling (handles quoted commas/newlines).

python3 - "$CSV" "$TODAY" "$TMPFILE" <<'PYEOF'
import csv, sys
from datetime import date

src, today_str, dst = sys.argv[1], sys.argv[2], sys.argv[3]
today = date.fromisoformat(today_str)
flagged = []

rows = []
with open(src, newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    fieldnames = reader.fieldnames
    for row in reader:
        review_str = row.get("review_date", "").strip()
        status = row.get("status", "").strip()
        if review_str and status == "PENDING":
            try:
                review_date = date.fromisoformat(review_str)
                if review_date <= today:
                    row["status"] = "REVIEW DUE"
                    flagged.append(row)
            except ValueError:
                pass
        rows.append(row)

with open(dst, "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(rows)

# Print flagged decisions to stdout for the log
for r in flagged:
    print(f"FLAGGED | {r['review_date']} | {r['decision']}")

sys.exit(0 if not flagged else 2)
PYEOF

EXIT_CODE=$?

# Replace original CSV with updated version
mv "$TMPFILE" "$CSV"

if [[ $EXIT_CODE -eq 2 ]]; then
  echo "$(date -Iseconds) [check_reviews] Review flags written to $CSV — run ./script/review.sh to view them."
elif [[ $EXIT_CODE -eq 0 ]]; then
  echo "$(date -Iseconds) [check_reviews] No new reviews due today."
fi
