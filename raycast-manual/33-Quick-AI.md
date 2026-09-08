> Source: https://manual.raycast.com/ai/quick-ai
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Quick AI

> Available on: Mac, Windows
> Tier: Pro Exclusive

Ask Raycast AI a one-off question from Root Search and get an answer in the same window, with follow-ups and context when you need them.

Quick AI lets you ask Raycast AI a one-off question from [Root Search](https://manual.raycast.com/search-bar) and get the answer in the same window. Type your question, press `Tab`, and read the response without interrupting your flow. When a question grows into something bigger, hand the whole conversation over to [AI Chat](https://manual.raycast.com/ai/ai-chat) with a single keystroke.

![Quick AI in Raycast](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/ai/mac-ai-quickai.png)

## Open Quick AI

There are three ways to start:

- From Root Search: Start typing your question, then press `Tab`. Raycast hands your text to Quick AI and submits it.
- Run the **Quick AI** command directly from Root Search to open with an empty prompt.
- Set Quick AI as a fallback command in **Settings → Launcher → Fallback Commands** to send any unmatched Root Search text straight to Quick AI when you press `↵`.

Pressing `Tab` from Root Search always opens Quick AI, even with no text typed, so you can start fresh.

## Ask a Question

Type your prompt and press `↵` to submit. Quick AI streams the answer back in the same window.

On the response, `↵` pastes the answer into the previously focused app by default. To swap the default to copy instead, open **Settings → AI → Commands → Quick AI → Primary Action**.

When a response includes code, it appears in a code block with the detected language and a copy button. Long lines scroll sideways by default. Click **Enable line wrap** in the top right of the block to wrap them to the response width, and click again to switch back.

![Enable line wrap button in a Quick AI code block](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/basics/mac-quickai-enablelinewrap.png)

## Follow-ups

Keep typing after a response to ask a follow-up. Quick AI is a full conversation, not a single-shot Q&A.

- Regenerate the last response with the same model: `⌘ R`/`Ctrl R`
- Regenerate the last response with a different model: `⇧ ⌘ R`/`Ctrl Shift R`
- Start a fresh conversation: `⌘ N`/`Ctrl N`
- Navigate between recent Quick AI chats: `⌘ [`/`Ctrl [` and `⌘ ]`/`Ctrl ]`

## Attach Context

Open the ** Add Context** menu to the left of the composer, or type `@`, to attach something to your question.

Quick AI can capture what you're looking at through Screen Awareness:

- **Focused Window**: A full capture of the app in front of you, including its content, your selection, and a screenshot.
- **Selected Text**: Whatever you've highlighted in another app.
- **Selected Area** or **Entire Screen**: A screenshot captured from your desktop.

Attachments are scoped to the message you send them with, and they come along if you continue the conversation in AI Chat, which accepts a wider set of context. Learn more on the [Screen Awareness page](https://manual.raycast.com/ai/screen-awareness).

**Send to AI** commands open AI Chat by default. To have them go to Quick AI instead, change the command's **Primary Action** in **Settings → Screen Awareness**.

## Collapsed Messages

To keep conversations easy to scan, long messages you send are collapsed in both Quick AI and AI Chat. A collapsed message shows its first part with a **Show more** control to expand it, and a **Collapse** control to fold it back once expanded.

![A long message collapsed in a Raycast AI conversation with a Show more control](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/ai/mac-chat-collapsedmessages.png)

Only long messages collapse: A message over 10 lines (or a comparably long single paragraph) is collapsed, while shorter messages are always shown in full.

## Ask User Question

Sometimes the AI needs a bit more direction. When a request is ambiguous or the model isn't sure how to proceed, it can pause and show you a short multiple-choice question right in the conversation. Pick an option and it continues with your answer. This works in both Quick AI and AI Chat and is always on — there's no setting to turn it off.

To reliably trigger it, ask for it in your prompt: Either name the tool directly ("use the ask questions tool") or describe the flow ("do X, then ask me to choose Y").

Try it: Paste either of these into Quick AI:

```text
Set up a new project folder for me and ask me to choose from the available options
```

```text
Use the ask questions tool and quiz me about who are the cofounders of Raycast
```

Because these requests leave out details (where to create the folder and what to call it, or how many questions and how hard), the AI will typically ask a clarifying question with a few options before doing anything.

![Raycast AI pausing to ask a multiple-choice question about Raycast's co-founders](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/ai/mac-aichat-askquestions.png)

You can also answer by voice: While a question or confirmation prompt is active, press `Ctrl M` to dictate your response. Learn more on the [Dictation page](https://manual.raycast.com/ai/dictation).

## Models

Configure the AI models used across Quick AI, AI Chat, and Custom AI Commands from **Settings → AI → Models**, or use the **Manage Models** command to jump straight there. Learn more on the [AI Commands page](https://manual.raycast.com/ai/ai-commands).

### Switch Models

Open the Action Panel (`⌘ K`/`Ctrl K`) and pick **Change Model** to switch the active model mid-conversation, or **Regenerate with Model…** to try the last answer on a different model.

You can also set a default in **Settings → AI → Commands → Quick AI → Default Model**.

### Default Models

Pick the default model for each surface:

- **Quick AI**: The model used when you ask a quick question from Root Search.
- **AI Chat**: The default for new chats. Set to **Last Used Model** to continue with whichever model you used most recently.
- **Custom AI Commands**: The default for any AI Command that doesn't specify its own model.

When a model supports reasoning effort, each row also shows a dropdown for it, with the recommended option marked **Default**. Your choice carries over between models that support it, or resets to the new model's default. The same control appears in Custom AI Command settings whenever a specific model is used instead of **Last Used Model**.

### Manage Models

Choose which models appear in the model pickers across Quick AI, AI Chat, and Custom AI Commands:

- **Review model details**: Each model lists its Speed, Intelligence, and Context window so you can compare capabilities at a glance.
- **Enable or disable models**: Toggle the checkbox next to a model to control whether it shows up in pickers. Disabled models are hidden everywhere AI models can be selected.

![Toggling a model on or off in Manage Models](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/basics/mac-settings-aimodels-toggle.png)

- **Group by Provider**: Models are grouped by their provider (e.g. Raycast, Anthropic). Expand or collapse a provider to focus on a subset.
- **Sort the list**: Use the sort menu in the top-right to order models by Brand, Alphabetically, Speed, Intelligence, or Context Window.

![Sort menu in Manage Models](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/basics/mac-settings-aimodels-sort.png)

## Continue in AI Chat

When a question grows into something bigger, press `⌘ J`/`Ctrl J` to move the conversation into AI Chat. The full history, model, and any attachments come with it, and you get the chat workspace, longer context, and tools. Learn more on the [AI Chat page](https://manual.raycast.com/ai/ai-chat).

## Auto-new Chat

Quick AI starts a fresh chat after a period of inactivity, so you don't accidentally tack new questions onto an older conversation. Adjust the timeout in **Settings → AI → General → Start New Chat** (options: 5 minutes, 10 minutes, 15 minutes, 30 minutes, 1 hour, always, never).

This same inactivity timer also determines whether a [Send to AI](https://manual.raycast.com/ai/ai-chat#attach-context) command reuses your active chat or starts a new one when AI Chat is closed.

## Settings

Tune Quick AI from **Settings → AI → Commands → Quick AI**:

- **Quick AI Default Model**: Default model used when opening Quick AI.
- **Primary Action**: Paste to active app or copy the response to clipboard on `↵`.
- **Tab Shortcut**: Hide the `Tab` hint in Root Search (the shortcut still works).

A few settings under **Settings → AI → General** apply to Quick AI as well as AI Chat:

- **Start New Chat**: Start a new chat after the specified timeout when opening Quick AI.
- **Conversation History**: Show conversations from AI Chat and Quick AI combined or keep them separate.

## Troubleshooting

Quick AI lets you talk to a model from Root Search. Most reports come down to the trigger key, model selection, sync, or hitting a usage or context limit. Here are the common ones.

### Tab doesn't open Quick AI, or stops working

Quick AI opens by typing your question in Root Search and pressing Tab. If Tab doesn't enter Quick AI, check that no other Tab-completion behavior is taking priority. Tab also opens Quick AI with an empty search, so you can start fresh.

### The model keeps resetting or picks the wrong one

Set your preferred model in **Settings → AI**. Quick AI and AI Chat can use different defaults, so set both.

### AI chats aren't syncing between devices

AI Chat History syncs through [Cloud Sync](https://manual.raycast.com/cloud-sync), which requires a signed-in Raycast Pro account with **AI Chat History** turned on in **Settings → Cloud Sync → Synced Content**. v1 and iOS devices sync through legacy Cloud Sync and appear as a single **Legacy Raycast & iOS Devices** entry, so bridging chats between a v1 device and a v2 device can lag behind syncing between two v2 devices. If it still looks stuck, see [Cloud Sync Troubleshooting](https://manual.raycast.com/cloud-sync#troubleshooting).

### Code or formatting comes out wrong (backslashes stripped, malformed blocks)

If code in a response drops backslashes or breaks formatting, copy it using the code block's copy action rather than selecting text by hand, which can pick up rendering artifacts. If the model itself is producing broken output, try a different model.

### I hit a request limit ("rate limit" / "too many requests")

Raycast AI has fair-usage request limits that depend on your plan. Raycast Pro and Advanced AI have access to different AI models with their own request limits. If you hit a limit, wait for the window to reset or upgrade your plan. Learn more on the [Usage Limits page](https://manual.raycast.com/ai/usage-limits).

### I hit a context limit, or the chat says the conversation is too long

Each model has a fixed context window, and a long conversation (or large attachments) can fill it, which trims earlier messages or blocks new ones. Start a fresh conversation for a new topic (`⌘ N`/`Ctrl N`), or switch to a model with a larger context window. Context windows vary by model. You can compare them at [raycast.com/core-features/ai/models](https://www.raycast.com/core-features/ai/models) or in **Settings → AI → Models → Manage Models** (also available via the **Manage Models** command).

### Still having issues?

If none of the above resolves it, gather the following and send it to us via the **Send Feedback** command so we can investigate:

1. **Your OS version** and **Raycast version** (found in **Settings → About**).
2. **Steps to reproduce** the issue.
3. Whether it's **AI Chat or Quick AI**, the **model** you're using, and whether the issue reproduces across models.
4. **Your Raycast logs**: Use the built-in **Copy Raycast Logs** command to copy your latest log files to the clipboard, or **Reveal Raycast Logs** to open your log folder.
5. **A screen recording** showing the issue in action.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Quick AI. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
