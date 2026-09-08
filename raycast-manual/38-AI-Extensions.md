> Source: https://manual.raycast.com/ai/ai-extensions
> Scraped from the Raycast Manual (https://manual.raycast.com)

# AI Extensions

> Available on: Mac, Windows, iOS
> Tier: Pro Exclusive

AI Extensions empower Raycast AI to perform actions and automate workflows within your extensions, allowing you to accomplish more simply by asking.

AI Extensions are how you let Raycast AI take action across your installed extensions. Once an extension exposes its commands as tools, you can mention it from Quick AI, AI Chat, or Root Search and the AI figures out which tool to call, with what arguments, and runs it for you.

## Discover AI Extensions

### Built-in AI Extensions

Raycast includes several built-in AI Extensions that work with Raycast itself, the data on your device, and the apps you use on Mac or Windows. The badge next to each one shows the platforms it's available on:

- _(Only on iOS)_ **Apple Health**: `@apple-health` reads your recent activity, workouts, sleep, and other metrics from Apple Health.
- _(Available on Mac and Windows)_ **Browser**: `@browser` reads and reasons about the page open in your browser. Requires the [Raycast Browser Companion](https://raycast.com/browser-extension).
- _(Available on Mac and Windows)_ **Calculator**: `@calculator` evaluates math, unit and currency conversions, and date calculations.
- _(Available on Mac and iOS)_ **Calendar**: `@calendar` asks about your schedule, free slots, or upcoming events.
- _(Available on Mac and Windows)_ **Clipboard**: `@clipboard` pulls your most recently copied item into the AI.
- _(Available on Mac and Windows)_ **Feedback**: `@raycast-feedback` sends a bug report, feature request, or support question to the Raycast team, and confirms with you before it sends. You can also use the **Ask Feedback** command in Root Search.
- _(Only on Windows)_ **File Explorer**: `@file-explorer` reads and manages files and folders on your Windows PC.
- _(Available on Mac and Windows)_ **File Search**: `@file-search` finds files across your indexed folders.
- _(Only on Mac)_ **Finder**: `@finder` searches and manages files and folders on your Mac.
- _(Available on Mac and Windows)_ **Focus**: `@raycast-focus` controls Focus sessions and asks what you're scheduled for.
- _(Available on Mac, Windows, and iOS)_ **Location**: `@location` knows where you are when you ask "what's nearby?". On Windows, the OS asks for permission the first time you run it.
- _(Available on Mac and Windows)_ **Manual**: `@manual` answers questions about Raycast straight from the Raycast Manual. You can also use the **Ask Manual** command in Root Search to jump right into a question, or **Open Manual** to read the manual in your browser.
- _(Available on Mac and Windows)_ **Memory**: `@memory` recalls earlier discussions and decisions from your past AI chats.
- _(Available on Mac, Windows, and iOS)_ **Notes**: `@raycast-notes` creates, reads, and searches your Raycast Notes.
- _(Only on iOS)_ **Quicklinks**: `@quicklinks` creates, searches, and opens your Quicklinks.
- _(Only on iOS)_ **Reminders**: `@reminders` creates, searches, and completes items in Apple Reminders.
- _(Available on Mac and Windows)_ **Screen Awareness**: `@screen-awareness` reads the content of the app in front of you, what you have selected, and a screenshot of its window, so you can ask about whatever you're looking at.
- _(Available on Mac and Windows)_ **Selected Text**: `@selected-text` pulls in whatever you've highlighted in another app.
- _(Only on iOS)_ **Snippets**: `@snippets` creates, searches, and manages your Snippets.
- _(Available on Mac and Windows)_ **Terminal**: `@terminal` runs and reasons about shell commands.
- _(Available on Mac, Windows, and iOS)_ **Weather**: `@weather` answers without a separate trip to a weather app.

### Install AI Extensions
_(Available on Mac and Windows)_

More AI Extensions are available on the Raycast Store. Open the Store from Root Search and filter by the **AI Extensions** category in the Navigation Bar using `⌘ P`/`Ctrl P` to see only the extensions that include tools. These cover everything from project trackers and music players to image editors and home automation.

> [!NOTE]
> On iOS, you can't install community-created AI Extensions, but you can extend Raycast AI the same way by connecting [MCP servers](https://manual.raycast.com/ai/model-context-protocol). `@`-mention them in chat exactly like the built-in extensions above.

## Using AI Extensions

Type `@` in AI Chat, Quick AI, or Root Search and a list of every installed AI Extension appears. Pick one and chat in natural language. The AI chooses the right tool and shows you the call as it happens. Example prompts:

- `@linear what's assigned to me this sprint?`
- `@calendar block out 2 hours tomorrow morning for deep work`
- `@github pull requests waiting on my review`
- `@spotify play something mellow but not sad`

You can also chain them in a single prompt: `@calendar @things any free slots tomorrow that I could use to clear overdue tasks?` and the AI will analyze both before answering your request.

### Permissions

By default, Raycast asks for approval before running any tool from an AI Extension. You can change the default option in **Settings → AI → Permissions**, or override it for a single chat from the AI Chat's Chat Settings menu.

When a tool asks for approval, you can also choose to always allow that one specific tool so it runs without confirmation from then on, regardless of your global Permissions default. Turn on the **Always allow \{tool title\}** toggle on the confirmation card and accept the tool call, or open the Action Panel and choose **Always Accept** while the pending confirmation is focused. This applies only to that tool — every other tool still follows your Permissions default. The built-in `ask_user_question` tool can't be always-allowed. You can review and revoke always-allowed tools any time from [Settings](https://manual.raycast.com/settings).

## Manage AI Extensions

**Desktop**

Each installed extension has its own section in **Settings**. Select one and you'll see the list of individual commands and the **Ask** tool it exposes. The **Ask** tool includes a free-text **Custom Instructions** field. Use it to steer the extension's behavior, for example "default my Linear queries to the Platform team" or "never schedule meetings before 10am." The AI reads these instructions whenever it considers using that extension's tools.

  To remove an AI Extension entirely, uninstall the extension either from the **Store** or in **Settings**; its tools disappear from `@-mentions` immediately.

**iOS**

Built-in AI Extensions are always available, so there's nothing to install or uninstall. To steer one, open **Account Avatar → AI**, where **Calendar**, **Apple Health**, and **Reminders** each expose a free-text **Custom Instructions** field. Use it to shape the extension's behavior, for example "never schedule reminders for the weekend." The AI reads these instructions whenever it considers using that extension's tools.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with AI Extensions. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
