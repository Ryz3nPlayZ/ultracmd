> Source: https://manual.raycast.com/ai/ai-chat
> Scraped from the Raycast Manual (https://manual.raycast.com)

# AI Chat

> Available on: Mac, Windows, iOS
> Tier: Pro Exclusive

Have ongoing conversations with Raycast AI using history, memory, attachments, agents, and tools in a dedicated workspace beside your work.

AI Chat is Raycast's full chat workspace, with persistent history, Memory, rich attachments, and tool use so you can start a multi-turn conversation, attach context, and pick up where you left off across sessions. For fast, one-off questions straight from Root Search, use [Quick AI](https://manual.raycast.com/ai/quick-ai) instead.

![AI Chat workspace in Raycast](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/ai/mac-ai-aichat.png)

There are a few ways to start:

- Use the **AI Chat** command from Root Search to open the chat workspace.
- Press `⌘ J`/`Ctrl J` from a [Quick AI](https://manual.raycast.com/ai/quick-ai) conversation to continue it in AI Chat with the full history.
- Use a **Send to AI** command to send content into your active AI Chat from anywhere: **Send Focused Window to AI**, **Send Selected Text to AI**, **Send Screen Area to AI**, or **Send Screen to AI**. Learn more on the [Screen Awareness page](https://manual.raycast.com/ai/screen-awareness).

AI Chat lives in its own window, so you can keep it alongside whatever you're working on.

## Start a Conversation

Type your prompt in the composer and press `↵` to send. `⇧ ↵` adds a new line. AI Chat streams the response back and remembers the whole thread, so each follow-up can build on earlier turns.

- Edit any previous message to re-run the conversation from that point.
- Regenerate the last response with `⌘ R`/`Ctrl R`.
- Start a fresh chat with `⌘ N`/`Ctrl N`.
- With an empty composer, `↑` / `↓` step through your recent messages.

When a response includes code, it appears in a code block with the detected language and a copy button. Long lines scroll sideways by default. Click **Enable line wrap** in the top right of the block to wrap them to the response width, and click again to switch back.

![Enable line wrap button in an AI Chat code block](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/basics/mac-aichat-enablelinewrap.png)

> [!TIP]
> You can adjust the zoom level of the AI Chat window by using `⌘ -`/`Ctrl -` / `+` to zoom out or in, or `⌘ 0`/`Ctrl 0` to return to actual size, or in **Settings → AI → General → Zoom**.

## Steer or Queue Follow-ups

While a response is streaming, you can **Queue** a follow-up to run when it finishes, or **Steer** to inject your message into the current run without restarting. The send button shows **Steer Message** or **Queue Message** for the active mode. Default is **Queue**. Change it under **Follow-up Behavior** in [Settings](#settings).

- **Do the opposite once**: `⌘ ↵`/`Ctrl ↵` applies the other behavior for one message (`⌥ ↵` if that's your primary **Send Message** shortcut).
- **Promote a queued message**: Click **Steer** on a queued message to inject it into the current run. With no active run, it simply sends.

Canceling is unchanged (empty input still cancels a run). Pending tool confirmations still pause the run; steered messages apply once it resumes.

## Edit a Message

Change a message you already sent and re-run the conversation from that point with the new text. Hover a previous message to reveal its actions, click the edit (pencil) icon, update the text in the composer (it shows **Editing Message** while you do), and resend.

![Editing a previously sent message in AI Chat, with the edit (pencil) action revealed and the Editing Message state shown](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/ai/mac-aichat-editmessage.png)

Editing replaces the original response and any messages after it, so resending counts as a new AI request, just like regenerating a response.

## Collapsed Messages

To keep conversations easy to scan, long messages you send are collapsed in both AI Chat and Quick AI. A collapsed message shows its first part with a **Show more** control to expand it, and a **Collapse** control to fold it back once expanded.

![A long message collapsed in AI Chat with a Show more control](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/ai/mac-chat-collapsedmessages.png)

Only long messages collapse: A message over 10 lines (or a comparably long single paragraph) is collapsed, while shorter messages are always shown in full.

## Ask User Question

Sometimes the AI needs a bit more direction. When a request is ambiguous or the model isn't sure how to proceed, it can pause and show you a short multiple-choice question right in the conversation. Pick an option and it continues with your answer. This works in both Quick AI and AI Chat and is always on — there's no setting to turn it off.

To reliably trigger it, ask for it in your prompt: Either name the tool directly ("use the ask questions tool") or describe the flow ("do X, then ask me to choose Y").

Try it: Paste either of these into AI Chat:

```text
Set up a new project folder for me and ask me to choose from the available options
```

```text
Use the ask questions tool and quiz me about who are the cofounders of Raycast
```

Because these requests leave out details (where to create the folder and what to call it, or how many questions and how hard), the AI will typically ask a clarifying question with a few options before doing anything.

![AI Chat pausing to ask a multiple-choice question about Raycast's co-founders](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/ai/mac-aichat-askquestions.png)

You can also answer by voice: While a question or confirmation prompt is active, press `Ctrl M` to dictate your response. Learn more on the [Dictation page](https://manual.raycast.com/ai/dictation).

![Dictating a response to an Ask User Question prompt in AI Chat, with the dictation session running in the composer](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/ai/mac-aichat-inlinedictation-askuserquestion.png)

## Models

Configure the AI models used across AI Chat, Quick AI, and Custom AI Commands from **Settings → AI → Models**, or use the **Manage Models** command to jump straight there. Learn more on the [AI Commands page](https://manual.raycast.com/ai/ai-commands).

### Switch Models

Open the model picker from the composer. Pick a fast model for chat, a reasoning model for harder problems, or an image-capable model when you want to generate visuals.

Tune model behavior from the settings sidebar:

- **Creativity**: None, Low, Medium, High, or Maximum.
- **Reasoning Effort**: For models that support extended thinking.
- **Web Search**: Let the model pull live results during the answer.

### Default Models

Pick the default model for each surface:

- **AI Chat**: The default for new chats. Set to **Last Used Model** to continue with whichever model you used most recently.
- **Quick AI**: The model used when you ask a quick question from Root Search.
- **Custom AI Commands**: The default for any AI Command that doesn't specify its own model.

When a model supports reasoning effort, each row also shows a dropdown for it, with the recommended option marked **Default**. Your choice carries over between models that support it, or resets to the new model's default. The same control appears in Custom AI Command settings whenever a specific model is used instead of **Last Used Model**.

### Manage Models

Choose which models appear in the model pickers across AI Chat, Quick AI, and Custom AI Commands:

- **Review model details**: Each model lists its Speed, Intelligence, and Context window so you can compare capabilities at a glance.
- **Enable or disable models**: Toggle the checkbox next to a model to control whether it shows up in pickers. Disabled models are hidden everywhere AI models can be selected.

![Toggling a model on or off in Manage Models](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/basics/mac-settings-aimodels-toggle.png)

- **Group by Provider**: Models are grouped by their provider (e.g. Raycast, Anthropic). Expand or collapse a provider to focus on a subset.
- **Sort the list**: Use the sort menu in the top-right to order models by Brand, Alphabetically, Speed, Intelligence, or Context Window.

![Sort menu in Manage Models](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/basics/mac-settings-aimodels-sort.png)

## Memory

Turn on Memory (in **Settings → AI → Personalization → Memory**) and AI Chat will remember durable facts across conversations: Your name, the projects you work on, the format you prefer answers in. The model writes to and reads from memory automatically as you chat. Learn more on the [Personalization page](https://manual.raycast.com/ai/personalization).

## Long Conversations

Every model has a fixed context window, and a long working session will eventually fill it. Rather than cutting the conversation off, Raycast summarizes the earlier part of it in the background and carries on from the summary. You'll see a **Summarizing chat…** step in the transcript that settles into **Summarized chat** when it's done, and you keep going in the same chat.

Oversized tool results and attachments work the same way: Raycast saves the full content to a file and gives the model the start of it plus the path, so something too big for the context window can still be worked with. There's nothing to configure.

## Attach Context

Add context to your next message by clicking the attach button in the composer or typing `@`. AI Chat can pull in:

- **Files**: Documents, code, or images from your disk.
- **Notes**: Any of your Raycast Notes.
- **Clipboard History**: A recent item you've copied.
- **Browser Tabs**: Open tabs from supported browsers.
- **Web Search**: Live web results gathered while answering.
- **Focused Window**: A full Screen Awareness capture of the app in front of you, including its content, your selection, and a screenshot.
- **Selected Text**: Whatever you've highlighted in another app.
- **Window…**, **Selected Area**, or **Entire Screen**: A screenshot captured from your desktop.
- _(Only on Mac)_ **Calendar Events**: Events from today or coming up.

Attachments are scoped to the message you send them with, but the model can keep referring back to them later in the chat.

**Send to AI** commands push content into your active chat instead of always starting a new one. The commands are **Send Focused Window to AI**, **Send Selected Text to AI**, **Send Screen Area to AI**, and **Send Screen to AI**. Learn more on the [Screen Awareness page](https://manual.raycast.com/ai/screen-awareness).

What happens depends on AI Chat's state:

- **AI Chat open**: The content goes straight to the active chat.
- **AI Chat closed**: Your **Start new chat after inactivity** setting decides: Within the window the active chat is reused; once it's elapsed, a new chat begins. Adjust it in **Settings → AI → General → Start New Chat**, or see [Auto-new Chat](https://manual.raycast.com/ai/quick-ai#auto-new-chat).
- **Mid-response**: If you close AI Chat while the active chat is still streaming, that chat is always restored on next open, regardless of the timer.

## Tool Use & Extensions

AI Chat can call tools: Run a web search, generate an image, execute a terminal command, invoke an AI Extension, or hand work off to an MCP-compatible server. Toggle which tools are available per chat from the **Tools** section of the settings sidebar. With **Tool Confirmation** on, AI Chat asks before each tool runs. Learn more on the [AI Extensions page](https://manual.raycast.com/ai/ai-extensions) and the [Model Context Protocol page](https://manual.raycast.com/ai/model-context-protocol).

Generated images can be dragged and dropped straight from the chat into other apps.

## Agents

Switch the chat to a saved Agent with the ** Change Agent** action in the Action Panel. Agents set instructions, model, and AI Extensions for consistent results until you switch agents or choose **Ask Anything**. Learn more on the [Agents page](https://manual.raycast.com/ai/agents).

## Skills
_(Available on Mac and Windows)_

Author reusable knowledge for the model with plain `SKILL.md` files. Raycast discovers them automatically and loads them when they're relevant to your chat. Learn more on the [Skills page](https://manual.raycast.com/ai/skills).

## Folders
_(Available on Mac and Windows)_

The history sidebar organizes your chats into sections: **Pinned** at the top, then any **Folders** you've made, then **Recent** (the default section for chats you haven't organized), and **Archived** at the bottom. Folders let you group related chats by project, topic, or investigation so they don't get lost in Recent.

Create a folder in a few ways:

- Open the Action Panel (`⌘ K`/`Ctrl K`) on any chat and choose **Create Folder…** (`⌃ ⌘ N`/`Alt Shift N`).
- Choose **Move to Folder…** (`⌃ ⌘ M`/`Alt Shift M`) from the Action Panel and pick **New Folder…** from the submenu.
- Right-click any chat in the sidebar and choose **Move to Folder → New Folder…** from the context menu.

The **New Folder** dialog lets you name the folder and pick an icon for it.

To rename or delete a folder, right-click the folder's header in the sidebar and choose **Rename Folder** or **Delete Folder**. Deleting a folder doesn't delete its chats: They move back to Recent.

Hover a folder's header to reveal a quick **+** button that starts a new chat directly inside that folder.

## Manage Chats

The history sidebar shows every chat, with search at the top. From the Action Panel (`⌘ K`/`Ctrl K`) on any chat, or by right-clicking the chat in the sidebar, which offers the same actions plus **Copy Chat** and **Branch Chat**, you can:

- **Pin** important conversations to the top.
- **Archive** chats you're done with. Old chats archive automatically after the window you pick in Settings (or never).
- **Clear Chat** to remove a chat's messages while keeping its model, agent, and other configuration, so you can start over without losing your setup.
- **Delete** for good.
- **Rename** a chat to give it a title you'll recognize, instead of the auto-generated one.
- **Move**: Drag a chat onto the Pinned section, a Folder, or the Archived section to reorganize it instantly, without opening a menu, or use **Move to Folder…** from the Action Panel or right-click menu. Dropping a pinned or foldered chat back onto Recent removes it from that pin or folder.

You can also organize chats directly in the sidebar: Drag and drop chats between sections like Recent, Pinned, Archive, and individual folders, or right-click anywhere in the sidebar to quickly create a new folder.

## Always on Top

Toggle **Always on Top** from the Action Panel to keep AI Chat hovering over your other apps, handy while you're chatting about something on screen. You can also set this up in **Settings → AI → Commands → AI Chat → Always on Top**.

## Background Notifications
_(Available on Mac and Windows)_

Raycast can notify you when an AI Chat finishes responding in the background, so you don't have to keep watching the window. You'll get a notification when streaming finishes and the chat isn't in the foreground: You're viewing a different chat, or the window is blurred or minimized. It tells you why the chat finished (done, needs confirmation, failed, and so on), and clicking it takes you back to that chat.

Background notifications are off by default. The first time a chat finishes in the background, Raycast waits until you return, then shows a one-time alert (once per device):

- Enable, and Raycast turns on the toggle in **Settings → AI**. _(Only on Mac)_ You'll also get the system permission prompt.
- Decline (or press `Esc`) and the feature stays off. The alert won't appear again.

You can turn the toggle on or off anytime in Settings. Turning it off silences only these notifications.

![The Background Notifications toggle in Settings → AI](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/ai/mac-settings-ai-backgroundnotifications.png)

_(Only on Mac)_ On macOS, Raycast also needs system permission. If you dismissed or denied the prompt, or notifications still don't appear, open **System Settings → Notifications → Raycast** and turn on **Allow Notifications**. The toggle syncs across devices, but permission is per Mac: If the feature is on without permission here, Settings offers a button to show the prompt or open System Settings.

![Raycast's notification permission in macOS System Settings → Notifications](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/ai/mac-settings-ai-backgroundnotifications-systempermission.png)

If permission is granted but notifications still aren't showing, check whether an active Focus is holding Raycast back in **System Settings → Focus**. macOS banners disappear after a few seconds: Set the alert style to persistent in **System Settings → Notifications → Raycast** to keep them on screen.

## Continue from Quick AI

When a Quick AI question grows into something bigger, press `⌘ J`/`Ctrl J` to move it into AI Chat. The full history, model, and any attachments come with it. Learn more on the [Quick AI page](https://manual.raycast.com/ai/quick-ai).

## Settings

Tune AI Chat from **Settings → AI**:

- **Start New Chat**: How long a gap counts as a new conversation. It decides whether a Send to AI command reuses your active chat or starts a new one while AI Chat is closed, and when [Quick AI](https://manual.raycast.com/ai/quick-ai#auto-new-chat) begins a fresh chat.
- **Send Message**: Keyboard shortcut used to send messages in AI Chat (`↵` or `⌘ ↵`/`Ctrl ↵`).
- **Conversation History**: Show conversations from AI Chat and Quick AI combined or keep them separate.
- **Auto-Archive Chats**: Automatically archive chats after the specified period of inactivity.
- **Always on Top** (per-command, under AI Chat): Keep the AI Chat window above other windows.
- **Zoom**: Adjust the zoom level of the AI Chat window.
- **Follow-up Behavior** (Advanced): Queue follow-ups while the agent runs, or steer the current run. The alternate send shortcut does the opposite for one message.

## Troubleshooting

AI Chat lets you talk to models from anywhere in Raycast. Most reports come down to model selection, window behavior, sync, or hitting a usage or context limit. Here are the common ones.

### The model keeps resetting or picks the wrong one

Set your preferred model in **Settings → AI**. AI Chat and Quick AI can use different defaults, so set both.

### AI chats aren't syncing between devices

AI Chat History syncs through [Cloud Sync](https://manual.raycast.com/cloud-sync), which requires a signed-in Raycast Pro account with **AI Chat History** turned on in **Settings → Cloud Sync → Synced Content**. v1 and iOS devices sync through legacy Cloud Sync and appear as a single **Legacy Raycast & iOS Devices** entry, so bridging chats between a v1 device and a v2 device can lag behind syncing between two v2 devices. If it still looks stuck, see [Cloud Sync Troubleshooting](https://manual.raycast.com/cloud-sync#troubleshooting).

### Code or formatting comes out wrong (backslashes stripped, malformed blocks)

If code in a response drops backslashes or breaks formatting, copy it using the code block's copy action rather than selecting text by hand, which can pick up rendering artifacts. If the model itself is producing broken output, try a different model.

### The AI Chat window loses focus, won't float, or won't stay on top

Check your AI Chat window preferences in **Settings → AI**, including **Always on Top** under **Settings → AI → Commands → AI Chat**. If the input box loses focus or the window drops behind other apps, note exactly what you did right before it happened, since these are usually tied to a specific action.

### I hit a request limit ("rate limit" / "too many requests")

Raycast AI has fair-usage request limits that depend on your plan. Raycast Pro and Advanced AI have access to different AI models with their own request limits. If you hit a limit, wait for the window to reset or upgrade your plan. Learn more on the [Usage Limits page](https://manual.raycast.com/ai/usage-limits).

### I hit a context limit, or the chat says the conversation is too long

Each model has a fixed context window. AI Chat summarizes earlier turns automatically as you approach it (see [Long Conversations](#long-conversations)), so most long sessions keep going on their own.

If a single message is still too large to send, shorten it or swap a large attachment for a smaller excerpt. Start a fresh chat for a new topic, or switch to a model with a larger context window. Compare context windows at [raycast.com/core-features/ai/models](https://www.raycast.com/core-features/ai/models) or in **Settings → AI → Models → Manage Models**.

### Still having issues?

If none of the above resolves it, gather the following and send it to us via the **Send Feedback** command so we can investigate:

1. **Your OS version** and **Raycast version** (found in **Settings → About**).
2. **Steps to reproduce** the issue.
3. Whether it's **AI Chat or Quick AI**, the **model** you're using, and whether the issue reproduces across models.
4. **Your Raycast logs**: Use the built-in **Copy Raycast Logs** command to copy your latest log files to the clipboard, or **Reveal Raycast Logs** to open your log folder.
5. **A screen recording** showing the issue in action.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with AI Chat. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
