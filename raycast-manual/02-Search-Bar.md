> Source: https://manual.raycast.com/search-bar
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Search Bar

> Available on: Mac, Windows

The Raycast Search Bar and Root Search are where everything starts — search apps, files, commands, and extensions, then trigger actions with a press of a key.

The **Search Bar** is the single input at the top of the Raycast window, where everything starts. Type into it and Raycast searches across your Mac and extensions in real time.

**Root Search** is the list of results shown below the Search Bar when no command is open. It's Raycast's home screen and the entry point to everything you can do.

## Compact Mode

When Compact Mode is enabled, the Raycast window collapses to show only the search bar when the search term is empty. The full results list expands as soon as you start typing or open the Action Panel. The window automatically collapses again when it loses focus.

You can enable Compact Mode in **Settings → General → Appearance → Window Mode**.

## Action Panel

Every item in Root Search has an Action Panel (opened with `⌘ K`/`Ctrl K` or `Enter` on some items). The available actions vary by item type, but common actions include:

- **Add/Remove from Favorites**: Pin items for quick access.
- **Assign Hotkey**: Set a keyboard shortcut to launch a command directly.
- **Assign Alias**: Set a short keyword to quickly access a command. 
- **Copy Deeplink**: Copy a direct link to the command for sharing or automation.
- **Disable Command**: Hide a command from Root Search results.
- **Reset Ranking**: Clear the frecency data for a command, resetting it to its default position in results.

## Launch Apps

Raycast is a fast way to open any application installed on your system, no hunting through the Dock, Launchpad, or Start menu. Just open Raycast and start typing.

Hit your Raycast hotkey to focus the Search Bar, type the name of the app you want, and press `Enter` with it highlighted to launch it. Fuzzy search means you don't need an exact match, typing `msg` finds Messages, `slk` finds Slack.

> [!TIP]
> Pin the apps you use most as Favorites so they appear at the top of Root Search without typing. Open the Action Panel (`⌘ K`/`Ctrl K`) and choose **Add to Favorites**.

## URL Detection

Raycast automatically detects when you type a valid URL into the search bar. When a URL is recognized, commands that can handle URLs (like web browsers and search commands) are surfaced. If you type a domain without a scheme, Raycast infers `https://` automatically.

## File Navigation in Root Search

Files and directories are now integrated directly into Root Search.

When File Search indexing is enabled, files and directories appear directly in Root Search results, so you can find and act on them without leaving the search bar:

- `Shift Tab`: Navigate to the parent directory.

Recently used files also appear in the empty-search view, so you can quickly access files you've been working with.

## Command Arguments

Some commands accept arguments (up to 3). When you select a command that has arguments, input fields appear right in the search bar area. Fill them in and press `Enter` to run the command with those parameters.

Navigate between argument fields with the `Left` and `Right` arrow keys. Arguments can be text, password, or dropdown types.

## Search Contacts
_(Only on Mac)_
Use the **Search Contacts** command to find people from your Apple Contacts directly in Raycast. Open the command and start typing a name to filter your contacts in real time.
Once a contact is selected, use the Action Panel (`⌘ K`) to act on it: copy details, open in Contacts, etc. Make sure you enabled the Contact application in **Settings → Applications → Applications → Contacts**.

> [!TIP]
> Assign an alias or hotkey to **Search Contacts** so you can launch it straight from the Search Bar.

## How Ranking Works

Root Search learns from you. The more often, and the more recently, you pick a result for a given query, the higher it ranks the next time you type the same thing.

> [!TIP]
> If two apps match what you type (say, `cal` could be Calendar or Calculator), Raycast notices which one you usually pick and starts surfacing that one first. Open the same app a handful of times via Root Search and it starts appearing at the top for shorter and shorter queries.

Ranking priority (from highest to lowest):

1. Exact alias match
2. Alias prefix match
3. Title fuzzy match score
4. Subtitle and keyword matches
5. Frecency (a blend of frequency and recency) score

If results feel out of order, you can use **Reset Ranking** from the Action Panel to clear learned behavior for a specific command.

## What You Can Search For

Root Search surfaces a wide variety of items from across Raycast and your system. Here's everything you can find:

- **Applications**: All installed applications on your system. On macOS this includes symlinked apps; on Windows it covers Start Menu and desktop apps.
- **Commands**: Built-in Raycast commands and commands from installed extensions.
- **Files & Directories**: Indexed files and folders from your system. Recently used files appear when the search bar is empty.
- **Calendar Events**: Upcoming events for today appear at the top when the search bar is empty (requires calendar permissions).
- _(Only on Mac)_ **Search Contacts**: Find people from your Apple Contacts directly in Raycast.
- **Calculator**: Type a math expression (like `128 * 3.5`) and get instant results right in the search bar.
- **Quicklinks**: Saved quick links to URLs, files, or folders.
- **AI Commands**: AI-powered commands and built-in AI prompts.
- **Script Commands**: Custom scripts you've set up.
- **Settings**: Raycast preferences and extension settings.
- _(Only on Windows)_ **Windows Settings**: Every individual setting from the Windows settings catalog and Control Panel tasks.
- **Web URLs**: Type a valid URL and Raycast detects it, offering actions like opening it in your browser.
- **Color Conversion**: type or paste any supported color value (e.g. `#FF6B35`, `rgb(255 107 53)`, `hsl(16 100% 60%)`, `oklch(0.7 0.18 40)`) in Root Search to see an instant visual preview, then copy it in the format you need.

> [!NOTE]
> Check the Search Bar placeholder text, it tells you what you can search for in the current context.

### Search Sensitivity

You can adjust how strict the fuzzy search algorithm is in **Settings → Launcher → Root Search Sensitivity**. There are three levels:

- **High**: Requires more precise input. Best if you find too many irrelevant results.
- **Medium** (default): Balanced sensitivity for most users.
- **Low**: Returns broader results for any elements containing the typed letters. Best if you want maximum flexibility.

## Favorites

Pin any command, application, or item as a **Favorite** to keep it at the top of Root Search when the search bar is empty.

- **Add to Favorites**: Open the Action Panel (`⌘ K`/`Ctrl K`) on any item and select "Add to Favorites".
- **Reorder Favorites**: Use "Move Favorite Up" or "Move Favorite Down" in the Action Panel to change the order.
- **Remove from Favorites**: Open the Action Panel on a favorited item and select "Remove from Favorites".

Favorites appear in a dedicated section above all other results, making your most-used items always just one keystroke away.

## Aliases

Aliases are short, custom keywords you can assign to any command for quick access. For example, you could set `gc` as an alias for "Google Chrome".

- When you type an alias that exactly matches a command, that command is prioritized in results.
- Aliases appear as a tag next to the command name in the results list.
- If a command has arguments, typing the alias followed by a space will automatically focus the first argument field.

You can assign aliases from the Action Panel in Root Search or from extension settings.

## Settings

You can customize Root Search behavior from **Settings**:

- **Settings → Launcher → Root Search Sensitivity**: Adjust fuzzy search strictness (Low / Medium / High).
- **Settings → General → Appearance → Window Mode**: Switch between standard and compact mode.
- **Settings → Launcher → Pop to Root Search**: How long before Raycast returns to Root Search when inactive.
- **Settings → File Search → Include Files in Root Search**: File Search Extension Settings: Configure whether files appear in Root Search, which directories to index, hidden files visibility, and ignore patterns.
- **Settings → Calculator → Color Conversion**: Enable to surface color results in Root Search. Detected colors can be copied in any supported format, including hex, rgb, hsl, oklch and other modern color spaces, plus NSColor and UIColor for Swift.

The Search Bar is the central hub of Raycast. It's focused by default whenever you open the app, so you can start typing immediately to find what you need. Whether it's an application, a command, a file, a calendar event, or a quicklink, everything is reachable from a single search.

> [!NOTE]
> Open Raycast with `⌘ Space`/`Ctrl Space`. You can customize this shortcut in Settings (`⌘ ,`/`Ctrl ,`).

## Permissions

Some Root Search results rely on system access:

- **Calendar Events** needs calendar access to show your upcoming events. _(Only on Mac)_ Grant it in **System Settings → Privacy & Security → Calendars**.
- _(Only on Mac)_ **Search Contacts** needs contacts access. Grant it in **System Settings → Privacy & Security → Contacts**.

Raycast prompts for access the first time you use these features.

## Keyboard Shortcuts

Raycast is built for keyboard-first workflows. Here are the most useful shortcuts for navigating the Search Bar.
### Navigation

    - `↑` / `↓`: Move up / down through results
    - `⌘ ↑`/`Ctrl ↑` / `⌘ ↓`/`Ctrl ↓`: Jump to previous / next section
    - `⌥ ↑`/`Alt ↑` / `⌥ ↓`/`Alt ↓`: Jump to previous / next page of results
    - `Enter`: Run the selected item (primary action)
    - `⌘ Enter`/`Ctrl Enter`: Run the secondary action

### Search Bar

    - `Escape`: Clear search text, or close Raycast if already empty
    - `Backspace` (when search is empty): Navigate back
    - `⌘ K`/`Ctrl K`: Open the Action Panel for the selected item
    - `⌘ ,`/`Ctrl ,`: Open **Settings**


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Search Bar. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
