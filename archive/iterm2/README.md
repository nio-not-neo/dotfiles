# iTerm2 (3.7.3), retired

Profile "Default" was almost entirely stock. Distilled from `~/Library/Preferences/com.googlecode.iterm2.plist`
(the raw plist isn't kept: it's mostly colour tables, and includes AI feature settings).

| Setting | Value | Status in Ghostty |
|---|---|---|
| Font | Hack Nerd Font 12 | Ported: `font-family = "Hack Nerd Font"` (size kept at 14) |
| Shift+Enter | Sends `\n` (global key map) | Ported: `keybind = shift+enter=text:\n` |
| Scrollback | 1000 lines | Not needed: Ghostty's default is far larger |
| Option key | Normal (no Alt) | Changed: Ghostty uses `macos-option-as-alt = left` |
| Terminal type | xterm-256color | Ghostty uses `xterm-ghostty` |
| Window | 80x25, no transparency/blur | Not ported |
| Mouse reporting | On | Ghostty default |
