> Source: https://manual.raycast.com/hyper-key
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Hyper Key

> Available on: Mac, Windows

Give your keyboard a whole new layer of shortcuts by turning Caps Lock, a function key, or a single modifier into a dedicated Hyper Key that never clashes with your existing ones.

Hyper Key adds an extra modifier to your keyboard by remapping a key you don't use often. Once it's set, you can record shortcuts on top of it that won't overlap with existing system or app shortcuts. Choose from a left or right modifier, Caps Lock, or a function key.

## Get Started

1. Open **Settings → Keyboard → Hyper Key**.
2. Pick the key you want to use — a left or right modifier, Caps Lock, or a function key.
3. Assign Hyper Key shortcuts to your favorite commands. They appear in Raycast with the ✦ glyph.

![Hyper Key settings in Raycast, showing the key picker and available options](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/power-features/mac-hyperkey-setup.png)

## Settings

- **Hyper Key**: The physical key remapped to the Hyper Key modifiers. Choose **None** to turn it off, **Caps Lock** (`⇪`), any left or right modifier (`⌃ ⌥ ⇧ ⌘`, or `win Ctrl Alt Shift` on Windows), or a function key (`F1`–`F12`).
   - macOS Hyper Key triggers `⌃ ⌥ ⌘`
   - Windows Hyper Key triggers `win Ctrl Alt`
- **Include Shift (⇧)**: Adds Shift to the Hyper Key combo.
- **Quick Press**: Available when your Hyper Key is a non-modifier (Caps Lock or a function key). Choose what a single tap does on its own — **Does Nothing**, **Trigger** the original key (for example, send a real Caps Lock), or **Trigger Escape**.
- **Replace ⌃⌥⌘ with ✦**: Shown when no Hyper Key is set. Raycast still displays your existing `⌃ ⌥ ⌘` (or `win Ctrl Alt`) shortcuts using the `✦` glyph in [Root Search](https://manual.raycast.com/search-bar).
- **Secure Input Compatibility** _(Only on Mac)_: Some apps turn on macOS Secure Input (for example when you focus a password field), which normally blocks the Hyper Key from working until Secure Input is released. Turn this on to keep your Hyper Key shortcuts working in those contexts, without needing a keyboard driver like Karabiner. It's off by default because there are two tradeoffs:
   - While it's on, Right Control (`⌃⏵`) is reserved for the Hyper Key, so you can't use Right Control in your own shortcuts.
   - While Secure Input is active, only your Raycast Hyper Key shortcuts work — other apps' Hyper shortcuts won't fire until Secure Input is released.

   If you frequently hit Secure Input issues with the Hyper Key, it's worth enabling. Otherwise, leave it off to keep Right Control free.

## Troubleshooting

If your Hyper Key isn't firing, first make sure no other app is mapping the same physical key. Karabiner-Elements virtual keyboards, exclusive HID drivers, and other keyboard utilities can intercept the key before Raycast sees it. Turn these off and try again.

If an app is holding Secure Input and your Hyper Key stops working, you can either quit the app holding it, or turn on **Secure Input Compatibility** (in [Settings](#settings)) to keep your Raycast Hyper Key shortcuts working while Secure Input is active.

_(Only on Mac)_ With several keyboards connected, Hyper Key applies to each one independently, skipping any that can't be remapped, such as a keyboard shared over Universal Control. Turning it off restores Caps Lock on all of them.

Raycast includes a built-in diagnostic. From **Settings → Keyboard** with a Hyper Key configured, press the green dot to reveal the **Hyper Key Diagnostic** panel. It shows whether the Hyper Key is currently active, which key it's bound to, and any conflicts it detects, such as other apps, Karabiner, exclusive HID access, or Caps Lock mapping. Use the `↻` button next to **Active** to restart Hyper Key without quitting Raycast.

## FAQ

### Why doesn't Hyper Key work in password fields on macOS?

This is a macOS limitation. Password fields use secure input, which apps can't monitor for security reasons. The only way around it would be to load a kernel driver, which we won't do. It only affects macOS.

### Why isn't Hyper Key working with Caps Lock on macOS?

Open **System Settings → Keyboard → Keyboard Shortcuts… → Modifier Keys** and make sure the Caps Lock action is set to **Caps Lock** (not **No Action** or anything else). The Hyper Key Diagnostic panel flags this as a Caps Lock Mapping Conflict and includes a button that jumps straight to the right macOS setting. If it still doesn't work, copy the log file from the diagnostic panel and send it through **Send Feedback**.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Hyper Key. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
