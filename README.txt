HIGHLIGHT READER
================

SETUP
1. Double-click "Start Highlight Reader.vbs".
2. Paste your OpenAI API key into the setup window.
3. Choose a voice and click Save.

CHANGE SETTINGS LATER
Double-click "Edit Settings.vbs". Changes apply to the next reading, even if Highlight Reader is already running.

API KEY HELP
Open https://platform.openai.com/api-keys, sign in, choose Create new secret key, copy it, and paste it into settings. Keep it private. API billing is separate from ChatGPT and usage may cost money.

USE
1. Highlight text in almost any Windows app.
2. Press Ctrl + Shift + R.
3. Use the blue tray icon to change settings, stop speech, or exit.

NOTES
- Your API key is encrypted for your current Windows account.
- Highlighted text is sent to OpenAI to generate speech; API charges may apply.
- Up to 4,000 characters are read at a time.
- If Ctrl + Shift + R is already assigned elsewhere, the app will tell you.

TROUBLESHOOTING
- After replacing the app files, exit the old copy from its tray icon and start it again.
- Pressing Ctrl + Shift + R now shows a "Hotkey detected" notification.
- API or playback errors now appear in a message box.
- A diagnostic log is saved at %LOCALAPPDATA%\HighlightReader\HighlightReader.log.

- If the app is hidden or Ctrl + Shift + R is busy, run Stop Highlight Reader.vbs, then start the app once.
