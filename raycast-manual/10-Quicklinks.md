> Source: https://manual.raycast.com/quicklinks
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Quicklinks

> Available on: Mac, Windows, iOS

Turn any URL into a keyboard shortcut with Raycast Quicklinks — open sites, trigger searches, and jump to deep links across all your devices.

Quicklinks turn the places you open every day into fast, searchable shortcuts. Save a website, search URL, file path, folder, or deeplink, then open it from [Root Search](https://manual.raycast.com/search-bar) by name. Use them for anything you open repeatedly: a project folder in your editor, a customer dashboard, a Notion page, a Spotify playlist, or a search engine with arguments.

[Quicklinks in Raycast (YouTube)](https://www.youtube.com/watch?v=sQuW4nv8XcM)

> [!TIP]
> Use the **Create Quicklink** command to add a quicklink, or **Search Quicklinks** to browse your library. Quicklinks also appear directly in Root Search alongside commands and applications.

## Create a Quicklink

1. Open the **Create Quicklink** command.
2. Enter the **Link**. This can be a website URL, file path, folder path, or deeplink.
3. Give the Quicklink a **Name** & **Icon**. Raycast will automatically use the favicon when a website URL is entered.
4. _(Only on Mac)_ Select an app in **Open With** (Optional).
5. Add **Tags** to organize related Quicklinks (Optional).
6. Click **Save Quicklink** `⌘ ↵`/`Ctrl ↵` to create the Quicklink.

### Add from Library

Rather than build one by hand, click ** Add from Library** in **Settings → Quicklinks** and search hundreds of ready-made Quicklinks, with common ones like Google, Wikipedia, and YouTube featured at the top.

Picking one opens the **Create Quicklink** form pre-filled, with the search term already set up as a `{argument name="Query"}` placeholder, so you can adjust it before saving.

### Supported Links

You can use Quicklinks to open a wide range of link types, including:

- **Web URLs**: `https://github.com` or `https://figma.com/file/...`
- **File and folder paths**: `~/Projects/my-app` on macOS or `C:\Projects\my-app` on Windows
- **Deeplinks**: `spotify://playlist/...` or `slack://channel/...`
- **Search URLs**: `https://google.com/search?q={argument name="query"}`

### Autofill
_(Only on Mac)_

When you create a Quicklink, Raycast can automatically fill the link from your active browser tab or clipboard. Auto Fill requires Automation permissions and works with Safari, Chrome, and other popular browsers.

## Dynamic Placeholders

Quicklinks support [Dynamic Placeholders](https://manual.raycast.com/dynamic-placeholders), which are replaced when the Quicklink runs. This lets one Quicklink adapt to the current date, clipboard, selected text, calculator result, or a value you enter when opening it.

## Search and Manage Quicklinks

The **Search Quicklinks** command gives you a central place to browse, open, and manage your Quicklinks.

- Search by name to find a specific Quicklink.
- Filter by tag to narrow down your collection. Press `⌘ P`/`Ctrl P` to open the filter menu.

### Action Panel
Open the [Action Panel](https://manual.raycast.com/action-panel) `⌘ K`/`Ctrl K` to discover more actions you can take with Quicklinks, including

- ** Open Quicklink**
- ** Open With**: Open the Quicklink in a different app than the set default.
- ** Edit**: Change the contents of an existing Quicklink.
- ** Duplicate**: Use an existing Quicklink as a starting point for a new one.
- ** Pin/Unpin**: Keep your most used Quicklinks at the top of the **Search Quicklinks** command.
- ** Copy Name/Link**
- ** Hide in Root Search**: Keep a specific Quicklink hidden from Root Search.
- ** Create Quicklink**: Add a new Quicklink from scratch.
- ** Move Quicklink**: When part of an organization, move Quicklinks between your personal account and organizations.
- ** Delete Quicklink**

### Tags

Tags let you organize Quicklinks by project, client, team, or purpose. Assign one or more tags when creating or editing a Quicklink, then filter by tag in the **Search Quicklinks** command when your library grows.

## Shared Quicklinks

With Raycast for Teams, you can give everyone the same fast path to the links your organization uses every day, from internal dashboards and documentation to staging environments, design files, and onboarding resources. Shared Quicklinks appear alongside your personal Quicklinks. 

> [!NOTE]
> An Organization is required before you can create a Shared Quicklink. You can create an organization in **Settings** or through the [Raycast website](https://www.raycast.com/settings/).

### Create Shared Quicklink

1. Open the **Create Quicklink** command.
2. In **Organization**, select your organization.
3. Complete the dialog with the Quicklink information.
4. Click **Save Quicklink** `⌘ ↵`/`Ctrl ↵` to publish the Quicklink.

The Quicklink is then available to every member of the organization. Shared Quicklinks show the organization's avatar on the right side of the item and sync automatically between members.

### Managing Shared Quicklinks

To manage Shared Quicklinks, use the **Search Quicklinks** command. You will see all your available Quicklinks appear by default, and can swap to view just your organization's Quicklinks by using the Organization filter in the Navigation Bar.

Use the actions available in the Action Panel `⌘ K`/`Ctrl K` to **Edit**, **Duplicate**, **Move**, or **Delete** a Shared Quicklink. Raycast asks for confirmation before destructive actions. You can also manage Shared Quicklinks in **Settings → Quicklinks** where your organization's Quicklinks appear as a separate group from personal Quicklinks.

## Import Quicklinks

Raycast can import Quicklinks from a JSON file using the **Import Quicklinks** command. This is useful for moving an existing setup into Raycast or sharing a set of Quicklinks with teammates.

**JSON Format**

The JSON file must contain an array of Quicklink objects. Each object supports these fields:

- `name`: Quicklink title. Type: `String` (required)
- `link`: Quicklink URL. Type: `String` (required)
- `iconName`: Quicklink icon. Type: `String` (optional)
- `openWith`: Target app to open the Quicklink. Type: `String` (optional)

If no app is specified with `openWith`, the link opens in the default web browser. Deeplinks are routed by the browser.

If no icon is specified with `iconName`, Raycast uses the default Quicklink icon.

```json
[
  {
    "link": "https://duckduckgo.com/?q={argument}",
    "name": "Search DuckDuckGo"
  },
  {
    "openWith": "Finder",
    "iconName": "folder-16",
    "link": "~/Downloads",
    "name": "Downloads"
  },
  {
    "openWith": "Music",
    "link": "https://music.apple.com/gb/station/apple-music-hits/ra.1498155548",
    "name": "Apple Music Hits Radio"
  },
  {
    "link": "shortcuts://run-shortcut?Name={Test}",
    "name": "Run Apple Shortcut"
  }
]
```

After the import completes, Raycast shows how many Quicklinks were added and how many duplicates were skipped. A Quicklink is considered a duplicate when another Quicklink has the same title and content.

## Examples

- **Search engines**: `https://google.com/search?q={argument name="query"}` to search Google from Raycast.
- **GitHub repositories**: `https://github.com/{argument name="org"}/{argument name="repo"}` to jump to any repo.
- **Project folders**: `~/Projects/my-app` opened in VS Code.
- **Internal tools**: dashboards, staging environments, admin panels, and design files.
- **Translation**: a Google Translate URL with arguments for source language, target language, and text.
- **Meetings**: your team's standup Zoom or Google Meet link, pinned for fast access.

## Settings

All Quicklinks settings live under **Settings → Quicklinks**.

- **Show Link Previews**: Display a preview of the website URL when browsing Quicklinks in the **Search Quicklinks** command. 
- _(Only on Mac)_ **Prefer Existing Tabs**: When a Quicklink points to a website URL already open in your browser, Raycast switches to that tab instead of opening another one. Supports Chrome, Safari, and popular Chromium and Webkit browsers.
- **Pass Selected Text as Argument**: Raycast can automatically pass selected text from the active application to Quicklinks with a single argument when invoked via hotkey.
- **Show Warning Before Deleting Quicklinks**

![Settings open to the Quicklinks page](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/core/mac-quicklinks-settings.png)

### Commands

Assign aliases and hotkeys to the Quicklinks commands you use most:

- **Create Quicklink**: Open the Quicklink editor so you can save a new link. Toggle **Autofill selected text** to pre-fill the URL field with text selected in another app.
- **Export Quicklinks**: Save your Quicklinks to a file for backup or sharing.
- **Import Quicklinks**: Import Quicklinks from a JSON file.
- **Search Quicklinks**: Find and open a Quicklink from your library.

### Quicklinks

Below Commands, you'll find your full Quicklinks library. Personal Quicklinks and Organization Quicklinks are grouped. 
- ** Create Quicklink** to add a new Quicklink.
- ** Add from Library** to start from one of hundreds of ready-made Quicklinks.
- Assign an alias or hotkey to any Quicklink for faster access.
- Click the **ellipsis** icon next to a Quicklink to edit, duplicate, copy, disable or delete it.

## Permissions
_(Only on Mac)_

Auto Fill needs Automation access to read the link from your active browser tab. Grant it in **System Settings → Privacy & Security → Automation**. Raycast prompts the first time you create a Quicklink if the permission is missing.

## Troubleshooting

### Quicklink doesn't open or opens the wrong app

- Check that the URL, file path, or folder path is correct and accessible.
- _(Only on Mac)_ Check that the correct application is selected in the **Open With** field.
- For deeplinks such as `spotify://`, make sure the target app is installed.

### Arguments or placeholders aren't being replaced

- Check the placeholder syntax. Arguments must use curly braces, for example `{argument name="query"}`.
- You can use a maximum of 3 arguments per Quicklink.
- If you're using another Dynamic Placeholder, make sure the placeholder name matches the [Dynamic Placeholders](https://manual.raycast.com/dynamic-placeholders) reference.

### Still having issues?

If none of the above resolves it, gather the following and send it to us via the **Send Feedback** command so we can investigate:

1. **Your OS version** and **Raycast version** (found in **Settings → About**).
2. **Steps to reproduce** the issue.
3. The **Quicklink URL or path** (with any placeholders).
4. **Your Raycast logs**: use the built-in **Copy Raycast Logs** command to copy your latest log files to the clipboard, or **Reveal Raycast Logs** to open your log folder.
5. **A screen recording** showing the issue in action.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Quicklinks. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
