> Source: https://manual.raycast.com/action-panel
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Action Panel

> Available on: Mac, Windows

The Action Panel surfaces every contextual action for the selected item in Raycast — open the Actopm Panel to discover, learn, and trigger actions right from your fingertips.

The Action Panel is one of Raycast's most powerful features. It lets you discover and execute actions on any selected item with just a few keystrokes, no mouse needed. Every item in Raycast, whether it's an application, a command, a file, or a calendar event, has an Action Panel with contextual actions tailored to it.

## Opening the Action Panel

There are two ways to interact with actions:

- `⌘ K`/`Ctrl K`: Opens the full Action Panel, showing all available actions for the selected item. This is the best way to explore what you can do.
- `↵`: Triggers the **primary action** immediately (the first action in the list). For apps, this launches them. For commands, this runs them.
- `⌘ ↵`/`Ctrl ↵`: Submits form data when you're in a form view.
- `Esc`: Closes the Action Panel or navigates back from a submenu.

> [!TIP]
> Make it a habit to press `⌘ K`/`Ctrl K` whenever you're unsure what actions are available. Each action shows its keyboard shortcut on the right, so you can learn to trigger them directly over time.

## How the Action Panel is Organized

Actions are grouped into logical **sections** to make them easy to find. Each section groups related actions together. The exact sections depend on the item you've selected, but here's the typical layout:

### Primary Action

The first action in the Action Panel is the **primary action**. It's displayed prominently at the top and is the action that runs when you press `↵` without opening the panel. For example:

- For an **application**, the primary action is "Open".
- For a **command**, the primary action is "Run Command".
- For a **file**, the primary action is "Open" or "Open With…".

### Action Sections

Below the primary action, you'll find additional sections. Common ones include:

- **Favorites**: Add/remove from favorites, reorder favorites.
- **Configure**: Open command settings, set hotkey, set alias, configure extension.
- **Deeplink**: Copy a direct link to the command.
- **Manage**: Disable command, reset ranking.

## Searching for Actions

When the Action Panel is open, you'll see a search field at the top with the placeholder *"Search for actions…"*. Start typing to filter actions by name in real-time using fuzzy matching. This is especially useful when an extension provides many actions and you want to jump to a specific one quickly.

When searching, all matching actions are shown in a single flat list regardless of their original sections.

## Sub-menus

> [!NOTE]
> Actions can now open sub-menus and custom views.

Some actions don't execute immediately. They open a **sub-menu** with additional options. For example, "Configure Command" opens a sub-menu where you can set a hotkey, set an alias, open settings, or delete existing configurations.

Some sub-menu items open **custom views** directly inside the Action Panel. For instance, "Set Hotkey" opens an inline keyboard shortcut recorder where you can press your desired key combination and save it, all without leaving the Action Panel.

Press `Esc` to go back from a sub-menu to the main Action Panel.

## Configuring Commands from the Action Panel

> [!NOTE]
> You can now assign hotkeys and aliases directly from Root Search without going to Settings.

Select any command in Root Search and open the Action Panel. Under the **Configure Command** section, you'll find:

### Set Hotkey

Opens an inline keyboard shortcut recorder. Press the key combination you want to assign, then confirm with `↵`. The recorder shows:

- The command name and icon for context
- A "Press keys to assign" prompt
- The currently assigned hotkey (if one exists)
- A clear button to remove the existing hotkey

### Set Alias

Opens a text input field where you can type a short keyword as an alias for the command. Once set, typing that alias in Root Search will prioritize the command in results.

### Other Configure Options

- **Open Command Settings**: Opens the full settings page for the command.
- **Configure Extension**: Opens the extension's settings page.
- **Delete Hotkey / Delete Alias**: Removes the assigned hotkey or alias (only visible when one is set).

## Common Actions Reference

Here are the common actions you'll find across most items in Root Search:

### Favorites

- **Add to Favorites** (`⌘ F`/`Ctrl F`): Pin the item so it always appears at the top of Root Search.
- **Remove from Favorites**: Unpin a previously favorited item.
- **Move Favorite Up / Down** (`⌘ ↑`/`Ctrl ↑` / `⌘ ↓`/`Ctrl ↓`): Reorder your favorites.

### Configuration

- **Configure Command** (`⇧ ⌘ ,`/`Ctrl Shift ,`): Opens a sub-menu with Set Hotkey, Set Alias, and settings options.
- **Configure Extension** (`⇧ ⌘ ,`/`Ctrl Shift ,`): Opens extension-level settings.
- **Disable Command** (`⇧ ⌘ D`/`Ctrl Shift D`): Hides the command from Root Search results. You can re-enable it from the extension settings.

### Deeplinks & Sharing

- **Copy Deeplink**: Copies a direct URL to the command to your clipboard. Useful for sharing workflows, creating automation triggers, or adding to documentation.

### Managing Commands

- **Reset Ranking**: Clears learned frecency data and search terms for a command, resetting it to its default position. Useful if a command appears too high or too low in your results.

## Actions by Item Type

The Action Panel adapts to the type of item you've selected. In addition to the common actions above, here are some examples of what you'll see for specific item types:

- **Applications**: Open, Show in Finder, Uninstall (if supported), Hide/Unhide from Root Search.
- **Files & Directories**: Open, Open With…, Show in Finder, Copy Path, Move to Trash.
- **Calendar Events**: Open in Calendar, Join Meeting (if a link is available), Copy Event Details.
- **Extension Commands**: Run Command, plus any custom actions defined by the extension developer.

The best way to discover what's available is to press `⌘ K`/`Ctrl K` on any item and explore.

## Extension-Defined Actions

When you're inside an extension command (not Root Search), the Action Panel shows actions defined by the extension developer. These can include anything the extension needs: copying values, opening URLs, navigating between views, running scripts, and more.

Extension developers can:

- Define custom actions with icons, titles, and keyboard shortcuts.
- Organize actions into named sections.
- Create sub-menus for complex action hierarchies.
- Mark actions as **destructive** (shown in red) to warn users before irreversible operations.

## Keyboard Shortcuts

- `↵`: Run primary action
- `⌘ K`/`Ctrl K`: Open Action Panel
- `⌘ ↵`/`Ctrl ↵`: Submit form
- `Esc`: Close panel / go back
- `⇧ ⌘ F`/`Ctrl Shift F`: Add to Favorites
- `⇧ ⌘ ,`/`Ctrl Shift ,`: Configure Command
- `⌥ ⌘ ,`/`Ctrl Alt ,`: Configure Extension
- `⌃ ⇧ ⌘ D`/`Ctrl Alt Shift D`: Disable Command


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Action Panel. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
