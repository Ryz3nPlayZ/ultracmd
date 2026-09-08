> Source: https://manual.raycast.com/file-search
> Scraped from the Raycast Manual (https://manual.raycast.com)

# File Search

> Available on: Mac, Windows

Find any file on your computer by name from Root Search or the dedicated Search Files command, with full control over what's indexed.

File Search turns Raycast into the fastest way to find a file on your computer. Type in [Root Search](https://manual.raycast.com/search-bar) and matches appear inline as you go or use the **Search Files** command for richer details and metadata without opening Finder or Explorer.

[File Search in Raycast (YouTube)](https://www.youtube.com/watch?v=nQl8Wrue3oQ)

## Get Started

1. Start typing a file or folder name in Root Search. Matching results appear inline alongside your apps, commands, and history.
2. Press `↵` to open the selected result, or `⌘ K`/`Ctrl K` to open the [Action Panel](https://manual.raycast.com/action-panel) for more actions.
3. For a richer view, open the **Search Files** command. The command will show a wider results list, a details panel showing file metadata, and the same actions as Root Search. When the search field is empty, the command shows your **Recently Used** files.

![Raycast Root Search showing file search results](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/file-search/mac-filesearch-rootsearch.png)

> [!NOTE]
> By default, File Search matches on **file name** alone. To also match on what's inside your files, turn on [Content Search](#content-search).

> [!TIP]
> Type any file path into Root Search and you'll see an **Open in Finder** command (**Open in File Explorer** on Windows) to take you straight to that location.

## What Gets Indexed

By default, Raycast indexes your home folder, and on Mac it also indexes `/Applications`. Hidden files are excluded, and Raycast respects `.gitignore`, `.ignore`, Git exclude files, and `.rayignore` files. Common noise like `node_modules`, `*.tmp` files, and system caches is filtered out automatically.

Raycast also skips the state and cache folders that developer tools keep in your home folder, such as the caches and sessions inside `.claude`, plus `.codex`, `.npm`, `.cargo/registry`, and `.swiftpm`. Files you wrote yourself in those folders, like `.claude/settings.json` or anything under `.claude/skills`, are still indexed.

> [!NOTE]
> Your file index is stored locally on your device and is never synced or uploaded to Raycast servers.

### Permissions
_(Only on Mac)_

On first launch, Raycast requests permission to scan your home folder. If you prefer, grant permission to individual folders instead and File Search will index just those. If you skip this during setup, you'll see a prompt when you open the **Search Files** command.

### .rayignore

A `.rayignore` file works like `.gitignore`, but for Raycast's File Search. Place one in any folder to tell Raycast what to skip. List one path or glob pattern per line, and rules apply to that folder and all subfolders. This is useful when you want to exclude something from File Search without touching your Git config, such as a tracked build directory you don't want cluttering results.

The **Exclude from Index** action in **Search Files** handles this for you. Select a file, run the action, and Raycast walks up the directory tree to find the nearest `.rayignore`, appends the rule, or creates a new `.rayignore` in the file's parent folder if none exists.

## Settings

All File Search settings can be found in **Settings → File Search**.

![Settings showing File Search extension](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/file-search/mac-filesearch-settings.png)

- **Content Search**: Also match on the text inside files, not just their names. See [Content Search](#content-search) below.
- **Search Scopes**: Add or remove additional folders to be included when searching for files. Useful for bringing in an external drive or a specific project folder not in your home folder.
- **Ignore Patterns**: Comma-separated glob patterns to skip globally (for example `*.log, build/**`). Combine with `.rayignore` files for per-folder rules.
- **Include Hidden Files**: Index dotfiles, folders that start with `.`, and other hidden files on your system.
- **Use Ignore Files**: Respect `.gitignore`, `.ignore`, and `.rayignore` files. On by default.
- **Keep Files from Removed Volumes**: Preserve indexed results for files on external or network drives even when those drives are disconnected or unavailable.
- **Enforce Low Disk Space Block**: Stop indexing if the estimated index wouldn't fit in your available disk space. Off by default. See [Enforce Low Disk Space Block](#enforce-low-disk-space-block) below.
- **Reset to Defaults**: Restore all File Search settings to their defaults. See [Reset to Defaults](#reset-to-defaults) below.

If you would like to turn off File Search in Root Search, you can do so from **Settings -> Launcher -> Include Files in Root Search**.

### Content Search

Content Search lets Raycast find files by what's inside them, not just their names. It uses your operating system's built-in search index (Spotlight on macOS, Windows Search on Windows), so it only works when that index is healthy and covers your File Search folders.

To turn it on, open **Settings → File Search** and toggle on **Content Search**. If the toggle is grayed out, your OS index isn't covering your File Search folders yet — fix that first (below), then enable it.

![Content Search toggle in Settings → File Search](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/file-search/mac-settings-filesearch-contentsearch.png)

**Mac**

If Spotlight isn't indexing your File Search folders, Content Search shows a warning and the toggle stays disabled.

  1. Open **System Settings → Spotlight** (Raycast's warning has an **Open Spotlight Settings** shortcut).
  2. Make sure your File Search folders are not in Spotlight's **Privacy** / excluded list. Remove any you want searchable.
  3. Give Spotlight time to finish indexing, then re-toggle **Content Search**.

**Windows**

If your File Search folders aren't in the Windows index, Content Search shows a warning and the toggle stays disabled.

  1. Open **Windows Indexing Options** (Raycast's warning has an **Open Search Settings** shortcut).
  2. Add your File Search folders to the index.
  3. For file contents (not just names): **Indexing Options → Advanced → File Types** and set the relevant types to **Index Properties and File Contents**.
  4. Let indexing finish, then re-toggle **Content Search**.

### Enforce Low Disk Space Block

Off by default, and currently available to some users. When enabled, Raycast stops indexing your files if it estimates the index wouldn't fit in your available disk space, protecting you from a large index filling up your drive.

If indexing is blocked because you're low on space, Raycast shows a warning at the top of File Search settings ("You are low on disk space, which may prevent Raycast from indexing your files"). To resolve it, free up disk space, then re-run indexing. If you'd rather let indexing proceed regardless, turn this setting off.

### Reset to Defaults

If your File Search settings get into a messy state, or you just want a clean slate, you can restore everything to its defaults in one step.

1. Open **Settings → File Search**.
2. Scroll to **Reset to Defaults**.
3. Click **Reset**.
4. Confirm in the dialog ("Reset File Search Settings?"). Your files will then be re-indexed.

Resetting restores all File Search settings to their defaults, including:

- **Search directories (scopes)** — back to the defaults (your Home folder and Applications).
- **Ignore patterns / exclusions** — back to the default set.
- Other toggles like **Include Hidden Files**, **Use Ignore Files**, and **Keep Files from Removed Volumes**.

After you confirm, Raycast re-indexes your files so search reflects the restored settings. Depending on how much you have indexed, this can take a little while to complete.

> [!NOTE]
> This only affects File Search settings. It doesn't delete your files or change settings elsewhere in Raycast.

## Actions

With a file selected in either Root Search or the **Search Files** view, press `⌘ K`/`Ctrl K` to open the Action Panel. Several File Search-specific actions you can use in Raycast:

- **Show Details in File Search**: Opens the **Search Files** command to the selected file with the details panel open.
- **Quick Look**: Preview the file without opening it.
- **Open in Terminal**: Opens the folder in your default terminal. Folders only.
- **Save as Quicklink**: Turn the file into a [Quicklink](https://manual.raycast.com/quicklinks) so you can launch it by name later.
- **Save as Duplicate**: Creates a copy of the file alongside the original.
- **Send to Quick AI** / **Send to AI Chat** _(Only on Mac)_: Attach the file to a new Chat as context. Files only.
- **Toggle Hidden Files**: Includes hidden files on your computer in File Search.
- **Index Files**: Force a fresh scan of your file index. You can also use the **Stop Indexing** action from the indexing toast to pause it.

## AI Extensions
_(Only on Mac)_

File Search ships with [AI Extensions](https://manual.raycast.com/ai/ai-extensions) you can call in [AI Chat](https://manual.raycast.com/ai/ai-chat) or [Quick AI](https://manual.raycast.com/ai/quick-ai) with an `@` mention to ask about your files in natural language — for example "find the PDF I downloaded last week from Apple" or "open the most recent screenshot from this morning" — without knowing the exact file name.

- **Ask File Search** (`@file-search`) — queries Raycast's own File Search index, so it reflects your configured search scopes, ignore patterns, and (if enabled) [Content Search](#content-search).
- **Ask Finder** (`@finder`) — asks against macOS Finder.

![Quick AI using an AI Extension to find a project brief](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/file-search/mac-filesearch-aiextension.png)

Each can be given an alias and hotkey, and toggled on/off, from the **AI Extensions** section of File Search settings.

Both extensions are also available as [fallback commands](https://manual.raycast.com/settings#fallback-commands). This means you can type your file search into Root Search with no matching results and use the **Use with Ask File Search** or **Use with Ask Finder** command at the bottom of results to locate it on your Mac.

## Troubleshooting

If File Search isn't working as expected, here are some common issues and steps to resolve them.

### File Search is stuck on "Indexing files"

- Update Raycast to the latest version.
- Check that Raycast has the right permissions (**Full Disk Access** in
  **System Settings → Privacy & Security**).
- Make sure only one version of Raycast is running.
- Check for conflicts with other tools that index or watch files.
- To force a fresh scan, run the **Index Files** action inside File Search.

### A file isn't showing up in results

- Confirm the file's folder is included in your Search Scopes
  (**Settings → File Search**).
- If a specific folder seems broken, remove it from the scope and re-add it.
- File Search respects `.gitignore`, `.ignore`, and `.rayignore` files by
  default. Check **Ignore Patterns** and **Use Ignore Files** if expected
  files are missing.

### Hidden files aren't being found

- Enable **Include Hidden Files** in **Settings → File Search**. Hidden
  files are dotfiles and folders whose names start with `.` and are
  excluded by default.
- Note that ignore files (`.gitignore`, `.ignore`, `.rayignore`) still
  apply — a hidden file inside an ignored folder won't be indexed.
- Some developer tool caches and state folders are never indexed, even with
  **Include Hidden Files** on. See [What Gets Indexed](#what-gets-indexed).

### Search Screenshots / OCR isn't finding text in images

- Enable **Text Recognition** — it's required for the `text:` filter and
  the **Copy Text from Image** action.
- Make sure the folder holding the images is in Search Scopes. Defaults
  include the system screenshot location, CleanShot X, and `~/Desktop`.
- Grant Screenshots file access: **Full Disk Access** in **System Settings
  → Privacy & Security**, or at minimum Desktop, Documents, and Downloads.
- For non-screenshot images or videos in watched folders, enable **Include
  All Media**. Set **Recognition Mode** to **Accurate** to catch more text.

### Content Search toggle is grayed out

Your OS index isn't covering your File Search folders. Follow the platform
steps in [Content Search](#content-search) to add your folders to Spotlight
(macOS) or Windows Search, let indexing finish, then re-toggle **Content
Search**.

### Content Search isn't returning content matches

- Confirm **Content Search** is on in **Settings → File Search** and that the
  folder is in your OS index.
- Some files may not be indexed yet — large or recently added files can take
  time, and locations excluded from the OS index are never searched.
- Stale results usually mean the OS is still (re)indexing. Give it time to
  finish.

### Search results feel worse or different than Raycast v1

Fuzzy-matching behavior (e.g. underscores/hyphens in filenames) has changed
and several cases have been fixed across recent releases — make sure you're
on the latest version. If it still differs, it may be a known issue; please
report it with the details below.

### Still having issues?

If none of the above resolves it, gather the following and send it to us via the **Send Feedback** command so we can investigate:

1. **Your OS version** and **Raycast version** (found in **Settings
   → About**).
2. **Steps to reproduce** the issue
3. **Your Raycast logs**: use the built-in **Copy Raycast Logs** command to
   copy your latest log files to the clipboard, or **Reveal Raycast Logs**
   to open your log folder.
4. **A screen recording** showing the issue in action.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with File Search. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
