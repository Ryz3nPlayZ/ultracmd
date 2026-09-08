> Source: https://manual.raycast.com/run
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Run

> Available on: Windows

Replace the Windows Run dialog with Raycast — launch apps, Control Panel applets, MMC snap-ins, paths, and shell URIs by name.

Run is a modern replacement for the classic Windows Run dialog. Instead of memorising commands, you can browse, discover, and run everything your system offers, directly from Raycast.

## Getting Started

1. **Open Raycast** and search for **Open Run**.
2. **Browse or type**: Start typing or choose from previously run commands. Applications, system tools, Control Panel applets, Management Console, paths, and registered URIs you've run before will appear here as well.
3. **Execute**: Press `Enter` to run the selected item. Raycast records it in your history so you can rerun it later.

> [!TIP]
> Prefer to skip the list? Use **Execute Run Command** from [Root Search](https://manual.raycast.com/search-bar): press `Tab` to enter a command and run it instantly, when you know exactly what you need to launch.

### Commands

- **Open Run** – Browse and execute Windows commands, applications, Control Panel applets, MMC snap-ins, directories, and shell URIs. Your Run history is displayed in this command
- **Execute Run Command** – Run a Windows command directly from Root Search using `Tab`
- **Search Run Commands** – Browse and manage your custom Run Command aliases
- **Create Run Command** – Create a custom Run Command with an alias, icon, description, tags, and optional shell override

### Capabilities

With Raycast Run, you can:

- Search and launch applications and system tools (`notepad`, `calc`, `regedit`, `taskmgr`)
- Open Control Panel applets and MMC snap-ins (`appwiz.cpl`, `certmgr.msc`, `diskmgmt.msc`)
- Navigate to directories using paths, network shares, and environment variables (`C:\Users`, `\\server\share`, `%appdata%`)
- Execute shell URIs to access special locations (`shell:Recent`, `shell:startup`, `shell:RecycleBin`)
- Access and manage your run history with full backwards compatibility with the Windows Run dialog

## How Run Works

Run classifies what you type into one of these kinds:

- **Executable** – `.exe`, `.cmd`, `.bat`, `.com`, or an unrooted command like `notepad`
- **Control Panel Applet** – `.cpl` files such as `appwiz.cpl` or `ncpa.cpl`
- **Management Console** – `.msc` snap-ins such as `certmgr.msc` or `diskmgmt.msc`
- **Environment Variable** – `%VAR%` style values such as `%APPDATA%`
- **Path** – Rooted drive paths (`C:\Users`), UNC paths (`\\server\share`), and env-var paths (`%appdata%\Microsoft`)
- **URI** – Registered schemes like `shell:Recent`, `shell:startup`, or `ms-settings:`
- **Run Command** – Custom aliases you've created

History is shared with the built-in Windows Run dialog, so anything you've run there shows up here, and anything you run from Raycast stays available in both places.

### Run Commands

Run Commands are custom aliases for frequently used commands you build on top of anything Run already knows how to execute. A Run Command includes:

- Alias & Icon
- Description (optional)
- Command
- Tags (optional)
- Shell (defaults to system shell)
  - Non-default shells may not support URI commands, Control Panel applets, or Management Consoles.

Once saved, a Run Command appears in Root Search under its alias and in the **Open Run** list. You can create one at any time from the **Create Run Command** command or from the action in the [Action Panel](https://manual.raycast.com/action-panel).

## Tips

- Bind **Open Run** to `win R` to replace the built-in Windows Run dialog with the Run commands in Raycast
- Use the **Run as Administrator** action with a Run Command or executable selected to run with elevated permissions
- Use the **Delete from History** action on any History entries in the **Open Run** command to remove it from both Raycast and Windows Run history


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Run. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
