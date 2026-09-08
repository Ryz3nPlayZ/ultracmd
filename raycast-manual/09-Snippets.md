> Source: https://manual.raycast.com/snippets
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Snippets

> Available on: Mac, Windows, iOS

Store and auto-expand text snippets from Raycast. Type a keyword in any app to instantly paste templates, code, addresses, signatures, and more.

Snippets let you store frequently used text and insert it anywhere on your computer with just a few keystrokes. Whether it's email templates, code blocks, addresses, or emoji sequences, Snippets save you from typing the same things over and over. In v2, Snippets gain support for tagging and a new `{calculator}` [dynamic placeholder](https://manual.raycast.com/dynamic-placeholders).

[Snippets in Raycast (YouTube)](https://www.youtube.com/watch?v=1e8YeKe-0tU)

> [!TIP]
> Open Snippets by searching for "Search Snippets" or "Create Snippet" in [Root
> Search](/search-bar), or assign a hotkey for instant access.

## Creating a Snippet

To create a new Snippet:

1. Open Raycast and search for **Create Snippet**
2. Enter the text you want to save in the **Snippet Text** field. This can be plain text, formatted content, code, or any text you type repeatedly.
3. Give your Snippet a **Name** so you can find it later.
4. Optionally assign a **Keyword** to enable auto-expansion (see below).
5. Optionally add **Tags** to organize your Snippets into groups.
6. If you're in a Raycast team, choose an **Organization** to decide whether the Snippet is personal or shared with your organization.

> [!NOTE]
> Snippet text has a maximum length of 65K characters. This limit exists for performance reasons —
> in practice, most Snippets are well within this range.

## Keywords & Auto-Expansion

Keywords are the real power behind Snippets. When you assign a keyword to a Snippet, typing that keyword in any application automatically replaces it with the full Snippet text. This works everywhere: in your browser, code editor, email client, chat apps, and more.

### How Auto-Expansion Works

1. Assign a keyword to your Snippet (e.g., `!email`, `;;addr`, `/sig`)
2. Type the keyword in any text field on your computer
3. Raycast automatically replaces the keyword with your Snippet text

> [!TIP]
> Choose keywords that are unlikely to be typed accidentally. Prefixes like `!`, `;;`, or `//` work
> well. For example, `!thanks` is safer than just `thanks`.

### Auto-Expansion Settings

You can enable or disable auto-expansion globally in **Settings → Snippets**. When disabled, Snippets still work — you just need to search for them in Raycast and paste manually instead of using keyword triggers.

{/* TODO: add screenshot — apps/raycast/public/images/app/core-features/snippets/mac-snippets-autoexpansion-settings.png */}

### Keyword Character Reference

Not all characters can be used in keywords. Raycast uses certain characters as word-boundary delimiters, which means they will trigger expansion rather than become part of the keyword itself.

**Characters that cannot be used in keywords:**

- **Backtick**: `` ` ``
- **Quotation marks**: single quote `'`, double quote `"`, and their curly/smart variants `' ' " "`
- **Whitespace**: spaces, tabs, and newlines
- **Other delimiters**: some additional punctuation characters act as word boundaries and will trigger expansion instead of being included in the keyword

**Characters that can be used in keywords:**

- **Letters**: all Unicode letters (Latin, Cyrillic, CJK, etc.)
- **Numbers**: `0–9`
- **Hyphen & underscore**: `-` and `_`
- **Math symbols**: such as `+ = < >`
- **Currency symbols**: `$ € £ ¥` and others
- **Most punctuation**: including `! ; / . , @ # ~ &` (except the restricted characters listed above)

> [!TIP]
> Keywords like `!email`, `;;addr`, `/sig`, and `$price` are all valid. Keywords like `my email`
> (contains a space) or `it's` (contains an apostrophe) are not, because the space and quote act as
> delimiters.

## Searching & Managing Snippets

The **Search Snippets** command gives you a central view of all your Snippets. From here you can:

- Search by name, keyword, or content
- Filter by tag to quickly narrow down your collection
- Copy a Snippet to your clipboard
- Paste a Snippet directly into the active application
- Pin frequently used Snippets to the top of the list
- Edit, duplicate, or delete Snippets

## Dynamic Placeholders

Snippets support [Dynamic Placeholders](https://manual.raycast.com/dynamic-placeholders) — arguments that are replaced with dynamic data when the snippet is expanded. This lets you create context-aware Snippets that adapt every time you use them.

## Tags

Snippets now support tagging. Tags let you organize your Snippets into
logical groups — for example, by project, language, client, or purpose. You can assign one or more
tags when creating or editing a Snippet, and then filter by tag in the Search Snippets view to
quickly find what you need.

To add a tag:

1. Open the Snippet editor (create a new Snippet or edit an existing one)
2. Use the **Tags** field to assign one or more tags
3. Type a new tag name to create it, or select from existing tags

In the Search Snippets view, use the tag filter dropdown to show only Snippets with a specific tag. This makes it easy to manage large Snippet collections.

![Snippet editor in Raycast](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/basics/mac-snippets.png)

## Shared Snippets (Teams)

With Raycast for Teams, you can create shared Snippets that are available to everyone on your team. This is ideal for maintaining consistent messaging: support responses, company boilerplate, onboarding templates, and more.

Shared Snippets are managed from the same Search Snippets interface. They appear alongside your personal Snippets and can be filtered separately. Team admins can manage shared Snippets from the Raycast Teams dashboard.

## Importing Snippets

You can bring existing Snippets into Raycast from a file or from another text expansion tool. To import:

1. Open Raycast and run the **Import Snippets** command
2. Select your file
3. Review the Snippets to be imported, then confirm

### Supported File Format (JSON)

Raycast imports Snippets from a JSON file containing an array of snippet objects. Each object supports:

- `name` (required) — the Snippet's title
- `text` (required) — the content that gets inserted
- `keyword` (optional) — the trigger that expands the Snippet

Example:

```json
[
  {
    "name": "Personal Email",
    "text": "sherlock@gmail.com",
    "keyword": "@@"
  },
  {
    "name": "Home Address",
    "text": "221B Baker St., London"
  },
  {
    "name": "Catchphrase",
    "text": "Elementary, my dear Watson",
    "keyword": "!elementary"
  }
]
```

Save the file with a `.json` extension. If your file is greyed out and can't be selected in the import dialog, it isn't in a format Raycast recognizes — convert it to the JSON structure above.

### Importing from Other Tools

Raycast can also import from other text expansion tools such as TextExpander, aText, Espanso, and PhraseExpress. Export your Snippets from those apps, then select the exported file in **Import Snippets**.

## Use Cases & Examples

Here are some practical ways to use Snippets:

- **Email signatures**: Keyword `!sig` expands to your full signature with name, title, and contact info
- **Meeting notes template**: Keyword `!notes` expands to a structured template with `{date}` and `{cursor}` placeholders
- **Code snippets**: Keyword `;;log` expands to `console.log({cursor})`
- **Support replies**: Tag your customer support responses and quickly filter by client or issue type
- **Emoji combos**: Keyword `!shrug` expands to `¯\_(ツ)_/¯`

> [!TIP]
> Looking for more ideas? Browse [ray.so/snippets](https://ray.so/snippets/) for a curated
> collection of ready-to-use snippets to get you started.

## Settings

Open Settings (`⌘ ,`/`Ctrl ,`) and select **Snippets** from the sidebar to configure how Snippets expand. Use the toggle in the top-right corner to enable or disable the Snippets feature entirely.

### Snippet Expansion

- **Enable Snippet Expansion**: Master toggle for automatic keyword expansion. Turn it off if you want to keep your Snippets library but stop them from auto-expanding as you type.

![Snippet Expansion settings](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/core/mac-settings-snippets.png)

- **Expansion Mode**: Choose when a Snippet expands after you type its keyword:
  - **Immediately**: Inserts the text as soon as the keyword is matched.
  - **After Delimiter (keeping)**: Waits until you type a delimiter (e.g. space, punctuation), then expands and keeps the delimiter.
  - **After Delimiter (discarding)**: Waits for a delimiter, then expands and discards the delimiter from the output.

![Expansion Mode options](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/core/mac-settings-snippets-expansionmode.png)

- _(Only on Mac)_ **Expand within Words**: When toggled off, a Snippet only expands when
  its keyword is typed as a standalone word. Turn it on if you want keywords to also expand when
  they appear inside a larger word.
- **Override System Snippets**: When enabled (experimental), Raycast expands its Snippets before macOS's built-in System Snippets. When disabled, Raycast skips expansion for keywords that conflict with system ones to avoid double insertion.
- **Injection Delay**: Adds a delay before Raycast types the expanded text. This lets you type words that happen to contain a Snippet keyword without triggering expansion, and gives slower apps time to receive the input correctly. Options range from None and Short through Regular, Long, and Extra Long. Increase the delay if expansion is unreliable in specific apps.

![Injection Delay options](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/core/mac-settings-snippets-injectiondelay.png)

- **Response Time**: Controls how quickly Raycast processes clipboard entries during expansion. Options range from Instant and Quick through Default, Delayed, and Extended. Try a slower setting if you notice missing characters or partial expansion in specific applications.

![Response Time options](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/core/mac-settings-snippets-responsetime.png)

- **Completion Sound**: Optionally play a sound whenever a Snippet is expanded automatically. Useful as a confirmation cue, especially when using longer Snippets or dynamic placeholders like `{clipboard}` and `{date}`.
- **Disabled Applications**: Add applications where Snippet expansion should never run. 1Password and Keychain Access are included to prevent accidental expansion inside password fields. Click the **+** button to add more.

### Commands

Assign aliases and hotkeys to the Snippet commands you use most:

- **Create Snippet**: Open the Snippet editor
- **Export Snippets**: Save your Snippets to a file for backup or sharing
- **Import Snippets**: Import Snippets from a JSON file, TextExpander, aText, Espanso, or PhraseExpress
- **Search Snippets**: Find and insert a Snippet from the list

Set the **Primary Action** for Search Snippets (e.g. **Paste to Active App** or **Copy to Clipboard**) to match how you most often use your library.

![Snippet commands settings](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/core/mac-settings-snippets-command.png)

## Troubleshooting

If Snippets aren't working as expected, here are some common issues and steps to resolve them.

### My snippets from Raycast v1 aren't working after upgrading to v2

If snippets you created in v1 don't expand in v2, they likely weren't migrated. Run the `Migrate from Raycast v1` command in v2 (on a Mac with v1 installed, the first launch of v2 also prompts an automatic transfer). Make sure you're on Raycast for Mac v1.104.16 or newer before migrating.

Migration is additive, so it won't wipe your existing v2 setup.

If you're running both versions, only one should handle expansion. Open Raycast v1 → Settings → Extensions → Snippets and turn off **Enable Snippet Expansion** there, so v2 can expand snippets without the two conflicting. If snippets stopped working in v1 too, fully quit v2 and confirm only one version of Raycast is running.

### Snippets aren't expanding when I type the keyword

- Make sure snippet expansion in v1 is disabled. If you're running both versions, only one should
handle expansion. Open Raycast v1 → Settings → Extensions → Snippets and turn off **Enable Snippet
Expansion** there, so v2 can expand snippets without the two conflicting. If snippets stopped
working in v1 too, fully quit v2 and confirm only one version of Raycast is running. - Make sure
auto-expansion is enabled in **Settings → Snippets** (look for **Enable Snippet Expansion**). -
Check the **Expansion Mode**. If expansion is unreliable, try switching between **Immediately**
and **After Delimiter**. - If expansion is intermittent, increase the **Injection Delay**, and if
text comes through partially, try a slower **Response Time**. - _(Only on Mac)_ Check
that Raycast has Accessibility permissions enabled in **System Settings → Privacy & Security →
Accessibility**. - Verify your keyword doesn't contain invalid characters (see the Keyword
Character Reference above). Characters like quotes, backticks, and spaces will prevent the keyword
from working. - Some apps with custom text input fields (e.g., certain code editors, terminal
emulators, virtual machines, or Apple Mail) may not support auto-expansion. Try pasting the
Snippet manually from the Search Snippets command instead.

### Line breaks or rich text aren't preserved when a snippet expands

Snippets with hard returns or formatting can paste on a single line or lose styling, depending on
the target app. Confirm the line breaks are saved in the snippet itself (edit it in Search
Snippets), then try a different paste method or a slower Response Time in **Settings → Snippets**.
Some apps strip formatting on paste regardless.

### Snippet text is pasted incorrectly or partially

- If the expanded text appears
garbled or incomplete, the target app may be interfering with the paste operation. Try increasing
the paste delay or switching to a different paste method in Snippet settings. - Ensure your
Snippet text is within the 65,536 character limit.

### Snippet keyboard shortcuts (like Cmd+1 to Cmd+8) aren't working

If the quick keyboard shortcuts for inserting snippets don't fire, confirm you're on the latest
Raycast version, and check that no other app is bound to the same shortcut. Note which app you're
in when it fails, since these shortcuts depend on the frontmost app passing the key combination
through.

### Dynamic placeholders aren't being replaced

Double-check the placeholder syntax. Placeholders must use curly braces, e.g., `{date}`, `{clipboard}`. A typo in the placeholder name will cause it to be inserted as plain text. For formatted dates, include the format inside the braces, e.g., `{date: YYYY-MM-DD}`.

### Still having issues?

If none of the above resolves it, gather the following and send it to us via the **Send Feedback** command so we can investigate:

1. **Your OS version** and **Raycast version** (found in **Settings → About**).
2. **Steps to reproduce** the issue.
3. The **name and keyword** of the Snippet that isn't working.
4. The **app** where you're trying to use the Snippet (e.g., Chrome, VS Code, Slack, Notion).
5. Whether you **migrated from v1**, and whether v1 is fully quit.
6. **Your Raycast logs**: use the built-in **Copy Raycast Logs** command to copy your latest log files to the clipboard, or **Reveal Raycast Logs** to open your log folder.
7. **A screen recording** showing the issue in action.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Snippets. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
