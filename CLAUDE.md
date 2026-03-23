# Claude Code Configuration

## NotebookLM Integration

Documentation and source-of-truth (SOT) files are uploaded to Google NotebookLM.
**Do NOT read docs from disk — query NotebookLM instead to save tokens.**

### Workflow

1. User uploads docs/SOT to a NotebookLM notebook
2. Claude Code queries the notebook using `notebooklm ask`

### Quick Reference

```bash
# One-time login (browser OAuth)
notebooklm login

# List available notebooks
notebooklm list

# Set active notebook
notebooklm use <notebook-id>

# Query the active notebook
notebooklm ask "What does X do?"

# Check current context
notebooklm status
```

### Architecture

```
User docs/SOT → NotebookLM notebook
                        ↓
Claude Code → notebooklm ask "..." → answer (no file reads needed)
```

Use the `/notebooklm` skill in Claude Code for full NotebookLM access.

### Installation

```bash
pip install "notebooklm-py[browser]"
playwright install chromium
notebooklm skill install
notebooklm login
```
