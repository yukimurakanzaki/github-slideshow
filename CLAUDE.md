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

## Project Context

This is a GitHub Pages slideshow project (Jekyll-based). Refer to memory files for accumulated project-specific context.
