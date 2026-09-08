> Source: https://manual.raycast.com/ai/dictation
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Dictation

> Available on: Mac, Windows, iOS
> Tier: Pro Exclusive

Press, speak, and Raycast transcribes your words into clean, formatted text — pasted instantly wherever you're working.

Dictation turns speech into clean, formatted text anywhere you type. Trigger with a hotkey, speak naturally, and Raycast removes filler words, fixes punctuation, and pastes the result instantly. On iOS, the Raycast Keyboard brings the same experience to every text field.

[Dictation in Raycast (YouTube)](https://www.youtube.com/watch?v=RUh1KDgSOsc)

## Get Started

When you first open Dictation, you'll get started in three steps:

1. Grant Microphone access (macOS also requires the Accessibility permission for transcriptions to paste directly into your focused app).
2. Pick your input device. We recommend the built-in or wired microphone for the lowest latency.
3. Set your hotkey to trigger Dictation from anywhere without opening Raycast first

> [!TIP]
> On macOS, you can use the `globe` / `fn` key as your dictation hotkey.
> Open **System Settings → Keyboard → Press Globe /{" "}
> `fn` key to** and set it to **Do Nothing** so the system doesn't intercept the press
> first.

_(Only on Mac)_ Dictation's hotkey now supports
multi-modifier combinations (such as `⌥ ⌘`) and single-tap modifier keys (such as
Right `⌘` or Right `⇧`
), so you can pick a trigger that stays out of your way. See [Command Aliases &
Hotkeys](/command-aliases-and-hotkeys#hotkey-types) for how to set them.

Press your hotkey to start a session. The **Dictation Pill** appears above your current app, showing a live waveform and timer. Speak naturally as Raycast handles filler words, punctuation, capitalization, and grammar automatically.

Press your hotkey again to accept or `Esc` to cancel. Your text pastes into the active app, or copies to your clipboard, depending on your settings.

![The Dictation Pill floating on a wallpaper](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/ai/mac-dictation-hero.png)

> [!TIP]
> Prefer hold-to-talk? Hold the hotkey down. Raycast switches to push-to-talk and when you release
> the hotkey, your session ends and recording finishes automatically.

> [!NOTE]
> Each dictation session is limited to **20 minutes** of dictation time. If you reach the limit,
> your session ends automatically and the transcription is processed.

## Personalization

Personalization is where Dictation starts to feel like yours. Fine-tune every transcription with custom instructions, app-aware context, and a vocabulary built around the words and names that matter to you. You can personalize your experience in **Settings → Dictation → Personalization**.

### Custom Instructions

_(Only on Mac)_

Add global guidance to shape how your words are transcribed. Use it to enforce things like spelling preferences, grammar rules, tone, name capitalization, and formatting conventions. These instructions sit above any per-style settings and apply to every transcription.

### App Context

_(Only on Mac)_

With App Context, Raycast reads the frontmost app, including its name, the field you're focused on, and any visible text nearby, then passes that to the transcription model to improve transcription accuracy.

> [!NOTE]
> App Context is used only for that transcription request and is never stored. Once the
> transcription is complete, the context data is discarded.

### Vocabulary

Add words, names, brand terms, or jargon that Raycast should always get right. Entries are passed to the transcription model to improve accuracy when it hears something close to them.

> [!TIP]
> Use the **Add Word to Vocabulary** command to add a term without opening
> Settings. Type the word as an argument, or leave it empty to use the word you have selected.

## Styles

_(Only on Mac)_

Styles shape your dictated text for different contexts. One spoken sentence becomes a tight Slack one-liner, a properly punctuated email, or any other format you define. You can control your transcription styling in **Settings → Dictation → Styles**. Your styles sync across devices with [Cloud Sync](https://manual.raycast.com/cloud-sync).

### Auto Styling

**Auto Styling** picks the right style for the app or website you're dictating into. **Email** style in Mail, **Messaging** style in Slack, or a custom "Code Comments" style in your editor. When **Auto Styling** is off, Raycast still applies baseline cleanup but you don't get app-aware formatting on top.

### Custom Styles

Two styles come built in to Raycast. **Email** can format greetings, sign-offs, add paragraph breaks, and full punctuation. **Messaging** keeps transcriptions short, casual, and lightly punctuated for communication apps.

> [!TIP]
> You can adjust which apps and websites trigger each built-in style. If you use an app or website
> for email that isn't in our list, add it to the **Email** style to get the same formatting.

Create your own style using the ** Create Style** option in Settings, or use the **Create Style** command and give your style a **Name & Icon**, **Prompt**, and a list of **Apps & Websites** it should apply to. If you're in a Raycast team, use **Organization** to choose whether the style is personal or shared with your organization.

![The Create Style dialog with a custom style named 'steph style', a prompt with formatting rules, and a list of apps and websites it applies to](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/ai/mac-dictation-customstyle.png)

A style prompt tells the AI how to clean up your transcript to match your expected output. Describe the artifact (meeting notes, agenda, PR review), the voice, and spell out mechanics (punctuation, capitalization, numerals, emojis).

## Dictate to Note

Use the **Dictate to Note** command to skip dictating to the active app entirely and save the transcription as a new [Note](https://manual.raycast.com/notes). Useful for capturing ideas, voice memos, or meeting takeaways that you want to keep alongside your other notes without using another app or website.

## Dictate in AI Chat

When AI Chat pauses to ask you something, you don't have to switch back to the keyboard. While an [Ask User Question](https://manual.raycast.com/ai/ai-chat#ask-user-question) tool or a confirmation prompt is active, press `Ctrl M` to dictate your response. These composers don't show a microphone button since they're already busy, so `Ctrl M` swaps the available actions for the dictation pill.

![Dictating a response to an Ask User Question prompt in AI Chat, with the dictation session running in the composer](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/ai/mac-aichat-inlinedictation-askuserquestion.png)

## Dictation History

Every transcription is saved to the **Dictation History** command so you can find and reuse it later. You can use the actions in the Action Panel to either **Paste**, **Copy to Clipboard**, **Delete Transcription** for the selected transcription, or **Delete All Local Transcriptions** to remove them all.

![The Dictation History command in Raycast](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/ai/mac-dictation-history.png)

> [!TIP]
> Use the **Get Last Transcription** command (previously **Copy Last
> Transcription**) to quickly copy the last transcribed text, or paste it into the active app,
> without needing to open the **Dictation History** command.

## Settings

All Dictation settings live under **Settings → Dictation**, including your preferred input device, general behavior options, and usage statistics.

![Settings open on the Dictation pane, showing activity graph](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/ai/mac-dictation-graph.png)

### Statistics

Over time, Dictation builds up a picture of your usage through statistics. You'll see your average WPM, estimated time saved, and total words dictated.

Activity also displays a graph of when you're using dictation the most.
Your stats are computed entirely on your device from your local transcription history. Statistics
are not sent to Raycast as analytics nor telemetry.

### Microphone

By default, Raycast uses your System Default microphone provided by the OS when **Use System Default** is turned on. You can customize your microphone priority list to switch between input devices throughout the day by turning **Use System Default** off.

Use **the drag handle** to reorder microphones by priority, or press **the ellipsis** to exclude a microphone from the list. Your currently active microphone appears in green at the top.

### General

- **Language**: Select a specific dictation language, or leave on **Auto** to detect what you're speaking each time.
- **Output Action**: Paste the transcript directly into your active app (Default), or copy to your clipboard.
- **Sound Effects**: Play feedback when dictation starts or stops.
- **Mute While Recording**: Mute system audio while a session is active.
- **Finish and Cancel Shortcuts**: Choose the shortcut used to finish or cancel dictation.
- **Context-Aware Paste** (experimental): Adapts each transcription to the text right before your cursor, adding a leading space mid-sentence and matching capitalization.
- **Auto Submit** (experimental): Presses `↵` (or `⇧ ↵`) after a transcription is pasted, either every time or only when you finish speaking with a chosen keyword.

> [!TIP]
> If you regularly dictate while using other apps and need `↵` to behave normally (for
> new lines, sending messages, etc.), turn **Allow Enter Hotkey** off and use your **Dictate**
> hotkey to accept transcriptions instead.

## Migrate from Another App

If you're coming from another dictation app, Raycast can bring your setup
with you. Migration imports your **vocabulary** and your **hotkey**, so you can get started quicker.

You'll be prompted when getting started with Dictation for the first time, or you can migrate later from **Settings → Dictation**. The option only appears if you have one of the supported apps installed:

- _(Available on Mac and Windows)_ **Wispr Flow**
- _(Only on Mac)_ **Superwhisper**
- _(Only on Mac)_ **MacWhisper**
- _(Available on Mac and Windows)_ **Aqua Voice**
- _(Only on Mac)_ **VoiceInk**
- _(Available on Mac and Windows)_ **Handy**

Raycast asks you to confirm first, then reports what came across: how many vocabulary words were added, and whether your hotkey was imported or skipped because another command already uses it.

## Permissions

Dictation needs Microphone access to record your voice. On macOS, it also needs the Accessibility permission so transcriptions can paste directly into your focused app — grant both in **System Settings → Privacy & Security**. Raycast prompts during setup if permissions are missing.

## Privacy

Dictation is private by default. Your voice is never used to train AI models, audio isn't retained on Raycast servers, and your transcriptions and statistics are stored locally on your device. For full details on how your audio and transcriptions are handled, see [Raycast AI Privacy & Security](https://manual.raycast.com/ai/raycast-ai-privacy-security#dictation).

## Dictate on iOS

_(Only on iOS)_

Dictation lives inside the [Raycast Keyboard](https://manual.raycast.com/ios/keyboard) and enables you to dictate from most text field in apps on your iPhone or iPad.

![Dictation listening in the Raycast iOS app, with the Raycast AI Dynamic Island activity at the bottom of the screen](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/ai/ios-dictation-app.png)

### iOS Get Started

Install and enable the Raycast Keyboard before using Dictation. See [Keyboard](https://manual.raycast.com/ios/keyboard) for setup instructions.

1. In any app, tap a text field and switch to the Raycast Keyboard using the Globe icon.
2. Tap the waveform button button in selector on the Keyboard, then tap Waveform button to begin dictating. At the beginning of a dictation session, you will be redirected to the Raycast app – this is necessary since iOS keyboards don't have direct microphone access.
3. Speak naturally. Raycast handles filler words, punctuation, capitalization, and grammar automatically.
4. Stop the recording with Stop Filled button or from the Live Activity. The cleaned-up text is inserted into your text field, or held for review, depending on your [**Insert Mode** setting](https://manual.raycast.com/ai/dictation#insert-mode).

> [!WARNING]
> As of iOS 26.4, Apple removed the ability for keyboards to detect the host app's bundle ID, so
> after dictating you'll need to swipe back to your previous app manually. We hope this is resolved
> in a future iOS update.

#### Dictation Session

After you start a dictation session, Raycast keeps a **5-minute session** alive in the background so you can dictate multiple times without recording to the app each time. While a session is active, you'll see a Live Activity. Tap it to control or end the session. You can also end it from the main app by tapping the power button.

Don't want a background session? Toggle **Disable Session** in **Raycast for iOS Settings → Dictation** to end it immediately, or after 5 minutes, 10 minutes, 15 minutes, 30 minutes, or 1 hour.

### Insert Mode

By default, the dictation is inserted into your text field automatically. You can change the insertion mode by completing the following settings:

1. Open the Raycast app.
2. Tap your profile in the top right.
3. Tap **Keyboard** then change **Insert mode** to one of the following; Auto-insert, Review first, or Review on AI command.

### Post-Processing

iOS Dictation includes the same concept as Styles, and allows you to run your dictation through a post-processing flow on top of the standard dictation cleanup to modify the output before inserted.

You can select the post-processing option under the Dictate button in the Raycast Keyboard, and choose from one of the following options:

- **Email**: Format your output for email
- **Notes**: Format your output for note-taking
- **Custom [AI Commands](https://manual.raycast.com/ai/ai-commands)**: Your own prompts, ideal for personal writing styles, translation, or specific tone adjustments

## Troubleshooting

Dictation turns your speech into text anywhere on your system. Most issues come down to language detection, microphone selection, or the trigger key. Here are the common ones.

### Dictation transcribes the wrong language

Dictation auto-detects the language you speak, and detection can slip between similar-sounding languages (for example Chinese being transcribed as Japanese or Korean).

To fix it, set your language explicitly in **Settings → Dictation → General** instead of relying on auto-detect. If you regularly switch languages, add the ones you use so the dictation post-processing task has a smaller set to choose from.

### Words are consistently misheard

If transcriptions are inaccurate, work through these in order:

- **Check your input device.** Make sure the right microphone is
  selected and actually usable — a common cause is the built-in laptop
  mic being used while the lid is closed (clamshell mode), which muffles
  or blocks audio. Switch to an external mic or open the lid. See
  [My microphone isn't listed](#faq-dictation-microphone) below.
- **Add tricky terms to Vocabulary.** For names, jargon, or technical
  terms that are repeatedly mistranscribed, add them under
  **Settings → Dictation → Personalization**.
- **Compare against the raw transcription.** On a successful
  transcription, open **Dictation History**, select the entry, and
  choose **Copy Raw Transcription** from the main Action Panel (`⌘ K`/`Ctrl K`).
  If the raw text is accurate but what got inserted wasn't, the issue is
  in post-processing rather than recognition.
- **Reduce background noise** and speak at a steady pace and volume
  close to the mic.

### My microphone isn't listed (clamshell or external mic)

In clamshell mode (laptop closed with an external display), or with some external and Bluetooth mics, the device may not appear or get selected automatically.

Open the microphone picker in **Settings → Dictation → Microphone** and make sure the device isn't in your excluded list. If it's still missing, check the microphone is detected in **System Settings** on macOS and **Windows Settings** on Windows.

### There's a delay before dictation starts, or input lags

A few seconds of lag
between pressing the trigger and Dictation responding is usually a hotkey or startup-cost issue.
Try a simpler trigger key, make sure no other app is bound to the same shortcut, and check that
your mic isn't being held by another app.

### I want to trigger Dictation with a single key (F5, right Option, etc.)

You can bind Dictation to a single key in **Settings → Dictation → Commands**. If you're on macOS
and pick an fn/Globe or function key (F1–F12) that doesn't register, disable "Use F1, F2, etc.
keys as standard function keys" in **System Settings → Keyboard → Keyboard Shortcuts → Function
Keys**. After that the key is captured correctly.

### Comparing the transcription with the raw model output

If a transcription doesn't match what you said, you can check the unedited
  model output to see whether the issue came from transcription or from
  post-processing. Open **Dictation History**, select the transcription, and in
  the Action Panel (`⌘ K`/`Ctrl K`) choose **Copy Raw Transcription**. Compare it with the
  cleaned-up text that was inserted.

This is only available for successful transcriptions. For a failed one, the
only action offered is **Retry** (macOS only).

### Finding the original audio recording

Raycast keeps recent recordings so you can retry or inspect them. In
**Dictation History**, open the About Panel (`⇧ ⌘ K`/`Ctrl Shift K`) and
choose **Open Recordings Directory**.

Recordings are saved as `.wav` files in
`<Application Support>/dictation-recordings`. Only the most recent 25 are
kept; older ones are pruned automatically.

### Still having issues?

If none of the steps above resolve your issue, please reach out to our
  support team. To help us diagnose the problem quickly, include the
  following:

1. **The raw transcription** of an affected session: in **Dictation
   History**, select the entry and choose **Copy Raw Transcription** from
   the main Action Panel (`⌘ K`/`Ctrl K`). Available on successful transcriptions
   only.
2. **The audio recording** of a bad session: in **Dictation History**,
   open the **About Panel** (`⇧ ⌘ K`/`Ctrl Shift K`) and choose **Open
   Recordings Directory** — note this is in the About Panel, _not_ the main Action
   Panel. Sessions are saved as `.wav` files (the last 25 are kept);
   attach the one that transcribed badly.
3. **Your input setup**: which microphone you're using, and whether
   you're in clamshell mode or on an external/Bluetooth device.
4. **Your OS version** and **Raycast version** (**Settings →
   About**).
5. **Your Raycast logs**: use the **Copy Raycast Logs** command to copy
   your latest logs, or **Reveal Raycast Logs** to open the log folder.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Dictation. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
