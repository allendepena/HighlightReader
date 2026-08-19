# Highlight Reader

Highlight text in almost any Windows app, press **Ctrl + Shift + R**, and hear it read aloud with OpenAI text-to-speech.

## Install and start

1. Download the project ZIP and extract it.
2. Keep all files together in the extracted folder.
3. Double-click **Start Highlight Reader.vbs**.
4. Complete the settings window, then select **Save**.

## Create an OpenAI API key

1. Open [OpenAI API keys](https://platform.openai.com/api-keys) and sign in.
2. Select **Create new secret key**.
3. Copy the new key when it is shown.
4. Paste it into Highlight Reader's **OpenAI API key** box and save.
5. If the account has no API balance, open [Billing](https://platform.openai.com/settings/organization/billing/overview) and add credits or a payment method.

Treat the API key like a password: do not post it online, commit it to GitHub, or share it. OpenAI API usage may cost money and is billed separately from ChatGPT subscriptions.

## Use the app

1. Highlight some text.
2. Press and release **Ctrl + Shift + R**.
3. Wait a few seconds for speech to begin.

## Change settings later

Double-click **Edit Settings.vbs** at any time. You can change the API key, voice, quality, reading speed, and whether the app starts when you sign in. Changes apply to the running app on the next reading.

You can also double-click the Highlight Reader tray icon or right-click it and select **Settings**.

## Stop or troubleshoot

- Use the tray icon's **Stop speaking** or **Exit** command.
- If the app is hidden or the hotkey is busy, run **Stop Highlight Reader.vbs**, then start the app once.
- Diagnostic logs are stored at `%LOCALAPPDATA%\HighlightReader\HighlightReader.log`.
