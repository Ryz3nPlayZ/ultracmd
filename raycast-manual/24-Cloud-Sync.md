> Source: https://manual.raycast.com/cloud-sync
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Cloud Sync

> Available on: Mac, Windows, iOS
> Tier: Pro Exclusive

Cloud Sync keeps your Raycast data — Quicklinks, Snippets, Notes, AI chats, themes, and more — consistent across all your devices and apps.

Cloud Sync keeps your Raycast setup consistent on every device where you're signed in. The things you create — [Quicklinks](https://manual.raycast.com/quicklinks), [Snippets](https://manual.raycast.com/snippets), [Notes](https://manual.raycast.com/notes), AI chats, themes, window management layouts, and more — sync continuously in the background, so a Snippet you add on your Mac at work is ready on your Windows machine at home. Even devices that have been offline catch up automatically, with nothing to export or merge by hand.

## Get Started

> [!WARNING]
> Before turning on Cloud Sync, run the **Export Settings & Data** command to create a backup of your current setup. This makes sure you have a safe copy of your data to restore from in case anything goes wrong during the initial sync. We also recommend enabling [scheduled exports](https://manual.raycast.com/import-export#scheduled-exports) so you always have a recent backup.

1. If you're a macOS v2 user who hasn't run the **Migrate from Raycast v1** command yet, do so first to bring your v1 data across. Skip this on Windows or if your app is already set up.
2. Sign in to your Raycast account in **Settings → Account** — Cloud Sync requires a Pro subscription.
3. Open **Settings** (`⌘ ,`/`Ctrl ,`) and select **Cloud Sync** from the sidebar.
4. Under **Sync Preferences**, choose which categories to include when Cloud Sync turns on. You can change your selection at any time later.
5. Turn Cloud Sync on with the toggle in the top-right corner and confirm.

![The Cloud Sync settings tab with the enable toggle turned off and the backup reminder](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/basics/mac-settings-cloudsync.png)

> [!NOTE]
> Cloud Sync requires a signed-in Raycast Pro account. If your session expires, syncing pauses and resumes once you sign in again. If you sign out, Cloud Sync turns off, and you'll need to re-enable it after signing back in.

Once Cloud Sync is on, the settings page shows two screens: **Synced Devices**, listing every device connected to your account, and **Synced Content**, where you control what's kept in sync.

![The Cloud Sync settings tab with sync enabled, showing Synced Devices, Synced Content, and the items that are not synced](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/basics/mac-settings-cloudsync-enabled.png)

## Choose What to Sync

The **Synced Content** screen is where you control what's kept in sync. Each content category shows a live count of its synced items and a toggle to turn it on or off. While a device is still catching up, the count shows how many items are on this device out of how many are in the cloud.

### Content categories

- **AI Commands & Agents**
- **AI Chat History**
- **MCP Servers**
- **Quicklinks**
- **Raycast Notes**
- **Snippets**
- **Themes**
- **Transcription Styles**
- **Window Management Layouts**
- **Extensions**: Extensions and commands sync across devices, but need to be enabled per device.

### General Settings categories

- **Open at Login**
- **Show in Menu Bar** (Show in System Tray on Windows)
- **Appearance**
- **Interface Size**
- **Window Mode**

> [!TIP]
> Some preferences are synced by default and can't be turned off: **Some General Settings** and **Root Search Ranking**. AI Chat History also always keeps the AI models and folders it depends on in sync, even if you turn off AI Commands & Agents.

![The Synced Content screen listing each category with its item count and sync toggle](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/basics/mac-settings-cloudsync-syncedcontents-content.png)

### Not Synced

Some data always stays on your device:

- **Clipboard History**
- **Script Commands** (scripts only; their settings sync)
- **Credentials and Passwords**: never synced, for security reasons
- **Some General and Advanced Settings**: device-specific settings stay on this device

Anything that doesn't appear in Synced Content — such as Screenshots, Search History, and your Export & Backup settings — is also not synced.

## Manage Synced Devices

The **Synced Devices** screen lists every device connected to your account. Each entry shows the device name, its platform, OS and app version, and when it last synced. From there you can:

- **Rename a device** so it's easy to recognize — click its name and type a new one.
- **Remove a device** with the x button next to it to stop it from syncing and revoke its access. The removed device stops syncing and clears its local synced state; the local data itself stays on that device.

Your current device is marked **This Device**, always appears at the top, and can't be removed.

> [!NOTE]
> **Legacy Raycast & iOS Devices** groups all of your Raycast v1 and iOS devices into a single entry. They sync through legacy Cloud Sync and can't be shown, renamed, or removed individually. The Cloud Sync settings shown here are exclusively part of v2, and Cloud Sync v2 for iOS is coming soon.

![The Synced Devices screen listing each connected device with its platform, app version, and last sync time](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/basics/mac-settings-cloudsync-synceddevices.png)

## Turn Cloud Sync Off

Turning Cloud Sync off on a device stops data from syncing. Any data previously synced to that device remains on it — only the device's local sync state is cleared. Your data stays available in the cloud and on your other synced devices, and is restored to the device when you re-enable Cloud Sync.

## Delete Your Cloud Sync Data

Turning Cloud Sync off only stops a device from syncing — your synced data stays on Raycast's servers and on your other devices. If you want to remove that data from the cloud entirely, open **Settings → Cloud Sync** and, under the **Danger Zone**, use the **Delete Cloud Sync Data & Devices** button.

This permanently removes the data your account has synced to Raycast's servers, disconnects your synced devices, and turns off syncing on this device. Your local Raycast data stays on your devices. The button is available whenever your account still has synced data on the server, whether Cloud Sync is currently enabled or disabled on this device — so even if you've already turned Cloud Sync off here, you can still delete the data your account has previously synced to the cloud.

> [!WARNING]
> **Delete Cloud Sync Data & Devices** permanently removes your synced data from Raycast's servers and cannot be undone. This is different from turning Cloud Sync off, which leaves your server data intact. Make sure you have a recent backup (**Export Settings & Data**) before deleting.

## Privacy & Security

Synced data is tied to your Raycast account and is encrypted in your device's local database, in transit, and in the server's database. Credentials and passwords are never synced. Raycast for Enterprise organizations can disable Cloud Sync for their members entirely with the [Cloud Sync Control](https://manual.raycast.com/enterprise/cloud-sync-control) admin setting.

## FAQ

### Do I need a Raycast Pro subscription?

Yes. Cloud Sync is a Pro feature. It also requires being signed in to your Raycast account.

### Can I choose what gets synced?

Yes. Each category (Quicklinks, Snippets, Notes, AI history, themes, and more) can be turned on or off independently in the Cloud Sync settings — either before you enable Cloud Sync via **Sync Preferences**, or at any time afterwards via **Synced Content**.

### What happens to my data if I turn Cloud Sync off?

Your data remains in the cloud and on your other synced devices. Only the local synced state on the device you disabled is cleared; it is restored when you re-enable Cloud Sync.

### How do I remove my data from the cloud entirely?

In **Settings → Cloud Sync**, under the **Danger Zone**, use the **Delete Cloud Sync Data & Devices** button. This permanently removes your synced data from Raycast's servers and disconnects your synced devices, and is different from turning Cloud Sync off, which leaves your server data intact. The button is available whether Cloud Sync is currently enabled or disabled on the device, as long as your account still has synced data on the server. Because it's hard to undo, make sure you have a recent backup first.

### Which platforms are supported?

Cloud Sync works across the Raycast for Mac v1 and v2 apps, the Raycast for Windows app, and the Raycast for iOS app. Data you create or change in any one of them is kept in sync with all the others. v1 and iOS devices sync through legacy Cloud Sync and appear as a single **Legacy Raycast & iOS Devices** entry in the Synced Devices list.

### Why does Raycast say my organization has disabled Cloud Sync?

Raycast for Enterprise organizations can turn off Cloud Sync for all members via the [Cloud Sync Control](https://manual.raycast.com/enterprise/cloud-sync-control) admin setting, typically for data privacy reasons. If you see this message, reach out to your organization's admin.

## Troubleshooting

Cloud Sync is designed to be hands-off, but a few rough edges remain — especially around bridging data between v1 and v2 devices. Here are the known issues and what to do about them.

### Cloud Sync says my network requires an extra security certificate

Some networks, often managed or corporate ones, intercept TLS traffic with their own certificate. When that happens, Cloud Sync goes offline with **Your network requires an extra security certificate** instead of a generic connection error, and links you to where you can fix it.

Add your network's certificate as an **Additional Certificate Authority** in **Settings → Advanced → Connection**, then reconnect. If you don't have the certificate, ask whoever manages your network for it.

### Content looks stale or missing on another device

Cross-device data can look stale or missing while a device is catching up on changes. Check the item counts in **Settings → Cloud Sync → Synced Content** — while a category is still syncing, the count shows how many items are on this device out of how many are in the cloud. Give it a moment to finish before assuming data is lost.

### A Quicklink opens with a different app on another device

The Quicklink **Open With** app is not synchronized between Windows and macOS, since apps on the Mac are not the same as on Windows. Raycast falls back to the default app for the link; once you assign an app on a specific platform, it's remembered for that platform.

The same applies between v1 and v2 devices: v1 identified apps by bundle identifier while v2 uses file paths (to handle multiple installed copies of the same app, e.g. Xcode), so the assigned app is not bridged between v1 and v2 — although it does sync between v2 devices.

### A hotkey or setting reverted to its default after setting up a new device

Settings, categories, hotkeys, and extension state can be clobbered when a new device first merges into your synced data. We are working on mitigating these enrollment issues. Note that hotkey conflict detection is also incomplete: same-platform hotkey sync is supported, but cross-platform behavior and conflict handling still need clearer UX.

### I see duplicate items after migrating from v1

Duplicate entities may appear due to the v1-to-v2 migration. Cloud Sync has a de-duplicator, but it is intentionally conservative to avoid removing data it shouldn't.

### Newer edits to a note were overwritten

Opening an unchanged note has been reported to overwrite newer edits made on another device. This commonly happens on iOS devices. We will fix this soon — until then, a recent backup (**Export Settings & Data**) is the safest way to recover lost note content.

### Window layouts lose details between v1 and v2

Window-layout bridging between v1 and v2 is lossy: app identity, Quicklink arguments, and some file URL names can be dropped. Layouts sync fully between v2 devices.

### Still having issues?

If none of the above resolves it, gather the following and send it to us via the [Send Feedback](raycast://extensions/raycast/raycast/send-feedback) command so we can investigate (see [Contact Support](https://manual.raycast.com/contact-support) for more ways to get in touch):

1. **Your OS version** and **Raycast version** (found in **Settings → About**).
2. **Steps to reproduce** the issue.
3. The **devices involved** and their platforms, and whether the issue affects one device or all of them.
4. **Your Raycast logs**: use the built-in **Copy Raycast Logs** command to copy your latest log files to the clipboard, or **Reveal Raycast Logs** to open your log folder.
5. **A screen recording** showing the issue in action.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Cloud Sync. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
