> Source: https://manual.raycast.com/keyboard-shortcuts
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Keyboard Shortcuts

> Available on: Mac, Windows

Explore the Raycast keyboard shortcut on Mac and Windows. Learn how to launch commands, navigate search, trigger actions, manage windows, and streamline your workflow with speed.

Raycast is built to be driven entirely from the keyboard. This page lists all the keyboard shortcuts available across the app. Learning even a few of these will significantly speed up your workflow.

> [!TIP]
> On macOS, Raycast uses `⌘` (Cmd) as the primary modifier. You can also enable Emacs-style or Vim-style navigation bindings in Settings.

## Global Shortcuts

These shortcuts work from anywhere on your system, even when Raycast isn't in focus.

- `⌘ Space`/`Alt Space`: Open or close Raycast (default, can be customized).

You can also assign custom global hotkeys to any command. See the **Command Aliases & Hotkeys** page for details.

## General Navigation

These shortcuts work across most views in Raycast.

- `Esc`: Go back to the previous view. From Root Search, closes the Raycast window.
- `⌘ Esc` (Mac) / `⇧ Esc` (Windows): Pop to Root.
- `⌘ W`/`Ctrl W`: Close the Raycast window.
- `⌘ ,`/`Ctrl ,`: Open **Settings**.
- `⇧ ⌘ /`/`Ctrl Shift /`: Open the User Guide.

## List Navigation

These work in any list view: Root Search, extension results, Action Panel, etc.

- `↑ ↓`: Move up and down in the list.
- `⌥ ↑`/`Alt ↑` / `⌥ ↓`/`Alt ↓`: Jump to the previous or next page of results.
- `⌘ ↑`/`Ctrl ↑` / `⌘ ↓`/`Ctrl ↓`: Jump to the previous or next section.
- `Ctrl N` / `Ctrl P`: Move down / up (Emacs-style, enabled by default).

> [!NOTE]
> Pagination keys can be changed in **Settings → Keyboard → Page Navigation Keys**.

## Root Search

These shortcuts work in Raycast's main search.

- `↵`: Run the primary action.
- `⌘ K`/`Ctrl K`: Open the Action Panel.
- `⇧ Tab`: Navigate to parent directory.
- `↑` / `↓` (at top/bottom of list): Cycle through search history.
- `⌘ F`/`Ctrl F`: Add the selected item to Favorites.
- `⇧ ⌘ ↑`/`Ctrl Shift ↑` / `⇧ ⌘ ↓`/`Ctrl Shift ↓`: Move a favorite item up or down.
- `⌘ ,`/`Ctrl ,`: Configure Command.
- `⇧ ⌘ ,`/`Ctrl Shift ,`: Configure Extension.
- `⇧ ⌘ D`/`Ctrl Shift D`: Disable Command.

## Action Panel

These shortcuts work inside the Action Panel.

- `⌘ K`/`Ctrl K`: Open or close the Action Panel.
- `↵`: Execute the selected action.
- `⌘ ↵`/`Ctrl ↵`: Execute the secondary action.
- `⇧ ⌘ ↵`/`Ctrl Shift ↵`: Execute the tertiary action.
- `Esc`: Close the Action Panel or go back from a sub-menu.
- Type to search: Filter actions by name when the panel is open.

## Common Item Actions

These shortcuts work on selected items across most views. Not all actions are available for every item type.

- `⌘ O`/`Ctrl O`: Open item.
- `⇧ ⌘ O`/`Ctrl Shift O`: Reveal in Finder / File Explorer.
- `⌥ ⌘ O`/`Ctrl Alt O`: Open With…
- `⌘ Y`/`Ctrl Y`: Toggle Quick Look preview.
- `⌘ E`/`Ctrl E`: Edit item.
- `⌘ I`/`Ctrl I`: Show info / details.
- `⌘ D`/`Ctrl D`: Duplicate item.
- `⌘ .`/`Ctrl .`: Pin or unpin item.
- `⇧ ⌘ .`/`Ctrl Shift .`: Show hidden items.

### Copy & Paste

- `⌘ C`/`Ctrl C`: Copy.
- `⇧ ⌘ C`/`Ctrl Shift C`: Copy (secondary, e.g. copy deeplink).
- `⌘ V`/`Ctrl V`: Paste.
- `⇧ ⌘ V`/`Ctrl Shift V`: Paste (secondary).

### Delete

- `Ctrl X`: Delete selected item.
- `Ctrl Shift X`: Delete all.

## AI Chat

AI Chat has a full set of dedicated keyboard shortcuts.

### Chat Navigation

- `⇧ ⌘ S`/`Ctrl Shift S` or `⌘ B`/`Ctrl B`: Toggle chat history sidebar.
- `⇧ ⌘ F`/`Ctrl Shift F`: Search chats.
- `⌘ J`/`Ctrl J`: Send selected item to AI Chat (from other views).

### Composer & Messages

- `⇧ ⌘ A`/`Ctrl Shift A`: Add attachment to composer.
- `⇧ ⌘ B`/`Ctrl Shift B`: Branch chat from a message.

### Model & Settings

- `⇧ ⌘ M`/`Ctrl Shift M`: Change AI model.
- `⇧ ⌘ Y`/`Ctrl Shift Y`: Change creativity level.
- `⇧ ⌘ U`/`Ctrl Shift U`: Change reasoning effort.

### Chat Management

- `⌥ ⌘ A`/`Ctrl Alt A`: Archive chat.
- `⌃ ⌘ N`/`Alt Shift N`: Create folder.
- `⌃ ⌘ M`/`Alt Shift M`: Move to folder.

### Feedback

- `⇧ ⌘ =`/`Ctrl Shift =`: Upvote / Good response.
- `⇧ ⌘ -`/`Ctrl Shift -`: Downvote / Bad response.

## Forms

These shortcuts work inside Raycast forms.

- `⌘ ↵`/`Ctrl ↵`: Submit the form.
- `Tab`: Move to the next field.
- `⇧ Tab`: Move to the previous field.
- `Esc`: Cancel and go back.

## Text Editing

Standard text editing shortcuts work in all text fields.

- `⌘ A`/`Ctrl A`: Select all.
- `⌘ C`/`Ctrl C`: Copy.
- `⌘ X`/`Ctrl X`: Cut.
- `⌘ V`/`Ctrl V`: Paste.
- `⌘ Z`/`Ctrl Z`: Undo.
- `⇧ ⌘ Z`/`Ctrl Shift Z`: Redo.

## Alternative Navigation Bindings

Raycast supports alternative navigation styles that you can enable in Settings. These provide familiar keybindings for users coming from terminal editors.

### Emacs Bindings (enabled by default)

- `Ctrl N`: Move down.
- `Ctrl P`: Move up.
- `Ctrl F`: Move right.
- `Ctrl B`: Move left.

### Vim Bindings (optional)

- `Ctrl J`: Move down.
- `Ctrl K`: Move up.
- `Ctrl L`: Move right.
- `Ctrl H`: Move left.

You can switch navigation bindings in **Settings → Keyboard → Navigation Bindings**.

## Extensions Support & Feedback

These shortcuts open extension support and feedback options.

- `⇧ ⌘ B`/`Ctrl Shift B`: Report a bug.
- `⌥ ⌘ F`/`Ctrl Alt F`: Request a feature.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Keyboard Shortcuts. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
