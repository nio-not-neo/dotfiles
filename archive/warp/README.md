# Warp, retired

Distilled from `~/.warp/settings.toml`. Account, telemetry, sync and agent-permission settings are Warp-specific
and not kept. The four `tab_configs/` files were identical empty templates.

| Setting | Value | Status |
|---|---|---|
| Font size | 13 | Not ported (Ghostty kept at 14) |
| Vertical tabs | On | Replaced by herdr's sidebar |
| Long-running notification | After 30s, plus needs-attention and password-prompt alerts | Ported: `notify-on-command-finish-after = 30s`. herdr handles agent attention |
| Clipboard (OSC 52) | Write-only | Ghostty default is `clipboard-write = allow`, `clipboard-read = ask` (equivalent) |
| Agent command denylist | `rm`, `curl`, `ssh`, shells, ... | Worth reusing as Claude Code deny rules if wanted |
