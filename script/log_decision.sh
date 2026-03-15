#!/usr/bin/env bash
# log_decision.sh — interactively log a decision to memory/decisions.csv
#
# Usage:
#   ./script/log_decision.sh
#   ./script/log_decision.sh --decision "..." --reasoning "..." --outcome "..."
#
# All fields can also be passed as flags (useful when called by Claude):
#   --decision    The decision made
#   --reasoning   Why this decision was made
#   --outcome     Expected outcome

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CSV="$REPO_ROOT/memory/decisions.csv"

# ── helpers ──────────────────────────────────────────────────────────────────

csv_escape() {
  # Wrap in double-quotes and escape any internal double-quotes
  local val="$1"
  val="${val//\"/\"\"}"
  echo "\"$val\""
}

today() { date +%Y-%m-%d; }

add_days() {
  # add_days <date YYYY-MM-DD> <n>
  date -d "$1 + $2 days" +%Y-%m-%d 2>/dev/null \
    || python3 -c "from datetime import date, timedelta; d=date.fromisoformat('$1'); print((d+timedelta(days=$2)).isoformat())"
}

# ── parse flags ──────────────────────────────────────────────────────────────

ARG_DECISION=""
ARG_REASONING=""
ARG_OUTCOME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --decision)  ARG_DECISION="$2";  shift 2 ;;
    --reasoning) ARG_REASONING="$2"; shift 2 ;;
    --outcome)   ARG_OUTCOME="$2";   shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

# ── collect input ────────────────────────────────────────────────────────────

if [[ -n "$ARG_DECISION" ]]; then
  DECISION="$ARG_DECISION"
else
  echo ""
  read -rp "Decision: " DECISION
fi

if [[ -z "$DECISION" ]]; then
  echo "Error: decision cannot be empty." >&2
  exit 1
fi

if [[ -n "$ARG_REASONING" ]]; then
  REASONING="$ARG_REASONING"
else
  read -rp "Reasoning: " REASONING
fi

if [[ -n "$ARG_OUTCOME" ]]; then
  OUTCOME="$ARG_OUTCOME"
else
  read -rp "Expected outcome: " OUTCOME
fi

# ── compute dates ─────────────────────────────────────────────────────────────

DATE="$(today)"
REVIEW_DATE="$(add_days "$DATE" 30)"

# ── append row ────────────────────────────────────────────────────────────────

# Ensure CSV exists with header
if [[ ! -f "$CSV" ]]; then
  echo "date,decision,reasoning,expected_outcome,review_date,status" > "$CSV"
fi

ROW="$(csv_escape "$DATE"),$(csv_escape "$DECISION"),$(csv_escape "$REASONING"),$(csv_escape "$OUTCOME"),$(csv_escape "$REVIEW_DATE"),$(csv_escape "PENDING")"
echo "$ROW" >> "$CSV"

echo ""
echo "Logged decision."
echo "  Date:        $DATE"
echo "  Review due:  $REVIEW_DATE"
echo "  File:        $CSV"
