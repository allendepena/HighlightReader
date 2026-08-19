# Highlight Reader

Highlight text in almost any Windows app, press **Ctrl + Shift + R**, and hear it read aloud with OpenAI text-to-speech.

## Install and start

1. Download the project ZIP and extract it.
2. Double-click **Install Highlight Reader.vbs**.
3. Confirm the installation.
4. Complete the settings window, then select **Save**.

Installation creates a **Highlight Reader** desktop icon. Double-clicking it opens the settings window. The app itself runs quietly in the system tray.

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

## Uninstall

Use **Windows Settings > Apps > Installed apps > Highlight Reader > Uninstall**, or open the Start menu and choose **Highlight Reader > Uninstall Highlight Reader**. The uninstaller lets you keep or delete saved settings and the encrypted API key.

## Stop or troubleshoot

- Use the tray icon's **Stop speaking** or **Exit** command.
- If the app is hidden or the hotkey is busy, run **Stop Highlight Reader.vbs**, then start the app once.
- Diagnostic logs are stored at `%LOCALAPPDATA%\HighlightReader\HighlightReader.log`.
