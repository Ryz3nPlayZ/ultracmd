> Source: https://manual.raycast.com/script-commands
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Script Commands

> Available on: Mac, Windows

Turn your scripts into Raycast commands with Script Commands. Run Bash, Python, Ruby, Swift, AppleScript, and more to automate any workflow.

Script Commands let you tailor Raycast to your needs. They allow you to run your frequently used scripts in a few keystrokes, or bind them to a hotkey.

Script Commands let you bring your own automation into Raycast by writing simple scripts in any language you prefer, whether it's C#, Bash, PowerShell, Python, Node.js, or others. Define a title, description, and other metadata at the top of your script file, and Raycast turns it into a fully searchable command, just like a built-in one.

Quickly create a new script with **Create Script Command** or import existing scripts by adding a **Script Directory** from Settings. You can learn more about the metadata format in the [Script Commands repo](https://github.com/raycast/script-commands#metadata).

## Overview

Reach for a Script Command when you want to:

- Trigger a system action you do all day: toggle hidden files, switch audio output, eject all disks.
- Run a personal dev workflow: kick off a deploy, open the staging dashboard, paste a templated commit message.
- Talk to home automation, IoT, or an internal API without writing a full extension.
- Turn ten lines of shell or Python into a first-class Raycast command.

## Adding Script Commands

### Create a new script

Open Raycast, run **Create Script Command**, pick a language template, and Raycast scaffolds a new file with the metadata header pre-filled. Save it to any folder you've added as a Script Directory.

### Import existing scripts

Open **Settings → Script Commands → Add Script Directory** and pick any folder. Raycast indexes every script file inside it as a command. Edits to a script's metadata (rename, add an argument, change mode) are picked up automatically — no restart needed.

For the full metadata reference (directives, modes, arguments, refresh time, and language-specific examples), see the [Script Commands repo](https://github.com/raycast/script-commands).

## Tips

### Bind frequently-used scripts to a hotkey

Any Script Command can be triggered from a global hotkey. Find your script in [Root Search](https://manual.raycast.com/search-bar), press `⌘ K`/`Ctrl K` to open the [Action Panel](https://manual.raycast.com/action-panel), pick **Configure Command**, then **Record Hotkey**. Now the script runs from anywhere on your system, even when Raycast isn't open.

### Keep scripts idempotent

If a script will be triggered repeatedly (especially from a hotkey or a refresh interval), make it safe to run twice in a row. Toggle commands beat on/off pairs; "ensure X exists" beats "create X".

## Platform Support

### macOS
_(Only on Mac)_
Script Commands run with whatever interpreter your shebang points to. Built-in support covers AppleScript (`.applescript`, `.scpt`), shell (`bash`, `zsh`), Python, Node.js, Ruby, PHP, and Swift.

> [!TIP]
> The first time a script touches Accessibility, Automation, or Full Disk Access, macOS shows a system permission prompt. Grant it to the **Raycast** app, not Terminal — Raycast is the process running the script.

> [!TIP]
> For AppleScript, prefer `.applescript` over compiled `.scpt` when you can. Plain text plays nicer with version control and is much easier to diff and review.

### Windows
_(Only on Windows)_
On Windows, Script Commands run with whatever interpreter is on your PATH. Common runtimes include PowerShell (`.ps1`), C#, Python, Node.js, and Bash (under WSL or Git Bash).

> [!TIP]
> If a `.ps1` script won't run, check your PowerShell execution policy with `Get-ExecutionPolicy`. The default `Restricted` blocks every script; `RemoteSigned` is the usual setting for personal machines.

> [!TIP]
> Forward slashes work in most paths and survive copy/paste between machines better than backslashes. Prefer `C:/Users/you/scripts/foo.ps1` over the escaped backslash form.

## Permissions
_(Only on Mac)_

The first time a script touches Accessibility, Automation, or Full Disk Access, macOS shows a system permission prompt. Grant it to the **Raycast** app, not Terminal — Raycast is the process running the script. You can review what's been granted in **System Settings → Privacy & Security**.

## Learn More

For the full metadata reference and examples in every supported language, see the [Script Commands repo](https://github.com/raycast/script-commands).

Here are two example scripts to get you started:

### Build Xcode
_(Only on Mac)_
```bash
#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Build XCODE
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖

osascript <<'EOF'
tell application "Xcode"
    activate
end tell
tell application "System Events"
    tell process "Xcode"
        keystroke "r" using {command down}
    end tell
end tell
EOF
```

### Open in CleanShot X
_(Only on Mac)_
```bash
#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open in CleanShot X
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🖼️
# @raycast.packageName Finder

# Documentation:
# @raycast.description Opens the currently selected Finder file with CleanShot X

selected_file=$(osascript -e '
tell application "Finder"
    if (count of (selection as alias list)) > 0 then
        set selectedItem to item 1 of (selection as alias list)
        return POSIX path of (selectedItem as text)
    else
        return ""
    end if
end tell
')

if [ -z "$selected_file" ]; then
    echo "No file selected in Finder."
    exit 1
fi

open -a "CleanShot X" "$selected_file"
echo "Opened $(basename "$selected_file") in CleanShot X"
```

## Troubleshooting

For issues with Script Commands, refer to the [troubleshooting and FAQs](https://github.com/raycast/script-commands#troubleshooting-and-faqs) section in the Script Commands repo.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Script Commands. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
