> Source: https://manual.raycast.com/window-management
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Window Management

> Available on: Mac, Windows
> Tier: More with Pro

Manage your windows without third-party tools. Raycast's built-in window management lets you split, tile, center, resize, and save layouts across any monitor setup.

Raycast lets you resize, organize, and move the focused window from your keyboard.

[Window Management in Raycast (YouTube)](https://www.youtube.com/watch?v=Ei1RIZCrZN8)

## Commands

Give your workspace a refresh and reorganize windows instantly:

- _(Only on Mac)_ **Toggle Fullscreen:** Toggles the focused window to fullscreen.
- **Maximize:** Expands the focused window to fill the whole screen.
- **Maximize Height:** Maximizes the window’s height.
- **Maximize Width:** Maximizes the window’s width.
- **Left/Right/Bottom/Top Half:** Moves the focused window to occupy half of the screen in any direction — perfect for comparing two documents.
- **Center:** Centers the focused window on the screen, maintaining its size.
- **Move Up/Down/Left/Right:** Moves the focused window to any screen edge.
- **Move Window:** Moves the focused window to an exact position you type, such as `100,100`.
- **Restore:** Restores the window to its previous size and position.
- **Reasonable Size:** Resizes the window to 60% of the screen (up to 1025x900px).
- **Resize Window:** Resizes the focused window to an exact size you type, such as `1920x1080`.
- **Move to Previous/Next Display:** For multi-monitor setups, quickly move windows between screens.
- _(Only on Mac)_ **Move to Previous/Next Space:** Move windows between different macOS Spaces.
- **First, First Two, Center, Last Two, Last Third:** Resize and place the window to occupy a third of the screen.
- **First, Second, Third, Last Fourth:** Move the window to one-fourth of the screen.
- **Top Left/Top Right, Bottom Left/Bottom Right Quarter:** Position the window in any quarter of the screen.
- **Top Left/Top Center/Top Right Sixth:** Align and size the window into a sixth at the top of the screen.
- **Bottom Left/Center/Right Sixth:** Align and size the window into a sixth at the bottom of the screen.
- _(Only on Windows)_ **Open Desktop 1…9:** Opens a new or switches to an existing virtual desktop by number.
- _(Only on Windows)_ **Close Desktop 1...9:** Closes a specified desktop.
- _(Only on Windows)_ **Close Desktop Active:** Closes the current virtual desktop.
- _(Only on Windows)_ **Rename Desktop 1…9:** Label a specific desktop for easy reference.
- _(Only on Windows)_ **Rename Desktop Active:** Label your current desktop.
- _(Only on Windows)_ **Move to Desktop 1…9:** Move your active window to a specified virtual desktop.

> [!TIP]
> Assign a Hotkey to the window management commands you use often. For example, set a Hotkey for **Left Half** to position and resize the focused window.

### Exact Sizes and Positions

**Resize Window** and **Move Window** take the numbers you type instead of a share of the screen, which is what you want when a window has to be a specific resolution — for a recording, a screenshot, or a demo.

Type a size as `1920x1080` or a position as `100,100`.

## Settings

Tailor your workspace:

- Adjust the gap between windows, or between windows and the edge of your desktop.
- Set **Left Half** and **Right Half** commands to cycle through different window sizes or even move between screens.

### macOS

- **Respect Stage Manager:** Enable this option to ensure window management commands leave space for Stage Manager, letting you see your other open apps.
- **Presets:** Instantly apply hotkeys from other popular window management apps.
- **System Spaces Shortcuts:** Override macOS’s system keyboard shortcuts to control Raycast Window Management instead.

### Windows

- **Auto Close Empty Desktops:** Virtual desktops are closed automatically when nothing is on them.

## Custom Commands

### Create Command

Set up personalized window commands by customizing window size, pinned position, and offsets with **Create Command**—using absolute values (points) or percentages (relative to display size).

> [!TIP]
> The **Offset** **X** and **Y** fields accept negative percentages, so you can shift a window left or up. A relative offset can be anywhere from −100% to +100% of the display's width or height. Sizes still can't be negative.

### Create Layout

Go beyond single-window commands. With **Create Layout**, arrange multiple app windows on any display — up to eight windows per display — each with its own size, offset, and position.

Every entry in a layout can also tell its app what to open, using the **Argument** dropdown:

- **Quicklink:** One of your [Quicklinks](https://manual.raycast.com/quicklinks).
- **File or Folder:** A path on your machine.
- **URL:** A link for the app to open.
- **Command Line Arguments:** The arguments Raycast passes to the app when it opens it.

_(Only on Windows)_ When a layout places windows into adjacent tiled regions — two halves side by side, for example — Raycast arranges them the way Windows' own snapping does, so their shared edge gets a divider you can drag to resize both windows at once.

### Create Layout from Current Windows

Already have everything where you want it? **Create Layout from Current Windows** turns the current arrangement into a layout: Raycast reads the windows on screen and opens the layout editor with a draft already filled in, so you only adjust what you want to change before saving.

To pick up the current arrangement in a layout you're already editing, choose **Add Visible Windows** from the plus button menu in the layout editor.

### Duplicate a Command or Layout

**Duplicate Command** uses a built-in command's layout as the starting point for a custom one. Find it in the [Action Panel](https://manual.raycast.com/action-panel) in [Root Search](https://manual.raycast.com/search-bar), or in ellipsis menu on the command's row in **Settings → Window Management**.

Nothing is saved right away: Raycast opens the **Create Command** form pre-filled with the built-in's position, size, and offset. Your own custom commands and layouts duplicate the same way. Only built-ins with a fixed layout can be duplicated, so commands that depend on the current window or your displays have no Duplicate action.

### Deeplinks

Custom commands support *Deeplinks*, which can be used outside Raycast. Create links with absolute or relative window values, for example:

```jsx
raycast://customWindowManagementCommand?&name=MyCommand&position=center&absoluteWidth=500.0&relativeHeight=0.5&absoluteXOffset=0.0&absoluteYOffset=0.0
```

| Argument           | Description                                                                                                                                         | Required |
|--------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| `name`             | Command name. If a matching custom single-window command is found, other arguments are ignored. No name means Raycast creates a temporary command.   | No       |
| `position`         | Pin window to this position. If omitted (with a temporary command), defaults to top left.                                                           | No       |
| `absoluteWidth`    | Width in points.                                                                                                                                   | No       |
| `relativeWidth`    | Width as a % of the screen width. Ignored if absolute width is set.                                                                                | No       |
| `absoluteHeight`   | Height in points.                                                                                                                                  | No       |
| `relativeHeight`   | Height as a % of the screen height. Ignored if absolute height is set.                                                                             | No       |
| `absoluteXOffset`  | Horizontal offset in points.                                                                                                                       | No       |
| `relativeXOffset`  | Horizontal offset as a % of the screen width. Ignored if absolute x offset is set.                                                                 | No       |
| `absoluteYOffset`  | Vertical offset in points.                                                                                                                         | No       |
| `relativeYOffset`  | Vertical offset as a % of the screen height. Ignored if absolute y offset is set.                                                                  | No       |

To create a one-time Deeplink, omit the `name`—Raycast generates a temporary command that positions or resizes the window on the fly.

For Window Layout Deeplinks, only the `name` argument is supported, so only existing window layouts can be used.

### Additional Notes

- Custom commands don't support window gaps.
- With Stage Manager enabled, using Window Layout only shows the top window; as a workaround, group the apps (hold `Shift`) before applying the layout, to keep all windows visible.

## Permissions
_(Only on Mac)_

Window Management needs Accessibility access to move and resize windows. Grant it in **System Settings → Privacy & Security → Accessibility**. The first time you use a command, Raycast prompts you to enable it if the permission is missing.

## Troubleshooting

Window Management lets you resize and position windows with commands and hotkeys. Most issues come down to macOS permissions or hotkeys not firing. Here are the common ones.

### Window commands do nothing

Window Management needs Accessibility permission. Open **System Settings → Privacy & Security → Accessibility** and make sure Raycast is enabled. If it's already listed, toggle it off and on, then restart Raycast.

### A window-management hotkey isn't firing

Another app or a macOS shortcut may be bound to the same combination. Check for conflicts, and confirm the hotkey is set in **Settings → Window Management**. If the key is an fn/Globe or function key (F1–F12) and doesn't register, disable "Use F1, F2, etc. keys as standard function keys" in **System Settings → Keyboard → Keyboard Shortcuts → Function Keys**.

### Windows snap to the wrong screen or size on a multi-monitor setup

Positioning is relative to the display the window is currently on. Move the window to the target display first, then run the command. For mixed-resolution or scaled displays, results can differ between screens, so set the hotkey on the screen you use most.

### Some apps ignore resize or position commands

A few apps don't expose standard window controls to macOS (some Electron apps, full-screen apps, and apps in native full-screen mode). Take the app out of full-screen first. If it still won't resize, it likely isn't reporting a resizable window to the system.

### Still having issues?

If none of the above resolves it, gather the following and send it to us via the **Send Feedback** command so we can investigate:

1. **Your OS version** and **Raycast version** (found in **Settings → About**).
2. **Steps to reproduce** the issue.
3. The **app** and the **command or hotkey** involved.
4. Your **monitor setup**.
5. **Your Raycast logs**: use the built-in **Copy Raycast Logs** command to copy your latest log files to the clipboard, or **Reveal Raycast Logs** to open your log folder.
6. **A screen recording** showing the issue in action.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Window Management. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
