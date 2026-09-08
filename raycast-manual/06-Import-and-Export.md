> Source: https://manual.raycast.com/import-export
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Import & Export

> Available on: Mac, Windows

Easily back up, transfer, or migrate your full Raycast setup and data between your devices.

Use Import & Export to move your Raycast setup between machines, create a backup for safekeeping, or migrate your data from Raycast for Mac v1. Export your entire configuration as a single file, or export individual components like Snippets and Quicklinks and import them into Raycast on another machine.

## Exporting

### Export Settings & Data

When you export using the **Export Settings & Data** command in Raycast on Mac or Windows, Raycast bundles eleven data categories into a single `.rayconfig` file saved to your computer. The following categories are included:

- AI Chats, Commands & Agents
- Clipboard History
- Quicklinks
- Snippets
- Notes
- Emoji & Symbol History
- MCP Servers
- Extensions installed from the Store
- Settings, Aliases & Hotkeys
- Raycast Wrapped
- Window Management Layouts

`.rayconfig` files are encrypted and require a passphrase of at least 8 characters. You'll be prompted to set one the first time you use the **Export Settings & Data** command, or in **Settings → Advanced → Export**. Raycast remembers it for future exports. You can clear or update it in Settings at any time.

### Export Snippets or Quicklinks

To export just your Snippets or Quicklinks, use the **Export Snippets** and **Export Quicklinks** commands to save each as a JSON file. Snippet and Quicklink exports are not encrypted and do not require an export passphrase.

### Scheduled Exports

**Pro** Raycast can automatically export your data on a schedule, so you always have a recent backup without having to think about it. To set it up:

1. Open **Settings → Advanced → Export**.
2. Set an export passphrase of at least 8 characters. Backups will be skipped if no valid passphrase is set.
3. Choose a backup frequency (**None**, **Daily**, **Weekly**, or **Monthly**) and an output folder.
   - Optionally, enable **Auto-Delete Old Exports** to manage disk space. You can keep the latest, last 5, or last 10 exports.

Once configured, a `.rayconfig` file will be saved to your chosen folder at the scheduled frequency.

> [!TIP]
> Point **Scheduled Backup Location** at a synced folder like iCloud Drive, Dropbox, or Google Drive. The `.rayconfig` is encrypted with your passphrase, so your data stays private while you get an off-machine copy automatically.

## Importing

### Import Settings & Data

Import `.rayconfig` files into Raycast using the **Import Settings & Data** command. You'll see a checklist of all available categories and can pick exactly which ones to import. Any unchecked categories are left untouched.

`.rayconfig` files are cross-platform. A file exported from Raycast on Mac v2 can be imported into Raycast on Windows, and vice versa. This makes it straightforward to carry your setup across platforms without any extra steps.

> [!TIP]
> Imports are selective. If you only want to recover your Snippets from an earlier backup, import the `.rayconfig` and tick only **Snippets** in the category checklist.

### Import Snippets or Quicklinks

Import your Snippets and Quicklinks using the **Import Snippets** and **Import Quicklinks** commands to load each from a JSON file.

### Migrate from Raycast v1

> [!WARNING]
> Make sure that you are running Raycast for Mac v1.104.16 or newer if you would like to migrate data from Raycast v1 to v2.

If you've previously used Raycast v1 on Mac, you can migrate your data directly to Raycast v2. No `.rayconfig` file is needed. The first time you launch v2 on a Mac where v1 is installed, you'll be prompted to transfer automatically.

If you'd prefer to migrate later, dismiss the onboarding screens and run the **Migrate from Raycast v1** command. This command brings across some extra data that is not included in your `.rayconfig` export, namely Clipboard History, Wrapped and your Emoji Picker customizations.

If you include **Settings, Aliases & Hotkeys**, Raycast will show a **Transfer Hotkeys?** prompt. Confirming will disable those hotkeys in v1 so both apps aren't competing for the same shortcuts. You can re-enable them in v1 at any time.

> [!TIP]
> Migration is additive — your existing v2 setup is never wiped. Duplicates, like a Quicklink with the same link or a Snippet with the same keyword, are skipped automatically.

If you don't need the extra data and are okay with manually reconfiguring your hotkeys, then using the Import Settings and Data command with your `.rayconfig` file is also an option.

### Conflict Handling

Raycast handles duplicates automatically when you import. Here's what to expect:

- Quicklinks with an existing matching link are skipped.
- Snippets that match an existing text, keyword, and name are skipped. Keyword collisions are also skipped.
- All other data merges with your existing setup. Nothing is overwritten.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Import & Export. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
