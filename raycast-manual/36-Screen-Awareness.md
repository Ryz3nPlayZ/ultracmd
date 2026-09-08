> Source: https://manual.raycast.com/ai/screen-awareness
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Screen Awareness

> Available on: Mac, Windows
> Tier: Pro Exclusive

Ask Raycast AI about whatever you're looking at. Screen Awareness reads the focused window's content, your selection, and a screenshot, then sends it to AI with your question.

Screen Awareness lets you ask Raycast AI about whatever is in front of you. Instead of describing your screen or pasting chunks of it into a chat, press a hotkey and Raycast captures the focused window for you: the app's content, the text you have selected, and a screenshot.

[Screen Awareness in Raycast (YouTube)](https://www.youtube.com/watch?v=_eHOl-KyY6I)

## Get Started

1. Run **Send Focused Window to AI** from Root Search. The first time, Raycast opens **Set Up Screen Awareness**.
2. _(Only on Mac)_ Grant the **Screen Recording** and **Accessibility** permissions. See [Permissions](#permissions).
3. Accept the suggested hotkey, a double tap of the right `⌘`/`Ctrl` key, or record your own.

With a hotkey set it becomes a single gesture: press it from anywhere and [AI Chat](https://manual.raycast.com/ai/ai-chat) opens with the capture attached, ready for your question.

> [!TIP]
> If the suggested hotkey is already taken, Raycast tells you which command owns it rather than overwriting it, and you can record a different one.

You can also start a capture from AI Chat or Quick AI: open the ** Add Context** menu to the left of the composer and pick **Focused Window**, **Selected Text**, **Selected Area**, or **Entire Screen**.

## What Raycast Captures

A capture bundles everything Raycast can read about the window you're looking at. Each piece is gathered independently, so a capture still works when some of them aren't available:

- **App details**: The name of the frontmost app and the title of its window.
- **App content**: The readable text in the window, taken from the system accessibility layer.
- **Your selection**: Whatever text you have highlighted in that window.
- **The focused control**: The specific field or element your cursor is in, including its value.
- **A screenshot** of the focused window, so the model can see anything that isn't text.
- **The current page**: When the focused app is a browser, the tab's title, URL, and content. Requires the [Raycast Browser Companion](https://raycast.com/browser-extension).
- _(Only on Mac)_ **Selected files**: The file paths you have selected, when Finder is the focused app.

Raycast never captures itself. Its own windows are excluded from every capture, so sending the focused window from AI Chat reads the app behind it, not the chat.

> [!NOTE]
> Screen Awareness reads your selection passively from the same accessibility snapshot it's already taking. It doesn't steal focus from the app you're in and it doesn't touch your clipboard.

### Check What Was Captured

As the capture is taken, an attachment card appears in the composer. It starts as **Screen Awareness** and fills in with the app's name as the details arrive. Click the card to see what was included:

- **App** and **Document**: The app and window (or page) the capture came from.
- **Capture Type**: **Screenshot + App Content**, **Screenshot**, **App Content**, or **Window Metadata**, depending on what Raycast could read.
- **Selection**: The text you had highlighted.
- **Included**: Which sources made it into the bundle, from Screenshot and Page text through App content, Focused control, Selection, and Files.

## Commands

Screen Awareness also covers the narrower captures, for when you know exactly what you want to send:

- **Send Focused Window to AI**: The full capture described above.
- **Send Selected Text to AI**: Only the text you've selected in the active app.
- **Send Screen to AI**: A screenshot of your entire screen.
- **Send Screen Area to AI**: A screenshot of an area you drag out.

Each command sends to AI Chat by default. To send to Quick AI instead, change the command's **Primary Action** in **Settings → Screen Awareness**.

> [!TIP]
> **Send Focused Window to AI** works as a [fallback command](https://manual.raycast.com/settings#fallback-commands), so Root Search text with no matches can go straight to AI with your screen attached.

## AI Extensions

Screen Awareness includes an [AI Extension](https://manual.raycast.com/ai/ai-extensions), **Ask Screen Awareness** (`@screen-awareness`), so the model can decide to look at your screen mid-conversation instead of prompting you to attach something.

When the model uses the Screen Awareness AI Extension, a **Looking at Frontmost Window** tool appears in the Chat, named after the app it can see, which is useful to confirm it read the window you meant.

## Settings

Screen Awareness settings live under **Settings → Screen Awareness**, where each command can be enabled or disabled and given a hotkey or alias, alongside:

- **Primary Action**: Whether the command sends to **AI Chat** (default) or **Quick AI**.
- **Custom Instructions** on **Ask Screen Awareness**: Steer how the model uses your screen.

## Permissions
_(Only on Mac)_

Screen Awareness needs **Screen Recording** to capture window screenshots and **Accessibility** to read the content of your focused app. Grant both from the setup view, or in **System Settings → Privacy & Security**. Granting a permission restarts Raycast, and setup picks up where you left off.

Accessibility is the one that matters most. Without it, Screen Awareness can't read the window and the attachment card shows **No Accessibility Permission** with a **Grant Permission** button. Screen Recording is optional: without it you still get the app's content, just no screenshot.

## Privacy

A capture is only taken when you ask for one, by running a command, including a Screen Awareness attachment, or asking the AI to look. Nothing is captured in the background, and nothing is stored: the capture is attached to the message you send and then handled like any other AI attachment. See [Raycast AI Privacy & Security](https://manual.raycast.com/ai/raycast-ai-privacy-security) for how attachments are processed.

A capture can include anything visible in the focused window, so you should consider when to use it, especially around sensitive information. To stop Screen Awareness being available at all, disable its commands and the **Ask Screen Awareness** AI Extension in Settings. On macOS you can also revoke the Screen Recording or Accessibility permission in **System Settings → Privacy & Security**.

## Troubleshooting

### Raycast says no context was captured

This means none of the capture sources returned anything. The usual cause on macOS is a missing **Accessibility** permission. Check **System Settings → Privacy & Security → Accessibility** and make sure Raycast is enabled there.

Some apps also expose very little through the accessibility layer. In those cases you'll still get a screenshot and the window's title, which is often enough for the model to work with.

### My selected text isn't included in the capture

Screen Awareness reads your selection passively through the accessibility layer rather than copying it, which keeps it from stealing focus or touching your clipboard. The trade-off is that apps which don't expose their selection that way won't report one.

If you specifically need the selected text, use **Send Selected Text to AI**, which asks the app for the selection directly.

### It captured the wrong window

Screen Awareness captures whatever was frontmost when you triggered it, and Raycast's own windows are always skipped. If you trigger it from inside AI Chat, you'll get the app behind AI Chat. Assign a hotkey to **Send Focused Window to AI** so you can capture without switching windows first.

### The browser tab's content isn't included

Reading the current page needs the [Raycast Browser Companion](https://raycast.com/browser-extension) installed in your browser. Raycast also only attaches a tab when the focused app is itself a browser, and only when that tab matches the window you're looking at, so a tab from a background browser window is deliberately left out.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Screen Awareness. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
