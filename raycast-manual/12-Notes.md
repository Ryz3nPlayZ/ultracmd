> Source: https://manual.raycast.com/notes
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Notes

> Available on: Mac, Windows, iOS
> Tier: More with Pro

Capture and access quick notes directly in Raycast — synced across Mac, Windows, and iPhone so your thoughts are always within reach.

Raycast Notes makes it frictionless to organize your thoughts from anywhere on your Mac. You can track your todos, take notes during meetings, and save your next big idea. It's designed to be lightweight with Markdown support and is just a keystroke away with a deep integration into the rest of Raycast's ecosystem.

Our note-taking experience comes with three commands:

- **Raycast Notes:** This command simply toggles the Notes window.
- **Create Note:** This command creates a new note and opens the window. It's ideal to capture your thoughts with zero friction.
- **Search Notes:** This command allows you to search all your notes by title and content, making it easy to revisit previous notes.

> [!TIP]
>   We recommend assigning a hotkey to the Raycast Notes command for quicker access. A commonly used hotkey is `⌥ N`/`Alt N`.
>
> Type `Raycast Notes` into the main Raycast window, then choose Configure Command → Set Hotkey from the `⌘ K`/`Ctrl K` Action menu. Alternatively, set the hotkey from Settings → Raycast Notes.

## Creating

It all starts by creating a new note. It can be your next big idea or just a way to jot down some thoughts. If you have Raycast Notes already open, you can click the plus button in the top-right corner of the toolbar (or press `⌘ N`/`Ctrl N`) to create a new note.

Alternatively, you can use the Create Note command in [Raycast's Root Search](https://manual.raycast.com/search-bar), which is globally available. After you have successfully created a new note, you can start writing. The first line of the note is used as the title of the note, which is shown in the toolbar.

## Editing

Raycast Notes offers a lightweight editing experience that allows you to format your note with ease.

There are four ways to format your notes:

1. By typing Markdown syntax like creating a heading with `#`
2. By pressing keyboard shortcuts like `⌘ B`/`Ctrl B` to make text bold
3. By performing the Format action via the [Action Panel](https://manual.raycast.com/action-panel) (`⌘ K`/`Ctrl K`)
4. By activating the Format Bar on the bottom of the window

Below is an overview of all formatting options and their corresponding keyboard shortcut and Markdown syntax.

### Paragraph Formatting

Everything you need to organize your content into clear, structured sections - from headers and lists to specialized blocks that help keep your notes tidy and easy to navigate.

| Format       | macOS Shortcut        | Windows Shortcut             | Markdown Syntax                                                                                                        |
| ------------ | --------------------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| Heading 1    | `⌥ ⌘ 1` | `Ctrl Alt 1`   | Type `#` at the beginning of a new line                                                                                |
| Heading 2    | `⌥ ⌘ 2` | `Ctrl Alt 2`   | Type `##` at the beginning of a new line                                                                               |
| Heading 3    | `⌥ ⌘ 3` | `Ctrl Alt 3`   | Type `###` at the beginning of a new line                                                                              |
| Code block   | `⌥ ⌘ C` | `Ctrl Alt C`   | Type <code>```</code> (three backticks and a space) or `~~~` (three tildes and a space) at the beginning of a new line |
| Blockquote   | `⇧ ⌘ B` | `Ctrl Shift B` | Type `>` at the beginning of a new line                                                                                |
| Ordered list | `⇧ ⌘ 7` | `Ctrl Shift 7` | Type `1.` (or any other number followed by a dot) at the beginning of a new line                                       |
| Bullet list  | `⇧ ⌘ 8` | `Ctrl Shift 8` | Type `*` or `-` at the beginning of a new line                                                                         |
| Task list    | `⇧ ⌘ 9` | `Ctrl Shift 9` | Type `[ ]` for an unchecked task or `[x]` for a checked task at the beginning of a new line              |

To toggle a task’s checked state, place the cursor on the task line and press `⌘ Enter`/`Ctrl Enter`.

### Text Formatting

Basic styling options that let you modify the appearance of individual words or phrases within your text to emphasize important points, add links, or create distinctions.

| Format                      | macOS Shortcut        | Windows Shortcut             | Markdown Syntax                                                |
| ---------------------------- | --------------------- | ----------------------------- | -------------------------------------------------------------- |
| **Bold**                    | `⌘ B`   | `Ctrl B`       | Type `**two asterisks**` or `__two underlines__`               |
| _Italic_                    | `⌘ I`   | `Ctrl I`       | Type `*one asterisk*` or `_one underline_`                     |
| ~~Strikethrough~~           | `⇧ ⌘ S` | `Ctrl Shift S` | Type `~~two tildes~~`                                          |
| Underline                   | `⌘ U`   | `Ctrl U`       | N/A                                                            |
| `Code`                      | `⌘ E`   | `Ctrl E`       | Type `` `one backtick` ``                                      |
| [Link](https://raycast.com) | `⌘ L`   | `Ctrl L`       | Type `[link text in square brackets](https://manual.raycast.com/link-url-in-parentheses)` |

### Other Formatting

Additional formatting elements that help you enhance your notes with visual separators and expressive elements like emojis to improve readability and communication.

| Format          | macOS Shortcut | Windows Shortcut | Markdown Syntax                                                                                    |
| --------------- | -------------- | ----------------- | ---------------------------------------------------------------------------------------------------- |
| Emoji           | N/A            | N/A                | Type `:` to open the inline emoji picker                                                           |
| Horizontal rule | N/A            | N/A                | Type three dashes (`---`) or three underscores and a space (`___ `) at the beginning of a new line |

## Organizing

Raycast Notes offers support for multiple notes but balances it with a lightweight user interface. Only one note is visible at the time. Notes are organized as a stack. You can think of them as a notepad with multiple pages. To access previous notes, you can click the Browse Notes tool bar item in the top right or press `⌘ P`/`Ctrl P`.

Alternatively, you can use the Search Notes command in Raycast's Root Search. This is handy when you want to quickly open a note, such as a note for your 1:1 with your manager.

### Pinning

Some notes are more important than others and you want to revisit them on a regular basis. Those notes can be pinned to the top of the Search Notes command and the Browse Notes action. To pin a note, press `⇧ ⌘ P`/`Ctrl Shift P` (from the Search Notes window, it's `⌘ .`/`Ctrl .`).

Once a note is pinned, it can be accessed with `⌘ 0`/`Ctrl 0` through `⌘ 9`/`Ctrl 9` while you have the Notes window open. This is similar to how pinned tabs work in most browsers and should feel familiar.

### Navigating

Raycast Notes keeps your focus on a single note at a time. But sometimes you want to go back and forth between multiple notes. You can use the `⌘ [`/`Ctrl [` and `⌘ ]`/`Ctrl ]` keyboard shortcuts to navigate between previously opened notes. This is similar to how the navigation hierarchy works in most browsers.

> [!TIP]
> You can adjust the zoom level of the Notes content by using `⌘ -`/`Ctrl -` / `+` to zoom out or in, or `⌘ 0`/`Ctrl 0` to return to actual size, or in **Settings -> Raycast Notes -> Zoom**.

## FAQ

### Are Raycast Notes synced across devices?

Yes, Raycast Notes supports Cloud Sync as part of an [active Pro
subscription](https://www.raycast.com/pro). That means you can start a note on one device and
continue it on another.

### What is free and paid in Raycast Notes?

You can use Raycast Notes for free with up to 5 notes. If you want more notes, you need to
purchase a [Pro subscription](https://www.raycast.com/pro). The subscription also unlocks other
features such as Raycast AI, Cloud Sync, and custom themes.

### Can I open multiple notes at the same time?

Raycast Notes is a lightweight note-taking experience and keeps your focus on a single note.
However, our navigation and search experience allows you to quickly switch notes.

### What is the hotkey to check a task from the task list?

`⌘ ⏎`/`Ctrl Enter`

### Can I recover notes that I accidentally deleted?

Yes. Press `⌘ K`/`Ctrl K` in Raycast Notes and search for the `Show Recently
Deleted Notes` action to recover a recently deleted note.

### Are the keyboard shortcuts the same on macOS and Windows?

Mostly, yes. The Windows shortcuts use `Ctrl` in place of `⌘` and{" "}
`Alt` in place of `⌥`, with otherwise identical key combos. The one
exception worth noting is Strikethrough — on macOS you may need to disable Speech selection in
System Settings → Keyboard → Keyboard Shortcuts → Accessibility for `⇧ ⌘ S` to work;
on Windows there's no equivalent conflict.

## Troubleshooting

If Notes isn't working as expected, here are some common issues and steps to resolve them.

### My notes aren't syncing between devices

- Notes sync through [Cloud Sync](https://manual.raycast.com/cloud-sync), which requires a signed-in Raycast Pro account with the **Raycast Notes** category turned on in **Settings → Cloud Sync → Synced Content**.
- v1 and iOS devices sync through legacy Cloud Sync and appear as a single **Legacy Raycast & iOS Devices** entry, so bridging notes between a v1 device and a v2 device can lag behind syncing between two v2 devices.
- Still stuck? See [Cloud Sync Troubleshooting](https://manual.raycast.com/cloud-sync#troubleshooting) for more.

### I'm on Pro but don't see Unlimited Notes

- Open **Settings → Account** to confirm your current plan. Pro includes
  Unlimited Raycast Notes (alongside Raycast AI, Translator, and more).
- Make sure you're signed into the same account on every device.
- If you subscribed on iOS, the subscription is managed from the iOS app /
  App Store.

### ⌘N doesn't create a new note

- Make sure the Notes window is actually focused when you press the shortcut
  — otherwise the keypress goes to the previously active app.
- Check for a conflicting global hotkey, especially one using a directional
  modifier (e.g. right-`⌘` + `N`).

### Raycast Notes appears on its own, or I can't hide it while screen sharing

These are known limitations the team is actively working on. Hiding Raycast
Notes from screen sharing isn't available yet, and unexpected appearances are
being investigated. If you hit this, please report it with the details below
so we can reproduce it.

### Still having issues?

If none of the above resolves it, gather the following and send it to us via the **Send Feedback** command (or **Share Feedback** in the iOS app) so we can investigate:

1. **Your OS version** and **Raycast version** (found in **Settings
   → About**).
2. **Steps to reproduce** the issue.
3. **Your Raycast logs**: use the built-in **Copy Raycast Logs** command to
   copy your latest log files to the clipboard, or **Reveal Raycast Logs**
   to open your log folder.
4. **A screen recording** showing the issue in action.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Notes. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
