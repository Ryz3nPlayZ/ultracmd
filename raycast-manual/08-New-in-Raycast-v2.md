> Source: https://manual.raycast.com/new-in-v2
> Scraped from the Raycast Manual (https://manual.raycast.com)

# New in Raycast v2

Tour what's new in Raycast v2, including a redesigned UI, improved hotkeys, AI Agents, Memory, branching chats, Personalization, and more.

Welcome to the brand new Raycast, rebuilt from the ground up for the next era of personal computing. **It's faster everywhere, the AI knows you now, and your hotkeys finally work the way you set them.**

Take a tour below of what's new in Raycast v2 to discover what's different. A full list of changes is available under [Everything New in v2](#everything-new-in-v2) at the bottom of this page.

## Fresh Design

Raycast has been redesigned for Liquid Glass to fit right at home on your Mac. Compact window mode strips Raycast back even more to the essentials, and grids in [Emoji & Symbols](https://manual.raycast.com/emoji-symbols) and [Screenshots](https://manual.raycast.com/screenshots) let you choose how many columns you see, so you decide how much fills the window.

![Compact mode in Raycast v2](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/new-in-v2/newinv2-design-compact.png)

## Search Files and Settings

Type a filename or folder into Root Search and the File Search results will show alongside other results, no separate command needed. File Search also runs on a new indexing engine, with faster results and more ways to filter them. Settings has its own search now too, covering every extension, command, and setting.

![File Search results in Root Search](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/new-in-v2/mac-newinv2-fsroot.png)

Learn more about [File Search](https://manual.raycast.com/file-search).

## Even More Shortcuts

The hotkey recorder is quicker and more reliable, and it understands the keyboard you actually use. You can now use `fn` as a hotkey on its own, assign left and right modifiers separately, or set a hotkey straight from the Action Panel in the launcher.

![Hotkey recorder in Raycast v2](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/new-in-v2/newinv2-design-hotkeyrecorder.png)

Learn more about [Command Aliases & Hotkeys](https://manual.raycast.com/command-aliases-and-hotkeys).

## Ask AI, Anywhere

Ask a question in Root Search and Quick AI is there to answer it. It's been redesigned to match AI Chat, making it a familiar experience across both. Make Quick AI your fallback command and anything that isn't a command goes straight to AI.

![Quick AI answering a question in Raycast v2](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/new-in-v2/mac-newinv2-quickai.png)

AI Chat can branch off any message to explore a different direction without losing the original thread. As a conversation nears its context limit, Raycast summarizes the earlier turns and keeps going.

AI Extensions load in automatically when they're relevant, and Screen Awareness brings whatever is in front of you into the conversation: the focused window, your selection, and a screenshot, sent along with your question. The chat sidebar is new too, with folders to group related chats and auto-archiving to keep the rest tidy, plus notifications when a reply lands while you're in another app.

![AI Chat sidebar with folders](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/new-in-v2/mac-newinv2-aichatfolders.png)

Learn more about [Quick AI](https://manual.raycast.com/ai/quick-ai), [AI Chat](https://manual.raycast.com/ai/ai-chat), and [Screen Awareness](https://manual.raycast.com/ai/screen-awareness).

## A More Personal AI

Raycast AI now carries context about you between conversations. Profile is what you tell it about your job, interests, values, or preferences like writing styles. Memory is what it picks up about you throughout your chats.

Agents replace Presets as reusable setups you switch into, and Skills give the model instructions and knowledge for the tasks you repeat.

Learn more about [Personalization](https://manual.raycast.com/ai/personalization), [Agents](https://manual.raycast.com/ai/agents), and [Skills](https://manual.raycast.com/ai/skills).

## Talk Instead of Typing

Dictation lays down clean, formatted text in the app you're in, filler words and punctuation handled. It picks up whichever language you're speaking, or you can set one yourself in Settings.

Auto Styling matches the tone to where you are, so the same words land as an email in Mail and a quick message in Slack, and Styles let you write your own prompts per app or website.

![The Dictation Pill floating on a wallpaper](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/ai/mac-dictation-hero.png)

Learn more about [Dictation](https://manual.raycast.com/ai/dictation).

## Everything New in v2

Every change in Raycast v2, grouped by where you'll find it.

### General

- A fresh new look and feel across the app, redesigned for macOS Tahoe.
- A simpler, cleaner compact mode that's easier to scan at a glance.
- Application symlinks now show up in Root Search, so you can launch them just like any other app.
- **Raycast in Raycast**: more reliable copy and paste between Raycast surfaces, for example pasting a Quick AI response into a Raycast Note.
- Search in the Settings sidebar, allowing you to quickly find any extension, command, or preference across Settings.

### Shortcuts

- A new and improved hotkey recorder that's quicker and more reliable to set up.
- Use the `fn` key on its own as a single-tap modifier, perfect for a quick shortcut without holding multiple keys.
- Support for single-tap `fn` key and double tap modifiers.
- Improved support for international keyboards. You can now record your hotkeys as either physical or key-equivalent keys.
- Better detection when shortcuts overlap, with a clear option to overwrite the existing one.
- Assign hotkeys and aliases right from the Action Panel in Root Search, no need to dig into **Settings**.
- You can now assign left and right modifier keys as hotkeys. Simply click on the key when you set it up in the Action Panel in Root Search or directly in **Settings → Shortcuts**
- Single-modifier and multi-modifier hotkeys work on Windows too, not just macOS.
- _(Only on Mac)_ Holding both keys of the same modifier at once (left and right `⌘` together, for example) can be its own hotkey, separate from a `⌘ ⌘` double tap. See [Hotkey Types](https://manual.raycast.com/command-aliases-and-hotkeys#hotkey-types).
- Hyper Key is more reliable, with new diagnostics for conflicts with other apps, Karabiner remappings, and system keyboard remappings.
- New **Secure Input Compatibility** option keeps your Hyper Key shortcuts working even while an app has macOS Secure Input active (such as a focused password field), without needing a keyboard driver like Karabiner.

### File Search

- Now powered by a new indexing engine for faster results and more ways to filter.
- Files and folders can now be found right in Root Search, so you don't need a separate command to look them up.

### Snippets

- Added support for tagging, so you can organize and find snippets faster.
- Major reliability improvements for snippet expansion across Chromium and Electron apps, plus better handling of multiline snippets. Shorter snippets also expand faster.

### Quicklinks

- Added support for pinning, so your most-used Quicklinks always stay at the top.
- Added support for tagging to keep large collections of Quicklinks organized.
- Added **Prefer Existing Tabs**, which focuses an already-open tab when launching a Quicklink instead of opening a new one.
- **Create Quicklink** now autofills the path of the selected file when Finder is active.

### Clipboard History

- Clipboard capture is now more reliable: Raycast detects changes directly instead of polling every 0.75 seconds, so fast consecutive copies are no longer missed.
- More reliable detection of the source app for each clipboard entry.
- Raycast now saves every original format you copied and lets you restore them, so pasting always matches the source.
- Rename clipboard entries to make them easier to find later.
- When you copy multiple files or pieces of content at once, they're now grouped together as a single clipboard entry.
- Refreshed UI for browsing history, with several visual improvements over v1.
- When pasting, you can now prefer plain text over the original formatting. Enable "Prefer pasting as plain text" in settings to strip rich formatting automatically.
- Copy text directly from QR codes found in images stored in your clipboard history.

### Translator

- Set default source and target languages so you don't have to pick them every time.
- Create custom commands with predefined language pairs, so you can jump straight into translating your most-used languages without picking them each time.
- New **Use Selected Text as Source** setting. When it's on, triggering the translator via hotkey automatically fills in whatever you have selected.
- Inline translation with the `in` suffix, so you can translate right as you type.

### Emoji & Symbols

- Multiple grid size options, so you can pick the layout that suits you best.

### Screenshots

- **Column Count**: choose between 3, 4, 5, or 6 columns in the Search Screenshots grid to tune thumbnail size and density to your liking.

### Calendar

- New **Create Event** command for adding events without leaving Raycast.

### Calculator

- Added syntax highlighting so expressions are easier to read at a glance.
- Several new syntax to use in Calculator, including:
  - **Work hours and days**: `workhours in 2023`, `55h in workdays`.
  - **Pixel calculations**: `2 inches in px at 72 ppi`.
  - **Trigonometry**: `cot`, `csc`, plus hyperbolic, inverse, and degree variants (`coth`, `csch`, `acot`, `acsc`, `cotd`, `cscd`, `acotd`, `acscd`).
  - **Time diff shorthand**: `time diff Paris`, `diff Paris`.
  - **Date/time expressions**: `time in 4 hours [in San Francisco]`, `3 days from now at 4:39pm`, ISO 8601 Zulu.
  - **Calendar arithmetic**: `August 5 + 5` (days), `3:45pm + 5` (hours), `8am to 4pm`.
  - **Percentage phrases**: `20% discount off $500`, `5% gratuity on $95`.
  - **Percentage ratios**: `20% of 500, 90-30%`.
  - **Percentage elapsed**: `day percentage`, `week %`, `year percentage`.
  - **US customary units**: `5 feet 3 inches in cm`; more `ft`/`in` aliases.
  - **Unit shorthands**: `mo`, `yr`, `deg`.
  - **Currency shorthand**: `USD1K`; `10K` = 10,000 (`10 K` = kelvin); `kilo` as a synonym for `kg`; no-space `1kUSD`.
  - **Cities and airports**: 119 new tourist destinations and airports; multi-word resolution (`London Heathrow`); aliases for multi-airport cities.
- Other fixes and improvements to existing syntax and expressions.

### Window Management

- New **Switch to Next Space** and **Switch to Previous Space** commands to jump between Spaces without the macOS animation.

### Dynamic Placeholders

- New `{calculator}` placeholder for inline math, available in **Snippets**, **Quicklinks**, and **AI Commands**.

### AI

**Quick AI**

- Redesigned to match AI Chat, with a more powerful composer for richer prompts.
- Tool calls and AI Commands now show richer detail. Expand any run to inspect the inputs the model passed.
- Added Quick AI as a fallback command (**Settings → Launcher → Fallback Commands**).

**AI Chat**

- Presets are now called **Agents**, and they're reused across chats. Update an agent's configuration once and the change applies to every chat that uses it. Learn more on the [Agents page](https://manual.raycast.com/ai/agents).
- Added **Memory** so chats remember context about you and feel more personal. Learn more on the [Personalization page](https://manual.raycast.com/ai/personalization).
- Added **Skills** so you can give Raycast AI custom instructions and knowledge for the tasks you do often. Learn more on the [Skills page](https://manual.raycast.com/ai/skills).
- Skills and AI Extensions are now loaded into the chat automatically when they're relevant, so you don't need to mention them manually.
- Tool calls and AI Commands now show richer detail. Expand any run to inspect the inputs the model passed.
- A redesigned history sidebar groups your chats into **Pinned**, **Folders**, **Recent**, and **Archived**, where v1 only had pinning. See [Folders](https://manual.raycast.com/ai/ai-chat#folders).
- Added **Folders** so you can group related chats together, with drag and drop between sections and a right-click menu anywhere in the sidebar.
- Chats can be auto-archived after a set period, keeping your sidebar tidy without any manual cleanup.
- Branch off any message in a chat to explore a different direction without losing the original thread.
- Raycast AI can now pause to ask you a short multiple-choice question when a request is ambiguous, so it can confirm the right direction before continuing.
- Added **[Background Notifications](https://manual.raycast.com/ai/ai-chat#background-notifications)** so you get notified when a chat finishes responding in the background.
- Long chats now keep going instead of hitting a wall. As a conversation approaches its model's context limit, Raycast summarizes the earlier turns for you and continues from there. See [Long Conversations](https://manual.raycast.com/ai/ai-chat#long-conversations).

**Screen Awareness**

- New **Screen Awareness** lets you ask Raycast AI about whatever you're looking at. It reads the focused app's content, the text you have selected, and a screenshot of the window, then sends the lot to AI with your question.
- Attach it in AI Chat or Quick AI with **Focused Window**, run **Send Focused Window to AI** from a hotkey, or mention `@screen-awareness` and let the model look for itself. Learn more on the [Screen Awareness page](https://manual.raycast.com/ai/screen-awareness).

**AI Commands**

- New **Quick Fix** runs the **Fix Spelling and Grammar** command in any focused app with a single hotkey. Learn more on the [AI Commands page](https://manual.raycast.com/ai/ai-commands#quick-fix).
- New **Output Behavior** option lets each command either **Open in Raycast** or **Replace Selection** in place.

**Personalization**

- Added **Profile**, where you can jot down context about yourself (role, preferred tools, communication style) that Raycast AI uses across conversations.
- Added **Memory**, an automatic summary Raycast AI builds from your conversations over time, picking up on your projects, preferences, and goals.
- Both are fully editable, and you can turn them off any time in **Settings → AI → Personalization**.

### Dictation

- Dictation turns speech into clean, formatted text and pastes it directly into the app you're in, with filler words and punctuation handled for you.
- **Auto Styling** picks the right tone for where you're typing, so dictation in Mail comes out as an email and dictation in Slack comes out as a quick message.
- **Custom Vocabulary**, **Instructions**, and **Styles** let you teach Dictation your spellings, your tone, and your own per-app templates.
- Press or hold to talk. Tap the hotkey to start and stop, or hold it down for push-to-talk, with the Dictation Pill keeping you in flow.
- **Dictation History** gives you back every past transcription, ready to paste, copy, or delete.
- Added **[Dictate in AI Chat](https://manual.raycast.com/ai/dictation#dictate-in-ai-chat)** so you can answer AI Chat's questions and confirmation prompts by voice with `Ctrl M`.

### Coming Soon

Some features from Raycast v1 aren't available just yet in v2 but will arrive in a later update, including:

- Flight tracker in Calculator
- Local Models
- Custom Providers

## Switching from v1

### What changes with the v2 update?

This is the moment when we come out of beta and Raycast becomes one app again.

For macOS users, this update will replace Raycast v1 and the v2 beta on your machine with the general Raycast v2 release. Your v2 beta data will remain unchanged, and during the migration process, you will have the option to import your v1 data if you have not already done so. Some permissions may need to be re-authorized because they are inherited from v1.

For Windows users, Raycast v2 is the version you have been using from the start. The most important change is that all features that were free during the beta will now be available on the Pro plan. See [What happens to all of my features that were free during the beta?](#faq-v2-free-features) below.

### What do I need to do to update to v2?

With this release, all macOS beta users will see an in-app notification prompting them to update. Simply follow the instructions provided.

For all v1 users who are not yet using the beta, we invite you to download the new 2.0 version. You will be migrated to v2 during installation. If you download Raycast 2.0 manually and already have Raycast installed, macOS will ask whether you want to replace the existing app or keep both. Choose **Replace**. If you keep both, you will end up with two copies of Raycast and the old one will keep launching.

Some permissions may need to be re-authorized since they are inherited from v1.

For Windows users, you do not need to do anything. You will either be updated automatically, or you can select **Check for Updates** to update as usual.

We have the following system requirements:

- **macOS**: Tahoe (Apple silicon)
- **Windows**: Windows 10 or later (x64 or ARM)

### I chose "Keep Both" when installing. How do I fix it?

You now have two apps in your Applications folder, `Raycast` and `Raycast 2`. The one that opens is still v1, which is why v2 seems to be missing.

To fix it:

- Quit Raycast.
- Delete both `Raycast` and `Raycast 2` from your Applications folder.
- Download Raycast 2.0 again and install it.

### Do I need to re-import my v1 data during the migration process?

If you have already imported your v1 data and are using the beta as your daily driver, you do not need to re-import it. The option is available for those who are still using v1 and have fresh data to import.

Please note that when you import v1 data, your v1 settings and hotkeys will override those currently configured in v2. During this step, you can choose which data to import if you do not want this to happen.

Some permissions may need to be re-authorized since they are inherited from v1.

### What happens to all of the features that were free during the beta?

All features that were free during beta will now be available on the Pro plan. This includes Dictation and AI features, as they were always intended to be.

To help ease the transition, you can try out Raycast Pro with a seven-day free trial to continue experiencing these features before subscribing. The trial can be accessed by simply signing in, no credit card is required.

### I'm on the Enterprise plan. Should I update?

Users on an Enterprise plan should refrain from updating to Raycast v2 for now. We are working directly with your teams to move to the new version.

### How do I install custom extensions in the new version?

For custom extensions to import correctly, you need to be on the latest version of Raycast v1, or at least `v1.104.16`.

If these did not automatically import, you can do it manually by running `npx @raycast/api@latest dev` and the dev command should be clever enough to pick up the new version if it's running.

### As an extension developer, should I continue supporting both v1 and v2?

Raycast v2 is the new version of Raycast going forward and all extension developers should focus on this version when creating extensions. 

Our team will still be able to test on v1, so extension updates should receive some testing on both versions during pull request reviews.

- [Get Raycast v2](https://raycast.com/): Run the **Check for Updates** command or download now from our website
- [The Technical Story](https://raycast.com/blog/a-technical-deep-dive-into-the-new-raycast): Read the blog post on how the team built the new Raycast


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with New in Raycast v2. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
