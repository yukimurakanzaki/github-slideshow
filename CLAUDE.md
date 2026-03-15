# Claude Instructions

## Persistent Memory System

At the **start of every session**, read all files in the `memory/` directory to restore context:

```
memory/decisions.md   - Past technical and project decisions
memory/people.md      - People involved in the project
memory/preferences.md - Coding style, tooling, and workflow preferences
memory/user.md        - Information about the user
```

At the **end of every session** (or after any significant interaction), update the relevant memory files with new information learned during the session:

- **decisions.md**: Record any significant technical decisions, architectural choices, or approaches agreed upon. Include the date, what was decided, and why.
- **people.md**: Add or update information about collaborators, maintainers, or stakeholders encountered.
- **preferences.md**: Note any preferences the user expresses about code style, tools, workflow, or communication.
- **user.md**: Update with new information about the user's goals, background, working style, or context.

## Update Format

When updating memory files, append new entries under the existing comments. Always include the date (YYYY-MM-DD format) with each entry. Do not delete existing entries unless they are explicitly outdated or incorrect — prefer appending.

## Decision Logging

When the user describes a decision they are making, log it immediately using:

```bash
./script/log_decision.sh \
  --decision   "<the decision>" \
  --reasoning  "<why they made it>" \
  --outcome    "<what they expect to happen>"
```

This appends a row to `memory/decisions.csv` with today's date and a review date 30 days out.

**Trigger phrases** — log a decision whenever the user says things like:
- "I've decided to…", "We're going with…", "I'm choosing…"
- "My plan is…", "Going forward I'll…", "I want to…" (when describing a concrete choice)

After logging, confirm to the user: the decision recorded, and the review date.

### Cron job (daily review check)

Add to crontab to flag overdue reviews automatically:

```
0 8 * * * /absolute/path/to/repo/script/check_reviews.sh >> /absolute/path/to/repo/memory/check_reviews.log 2>&1
```

To install: run `crontab -e` and add the line above with the correct absolute path.

### Reviewing flagged decisions

```bash
./script/review.sh           # show items with status REVIEW DUE
./script/review.sh --all     # show all decisions
./script/review.sh --mark 1  # mark item #1 as REVIEWED
```

## Project Context

This is a GitHub Pages slideshow project (Jekyll-based). Refer to memory files for accumulated project-specific context.
