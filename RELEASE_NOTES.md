# Highlight Reader v1.0.0-beta

This is the first public beta of Highlight Reader, a free Windows utility that reads highlighted text aloud using OpenAI text-to-speech.

## Included

- Global **Ctrl + Shift + R** reading shortcut
- Voice, quality, and reading-speed settings
- Encrypted local storage for the user's OpenAI API key
- Desktop settings shortcut and system-tray controls
- Optional start with Windows
- Per-user installer and uninstaller
- API-key setup guidance
- Local diagnostic logging

## Install

1. Download `HighlightReader-v1.0.0-beta.zip`.
2. Extract the ZIP.
3. Double-click **Install Highlight Reader.vbs**.
4. Follow the setup window to add your own OpenAI API key.

## Important

- Highlight Reader is free, but OpenAI API usage may incur charges.
- Highlighted text is sent directly to OpenAI to create speech.
- This beta is Windows-only.
- The current beta uses unsigned PowerShell/VBS components, so Windows may display a security warning.
- The app reads up to 4,000 characters per request.
- Another app may already use **Ctrl + Shift + R**.

Please report problems through [GitHub Issues](https://github.com/allendepena/HighlightReader/issues).
