> Source: https://manual.raycast.com/clipboard-history
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Clipboard History

> Available on: Mac, Windows
> Tier: More with Pro

Raycast's Clipboard History keeps every text, image, file, link, email, and color you've copied so you can search, paste, and reuse anything in seconds.

Ever had the situation that you wanted to find something that you copied earlier? Raycast has a built-in Clipboard History for that. The command keeps track of all copied text, images, files, links, emails, and even colors.

To access it, find the **Clipboard History** command in [Root Search](https://manual.raycast.com/search-bar). We recommend setting a custom Alias or Hotkey through the Shortcuts or Clipboard History tab in **Settings** (`⌘ ,`/`Ctrl ,`) in order to have direct access at all times.

- Raycast now saves every original format you copied. Use **Paste as…** to switch between rich text, plain text, RTF, HTML, and any other format the source provided, so what you paste always matches what you copied.
- When you copy multiple files or pieces of content at once, they're now grouped together as a single clipboard entry instead of being split apart.
- Rename clipboard entries to make them easier to find later.
- Enable **Prefer pasting as plain text** in settings to automatically strip rich formatting on every paste.
- Use **Copy Text from QR Code** to extract the encoded text or link from a QR code in an image in your history.

## Actions

Within the Clipboard History command, you can search through your entries by name, or hit `⌘ P`/`Ctrl P` to filter them by type: Text, Images, Files, Links, Emails, or Colors.

With a clipboard entry highlighted, you can either hit `↵` to paste it into your active input field, or hit `⌘ K`/`Ctrl K` to access additional options in the [Action Panel](https://manual.raycast.com/action-panel), such as:

- **Paste as Plain Text**: strip formatting before pasting
- **Copy to Clipboard** (`⌘ ↵`/`Ctrl ↵`)
- **Copy Text from Image**: extract text from a screenshot or photo via on-device text recognition
- **Copy Text from QR Code**: extract the encoded text or link from a QR code in an image
- **Send to AI Chat**: open a new [AI Chat](https://manual.raycast.com/ai/ai-chat) with the entry as context (or Attach to AI Chat for files and images)
- **Edit Content**: make quick edits to text, links, or colors before pasting
- **Save as Snippet**: turn a frequently used entry into a [Raycast Snippet](https://manual.raycast.com/snippets)
- **Rename Entry** (`⌘ E`/`Ctrl E`)
- **Pin Entry** (`⌘ .`/`Ctrl .`)
- **Delete Entry** (`⌘ X`/`Ctrl X`)
- **Delete Entries…**: bulk-delete by time window (last 5, 15, or 30 minutes, or last 1 or 24 hours) (`⇧ ⌘ X`/`Ctrl Shift X`)
- **Delete All Entries** (`⇧ ⌘ X`/`Ctrl Shift X`)

## Settings

Open Settings (`⌘ ,`/`Ctrl ,`) and select **Clipboard History** from the sidebar to configure how Raycast records, retains, and pastes your clipboard items. Use the toggle in the top-right corner to enable or disable Clipboard History entirely.

### History

**Keep history for**: Choose how long Raycast retains each clipboard item before it's deleted. Options include:

- 1 Day
- 1 Week
- 1 Month
- 3 Months
- 6 Months (Pro)
- 1 Year (Pro)
- Unlimited (Pro)

![Keep history for options](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/core/mac-settings-clipboardhistory-keep.png)

> [!TIP]
> On Raycast Pro? Longer retention isn't enabled automatically. Open **Settings → Clipboard History
> → Keep history for** and pick **Unlimited** (or 6 Months / 1 Year) to use it.

### Text Recognition

- **Text Recognition**: When enabled, Raycast automatically extracts text from images you copy so they can be searched alongside regular text entries. Helpful for quickly grabbing text from screenshots without an OCR step.
- **Recognition Mode**: Choose between faster processing or more accurate text extraction:
  - **Fast**: Lower CPU usage, suitable for most everyday screenshots.
  - **Accurate**: Better recognition for small text, mixed fonts, or low-contrast images, at the cost of higher CPU usage.

![Recognition Mode options](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/core/mac-settings-clipboardhistory-recognitionmode.png)

### Disabled Applications

Add applications where clipboard changes should not be recorded. Common examples like Passwords and Keychain Access are included to prevent sensitive values from ending up in your history. Click the **+** button to add more, for example password managers or banking apps.

### Commands

Assign aliases and hotkeys to the Clipboard History commands you use most:

- **Clipboard History**: Open the searchable history list to paste a previous item. Expand the command to access these options:
  - **Primary Action**: Choose what pressing Return does on a selected entry. **Paste to Active App** inserts the item into the focused app, while **Copy to Clipboard** puts it back at the top of your clipboard.
  - **Prefer pasting as plain text**: When enabled, pasting prioritizes plain text over restoring the original copied formats.
  - **Show visual information for links**: When enabled, social card images and favicons are fetched and displayed for link entries, making them easier to identify at a glance.
  - **Update history after action**: When enabled, clipboard items are moved to the top of the list after a copy or paste action, so your most recently used items stay easy to find.
    ![Clipboard History commands settings](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/core/mac-settings-clipboard-preferplaintext.png)

- **Paste Sequentially**: Paste multiple clipboard items one after another in sequence. Each time you run it, Raycast pastes the next item back through your history (most recent first, then the one before it), advancing a cursor as it goes. The cursor resets automatically once the **Sequence Timeout** elapses or your most recent clipboard item changes. Expand the command to access these options:
  - **Sequence Timeout**: How long Raycast waits between pastes before resetting the sequence. The default selection of 30 Seconds works well for filling out forms across fields.
  - **Add a new line after pasting text**: When enabled, Raycast inserts a line break after each pasted item, useful for pasting lists or filling multi-line text areas.
    ![Paste Sequentially settings](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/core/mac-settings-clipboardhistory-commands-paste.png)

- **Reset Paste Sequence**: Reset the paste sequence to start again from the most recent clipboard item. Running it moves the cursor back to the top and shows a HUD confirming **Paste sequence reset**, so you can restart a sequence right away — for example after a mistake or a context switch — without waiting for the **Sequence Timeout** to lapse. No hotkey is assigned by default; add an alias or hotkey from **Settings → Shortcuts** if you use it often.

### Ask Clipboard

**Ask Clipboard** is a built-in AI Extension that lets you act on your most recently copied item through natural language (for example, "summarize what I just copied" or "translate this to French"). It works with the latest clipboard entry rather than your full history. Assign an alias or hotkey to make it easier to invoke.

![Ask Clipboard settings](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/core/mac-settings-askclipboard.png)

## Troubleshooting

Clipboard History keeps a searchable record of what you copy. Most reports come down to history not recording, images not being captured, paste formatting, or the hotkey not opening the window. Here are the common ones.

### Clipboard History isn't recording anything (or stopped after updating)

If old entries are there but no new copies are saved, work through these checks:

- Make sure Raycast v1 is fully quit, not just disabled. Running v1 and Raycast at the same time can stop Raycast from recording. Quit v1 entirely, then reopen Raycast.
- Confirm Clipboard History is enabled in **Settings → Clipboard History**, then copy a plain piece of text and check whether it appears.
- Test whether it fails for copies from every app or only specific ones, and note which.
- Check your account and permissions. If Raycast is in `/Applications` and that folder is only writable by an admin, a standard user account can be blocked from saving. Confirm whether you're on an admin or standard account.
- On managed Macs, an MDM or security profile can block clipboard monitoring even if v1 worked. On a work device, check with your IT admin.

### Images or screenshots aren't saved, or paste without a file extension

Some image and screenshot entries may not appear in history, or paste without their file extension
so the target app can't open them. Confirm the image actually copied by pasting it directly into
another app first.

### Pasting keeps the formatting, or "Paste as Plain Text" doesn't always work

The default paste behavior changed from v1. To drop formatting on a single entry, use the "Paste
as Plain Text" action from the entry's Action Panel. Some apps re-apply their own styling on
paste, so if you want plain text every time, set your preferred default in **Settings → Clipboard
History**.

### The hotkey doesn't open Clipboard History

If your Clipboard History hotkey doesn't open the window, check for another app bound to the same
shortcut and confirm the hotkey in **Settings → Clipboard History**. Some combinations are
unreliable: double-modifier binds like Option + Option can fail to trigger while Caps Lock is on,
so try a standard modifier combination if yours isn't firing.

### Still having issues?

If none of the above resolves it, gather the following and send it to us via the **Send Feedback** command so we can investigate:

1. **Your OS version** and **Raycast version** (found in **Settings → About**).
2. **Steps to reproduce** the issue.
3. Whether **Raycast v1 is fully quit**.
4. The **app you copied from** and the **app you're pasting into**, and whether it happens with every app or only specific ones.
5. Whether the content was an **image, formatted text, or plain text**.
6. Whether you're on an **admin or standard account**, and whether the Mac is **managed (MDM)**.
7. **Your Raycast logs**: use the built-in **Copy Raycast Logs** command to copy your latest log files to the clipboard, or **Reveal Raycast Logs** to open your log folder.
8. **A screen recording** showing the issue in action.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Clipboard History. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
