> Source: https://manual.raycast.com/ai/skills
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Skills

> Available on: Mac, Windows
> Tier: Pro Exclusive

Skills extend Raycast AI with reusable knowledge and instructions that models can use automatically when it's relevant to your chat.

Skills are reusable context for Raycast AI. Instead of pasting the same conventions, guidelines, or domain knowledge into every prompt, you write them once as a plain `SKILL.md` file, drop it into a folder, and Raycast handles discovery automatically. It scans your library and loads whichever skills are relevant to your Chat prompts.

![Quick AI loading a skill called 'copywriting' to answer a tagline question](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/ai/mac-skills-quickai.png)

## What is a Skill?

A skill is a small, focused unit of context (instructions, examples, conventions, or domain knowledge) that Raycast AI can load on demand. Think of it as a piece of expertise the model can reach for when the conversation calls for it, rather than something you have to remember to attach every time.

Skills are stored as files in default folders used by common AI agents, or you can add your own directories. Each skill describes when it should be used and what knowledge or steps it brings to the conversation, so Raycast can decide on its own whether to load it for a given message.

> [!TIP]
> You can create your own skills to use inside Raycast, as well as across other AI platforms. Learn more about the open standard on [Agent Skills](https://agentskills.io/home).

## Discover Skills Automatically

By default, Raycast AI looks at the message you're sending and pulls in any skills from your configured directories that look relevant, so you don't need to attach them by hand. This keeps the Chat input clean and lets your skill library scale without adding friction.

Toggle this behavior per chat in AI Chat from **Chat Settings → Skills → Discover Skills Automatically**. Turning it off stops Raycast from surfacing skills on its own for that conversation, so nothing is added to the model's context unless you ask for it. Even with it off, you can still bring in a specific skill by mentioning it with `@` — a manual mention always forces that skill into consideration, regardless of the toggle's state.

![Chat Settings panel showing the Skills section with the Discover Skills Automatically toggle, sitting alongside the Extensions section](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/ai/mac-skills-aichat.png)

> [!NOTE]
> The **Discover Skills Automatically** toggle is per-chat in AI Chat and can be changed at any time. Quick AI has skill discovery turned on for all chats.

## Mention a Skill

Type `@` in the AI Chat or Quick AI composer and start typing a skill's name, id, or description to filter the mention menu — skills appear under their own **Skills** section, alongside AI Extensions. Select one to attach it; it renders as a pill with a skills icon in both the composer and the sent message.

Mentioning a skill this way always forces it into consideration for that turn, even when **Discover Skills Automatically** is turned off for the chat. The toggle only controls whether Raycast surfaces skills on its own; an explicit `@`-mention is a separate path that's always available.

> [!NOTE]
> Skill Mentions work in AI Chat and Quick AI. They aren't available when writing AI Command prompts, since AI Commands don't use skills.

## How Loading Works

When you send a message in AI Chat or Quick AI, Raycast shows the model a compact catalog of every skill it found, including the `name`, `description`, and file path from each frontmatter, not the body. If the model decides one or more skills look relevant, it loads them through a tool call and reads their full Markdown content before answering.

- **A clear `description` matters most.** It's the only signal the model has when deciding what to load. Lead with *when* to use the skill ("Use when adding a new screen to the admin panel…") rather than what's inside it.
- **Skills only run on models that support tools.** If you've picked a model without tool support, skills won't be offered. Most modern models qualify, but it's worth checking when something seems missing.
- **AI Commands don't use skills.** Commands are intentionally narrow and predictable, so Raycast keeps the skill catalog out of them.

## Settings

All your skills appear in **Settings → AI → Skills**. The page lists every skill Raycast has found, with its description, so you can scan your library at a glance.

![Screenshot of Skills settings page listing discovered skills with their descriptions](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/ai/mac-skills-settings.png)

Raycast watches your skill folders for changes. Adding, editing, or removing a skill file updates the list within a minute.

By default, Raycast scans the following folders for skills. You can add other folders by clicking the Plus button on Skill Folders.
- `~/.claude/skills`
- `~/.config/agents/skills`
- `~/.config/raycast/skills`
- `~/.agents/skills`

These folders are the same on Windows — `~` is your home folder, so on Mac that's `/Users/<name>` and on Windows it's `C:\Users\<name>`.

Each skill must reside in its own subfolder, with the folder name matching the `name` in the frontmatter, and the file itself must be named `SKILL.md` exactly (case-sensitive). Other `.md` files in the folder are ignored. Raycast scans only the top level of each specified folder and does not search recursively for skills.

## Skills vs. AI Extensions

Skills and AI Extensions both let Raycast AI go beyond the model's built-in knowledge, but they solve different problems:

- **[AI Extensions](https://manual.raycast.com/ai/ai-extensions)** give the model *tools*: actions it can take, like searching your notes, querying an API, or running a command.
- **Skills** give the model *context*: instructions, conventions, and knowledge it should apply when working on a particular kind of task.

The two pair naturally: an AI Extension to fetch the data, a Skill to tell Raycast how you want it interpreted or written up.

**[Agents](https://manual.raycast.com/ai/agents)** build on both: an Agent carries its own instructions and a scoped set of AI Extensions, while Skills still load automatically alongside whichever Agent is active.

## If a Skill Isn't Loading

When a skill fails to load, Raycast skips it silently and continues with your chat. If a skill you expect isn't showing up, check the following:

- It's in one of the default folders, or in a custom folder you added in **Settings → AI → Skills**.
- It lives in its own subfolder, and the folder name matches `name` in the frontmatter exactly.
- The file is named `SKILL.md` (case-sensitive) and starts with valid YAML containing both `name` and `description`.
- The `name` follows the rules: 1–64 characters, lowercase letters, digits, and hyphens, with no leading, trailing, or consecutive hyphens.
- The `description` is between 1 and 1024 characters.
- You're testing in AI Chat or Quick AI on a model that supports tools. Skills don't run in AI Commands.
- **Discover Skills Automatically** is on for the AI Chat you're wanting to use the skill in, or `@`-mention the skill to load it regardless of the toggle.
- Give it a minute. The folder scan is cached for about 60 seconds, so a fresh skill can take that long to appear.
If two skills share the same `name`, Raycast keeps the first one it finds and ignores the rest, so rename one of them if you're expecting both to coexist.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Skills. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
