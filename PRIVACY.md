# Privacy Notice

Last updated: August 18, 2026

Highlight Reader is a free, open-source Windows utility. It does not include analytics, advertising, telemetry, user accounts, or a developer-operated server.

## Information processed

When you press **Ctrl + Shift + R**, the text currently highlighted on your computer is sent directly from your computer to the OpenAI API to generate speech. OpenAI processes that request under its own terms and privacy policies.

Highlight Reader does not send the highlighted text to the app developer, and it does not write the highlighted text to its diagnostic log.

## API key

You provide your own OpenAI API key. Highlight Reader encrypts the key using Windows protection tied to your Windows account and saves the encrypted value locally in `%LOCALAPPDATA%\HighlightReader\settings.json`.

Treat the API key like a password. Do not post it online, share it, or commit it to a public repository. OpenAI API usage may incur charges and is billed separately from ChatGPT subscriptions.

## Files stored locally

Highlight Reader may store the following on your computer:

- Encrypted settings in `%LOCALAPPDATA%\HighlightReader\settings.json`
- The most recently generated audio in `%LOCALAPPDATA%\HighlightReader\speech.wav`
- A diagnostic log in `%LOCALAPPDATA%\HighlightReader\HighlightReader.log`

The diagnostic log contains timestamps, status messages, character counts, and error messages. It is not intended to contain highlighted text or the API key.

## Deleting local data

Use the Highlight Reader uninstaller and choose **Yes** when asked whether to delete saved settings and the encrypted API key. You can also delete `%LOCALAPPDATA%\HighlightReader` manually after closing the app.

## Questions

For questions or reports, open an issue in the [Highlight Reader GitHub repository](https://github.com/allendepena/HighlightReader/issues).
