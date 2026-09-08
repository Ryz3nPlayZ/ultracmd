> Source: https://manual.raycast.com/ai/raycast-ai-privacy-security
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Raycast AI Privacy & Security

Discover how Raycast AI keeps your data private, safe, and secure. Learn about our strict privacy policies, zero background data collection, no prompt training, encrypted AI processing, opt-in feedback, and full user control.

At Raycast, we prioritize your privacy and security in all our AI features. With this document, we aim to provide clarity and transparency about how AI works in Raycast and our commitment to privacy and security. 

- [Terms of Service](https://www.raycast.com/terms-of-service)
- [Privacy Policy](https://www.raycast.com/privacy)

## Key Principles 
You should know when and how AI is used and activated in Raycast. You should always be in control of your interaction with AI and have the ability to opt-out at any time. We will be transparent and open about how your data and AI inputs/outputs are used. We believe consent is crucial and aim to provide the best, most transparent AI user experience. 

## How Raycast AI Works
Raycast AI only runs when you explicitly trigger it; meaning, you ask AI a question, run an AI command, or otherwise interact with AI directly. The only time AI may activate without explicitly being called is with Emoji Search - which is opt-in and requires your consent. 

Raycast AI does not run in the background or monitor your activity. Your data is not used to train AI models. If you choose to send feedback, your data may be used to improve our AI system; this is strictly opt-in and you will be prompted to consent before data is sent.

## About Raycast AI  

### Data Collection & Usage
- Your AI interactions are not recorded
- We do not collect or store sensitive information
    - We do not log or retain any user prompts. We do store some basic metadata, such as the number of completion tokens, for operational purposes only.
    - Cloud Sync: when enabled, the client sends content such as Snippets, AI Chats, etc. to our backend. We store this information encrypted in our databases. 
    - AI attachments: Image attachments are securely uploaded to our servers for AI processing, enabling you to access them later. If you delete a message or chat that includes attachments, those attachments will be deleted from the server. 
    - AI Feedback: If you choose to report feedback, the full chat thread — including AI Extension tool calls and results — will be sent to us. This is **entirely opt-in** and you must give explicit consent before any data is sent. **Please be mindful of any sensitive data the thread might contain**. We may use this information to improve the reliability of our AI System.
- All models provided by Raycast AI are Zero Data Retention (ZDR). Providers do not keep your prompts or outputs after the request completes. Two exceptions apply:
    - **Mistral AI**: Retains data for a rolling 30-day window to monitor abuse. Data is deleted after that window
    - **xAI**: Retains data for 30 days before automatic deletion

### AI Personalization & Memory
When enabled, Raycast AI can build a memory summary from your conversations to personalize future responses. Memory is stored locally and encrypted at rest and in transit when synced via Cloud Sync. It follows the same privacy and security standards as all AI features. Your data is never used to train models. You can view, edit, or delete your memory at any time. You can learn more on the [Personalization](https://manual.raycast.com/ai/personalization) page.

### Dictation
[Dictation](https://manual.raycast.com/ai/dictation) is designed to be private by default. Your voice is never used to train AI models, and we don't store your audio or transcriptions on our servers.

- Your audio is sent to our speech‑to‑text partner solely to produce a transcription, and isn't retained on Raycast servers after the request completes. Our partners are contractually prohibited from using it to train their models.
- Every transcription is saved to your local app's database on your device, not in our cloud, so you can find and reuse it later. You can delete individual transcriptions or wipe the entire history at any time in the **Dictation History** command.
- Your dictation statistics are computed on‑device from your local history and are never sent to Raycast as analytics or telemetry.
- If App Context is enabled, nearby text and app details are used only for that single transcription request and discarded as soon as the transcription is complete. Nothing is stored.

## AI Processing & Partners
- Raycast AI features are powered by AI model providers, including OpenAI, Anthropic, Perplexity, and more (see the complete list of [AI providers we use and their Terms below](#ai-providers-terms))
- All AI processing occurs through secure server infrastructure to ensure the safety of our API keys
- When using Raycast AI (not BYOK), [our agreements with providers](https://www.raycast.com/terms-of-service#viii-generative-ai) prohibit them from using any AI interactions to train their models. When you use our AI features, we:
    - Forward your input to the AI provider's API
    - Exclude any personal information when doing so
    - Only share the minimum necessary data
- BYOK (Bring Your Own Key):
    - Anthropic, Google, OpenAI: Requests are processed through our servers in order to unify the model APIs, integrate fallback behaviors, and do some final prompt management. This helps to maintain the quality and consistency of output when using your own API key vs. ours. 
    - OpenRouter: Requests are routed directly from your device to OpenRouter's servers. 
    - Custom API keys are stored locally on the user’s computer, not in our backend
    - When using BYOK, you maintain the contractual relationship with the AI provider. Please consult their privacy policies and terms for more details. 
- AI input and output is encrypted during transmission

## User Control & Transparency
- AI features are optional and user-controlled. Users can completely disable AI.  
- Before using Raycast AI, you will be prompted to read and accept our Terms of Service if you haven’t accepted them in the past. AI does not run in the background and you must actively consent before AI can be activated. 

## AI Providers Terms
| Provider       | Terms of Service                                                                                                                                           |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OpenAI         | [Services Agreement](https://openai.com/policies/services-agreement), [Usage Policies](https://openai.com/policies/usage-policies)                         |
| Anthropic      | [Commercial Terms](https://www.anthropic.com/legal/commercial-terms)                                                                                       |
| Perplexity     | [API Terms of Service](https://www.perplexity.ai/hub/legal/perplexity-api-terms-of-service)                                                                |
| Groq           | [Terms of Use](https://groq.com/terms-of-use)                                                                                                              |
| Mistral AI     | [Terms](https://legal.mistral.ai/terms)                                                                                                                    |
| Google Gemini  | [Gemini API Terms](https://ai.google.dev/gemini-api/terms)                                                                                                 |
| xAI            | [Terms of Service (Enterprise)](https://x.ai/legal/terms-of-service-enterprise)                                                                            |
| Replicate      | [Terms](https://replicate.com/terms)                                                                                                                       |
| Baseten        | [Terms and Conditions](https://www.baseten.co/terms-and-conditions/)                                                                                       |
| Cerebras       | [Terms of Service](https://cloud.cerebras.ai/terms)                                                                                                        |

## Open Source Extensions
As a company that believes in the value and importance of open source software, Raycast has a rich and expansive extension ecosystem. Note that third-party extensions may use their own logic for AI. As all extensions are [open source](https://github.com/raycast/extensions), you can refer to an extensions’ README or source code for further information.

---

We continuously review and update our privacy practices to maintain the highest standards of data protection while delivering powerful AI capabilities. If you have questions or suggestions, you can contact us via [privacy@raycast.com](mailto:privacy@raycast.com).


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Raycast AI Privacy & Security. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
