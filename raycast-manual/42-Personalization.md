> Source: https://manual.raycast.com/ai/personalization
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Personalization

> Available on: Mac, Windows
> Tier: Pro Exclusive

AI Personalization blends a Profile you define with an intelligent Memory crafted from your interactions, enabling Raycast AI to deliver responses that are uniquely relevant and tailored to you.

Raycast AI learns about you over time to provide more relevant, personalized responses. This page explains how AI Personalization works, what data is involved, and how you stay in control.

## What is AI Personalization?

AI Personalization consists of two parts, found in **Settings → AI → Personalization**:

### Profile

Text you write yourself to give AI context about you: for example, your role, preferred coding language, or communication style. Your Profile is entirely manual and only contains what you choose to share.

### Memory

A summary that Raycast AI automatically builds from your conversations over time. It captures relevant context like your projects, preferences, and goals to make future interactions more helpful.

## How Memory Works

Every few hours, Raycast collects your recent AI Chat and Quick AI conversations and sends them (along with your current memory) to the AI model. The model distils this into an updated memory summary. This uses the same infrastructure, providers, and privacy protections as sending a message in AI Chat.

> [!NOTE]
> Memory in Raycast AI is stored locally on your device, synced via Cloud Sync when enabled (encrypted, like all other synced data), and never used to train AI models.

## What Raycast Remembers

Memory focuses on context that helps improve your AI interactions:

- Your role and professional context
- Projects you're working on
- Technical preferences and tools you use
- Communication style and preferences

## What Data Is Sent?

Only your chat contents are used to build Memory. No additional personal information (name, email, etc.) is sent beyond what's already part of your conversations. The same agreements with AI providers that prevent your data from being retained and used for model training apply here.

## Managing Your Personalization

You have full control over your AI Personalization:

- **View and edit your Memory**: See exactly what Raycast remembers in **Settings → AI → Personalization**. You can edit or clear your memory at any time.
- **Add to Memory manually**: Select text in a conversation and use **Add to Memory** (`⇧ ⌘ L`/`Ctrl Shift L`) to save specific information.
- **Ask AI to remember**: Tell AI to "remember this" or "update my memory" directly in a chat.
- **Disable Memory**: You can turn off Memory entirely in **Settings → AI → Personalization**.

## Privacy and Security

- AI Personalization follows the same privacy and security standards as all Raycast AI features
- Your conversations are not recorded or logged: Memory is a distilled summary, not a transcript
- AI providers cannot use your data for model training (see our [AI](https://www.raycast.com/core-features/ai) and [AI Privacy + Security](https://manual.raycast.com/ai/raycast-ai-privacy-security) page)
- Memory synced via Cloud Sync is encrypted at rest and in transit
- For full details, see our [Terms of Service](https://www.raycast.com/terms-of-service), [Privacy Policy](https://www.raycast.com/privacy) and [AI Privacy + Security](https://manual.raycast.com/ai/raycast-ai-privacy-security) page

## FAQ

### Is AI Personalization available on all platforms?

AI Personalization (Profile and Memory) is available on macOS and Windows. Your memory syncs across devices when Cloud Sync is enabled (coming soon).

### Does Memory store my full conversations?

No. Memory is a distilled summary of relevant context, not a transcript. Your conversations are not recorded or logged.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Personalization. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
