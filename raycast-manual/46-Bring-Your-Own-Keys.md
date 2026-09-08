> Source: https://manual.raycast.com/ai/bring-your-own-keys
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Bring Your Own Keys

> Available on: Mac, Windows, iOS
> Tier: Pro Exclusive

Connect your own API key from Anthropic, Google, OpenAI, or OpenRouter to use those models across Raycast's AI features, paying the provider directly for what you use.

Bring Your Own Key (BYOK) lets you connect your own API key from Anthropic, Google, OpenAI, or OpenRouter and use it across Raycast's AI features. If you already have credits with a provider, you can utilize them in Raycast, with usage bound only by what your key allows rather than Raycast AI limits. You'll be responsible for the API costs incurred at the provider's standard rates.

![Raycast AI Quick AI answering a question with a model running through a personal API key](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/ai/mac-byok-quickai.png)

You can add one API key per provider from [Anthropic](https://console.anthropic.com/settings/keys), [Google](https://aistudio.google.com/apikey), [OpenAI](https://platform.openai.com/api-keys), and [OpenRouter](https://openrouter.ai/settings/keys). Be sure to monitor the provider's API console to prevent costly surprises when using your own key. For Anthropic, Google, and OpenAI, only [AI models available in Raycast AI](https://www.raycast.com/core-features/ai/models) will be available as models through BYOK. An OpenRouter key unlocks OpenRouter's full model catalog instead.

> [!NOTE]
> If using BYOK with Anthropic, Google, or OpenAI, requests are processed through our servers in order to unify the model APIs, integrate fallback behaviors, and do some final prompt management. OpenRouter is the exception: requests made with your OpenRouter key go directly to OpenRouter's servers. Learn more about BYOK and Privacy on the [Raycast AI Privacy & Security](https://manual.raycast.com/ai/raycast-ai-privacy-security) page.

## Add a Key

**Desktop**

1. Open **Settings → AI**.
  2. In the API Keys section, click **Plus icon** to add your key.
  3. Select your provider from the dropdown.
  4. Paste your key into the API Key field, then click **Verify**. Raycast will check the key with the provider to ensure it can be used.
  5. Once verified, click **Save**. The key is stored securely and the provider appears in your API Key list.

  If you don't yet have a key, the **Manage in [Provider] Console** button opens the provider's key console page in your browser.

**iOS**

1. In the top right, tap your **Account Avatar -> AI -> Custom API Keys**.
  2. Select your provider from the list.
  3. Paste your key into the API Key field, then tap ** Verify**. Raycast will check the key with the provider to ensure it can be used.
  4. Once verified, tap **the back icon** to save.

  If you don't yet have a key, the **Manage in [Provider] Console** button opens the provider's key console page in the browser.

## Managing & Deleting Keys

**Desktop**

Each configured provider entry in the API Keys list will show:
  - A **toggle** to enable or disable the key without deleting it. Disabled keys won't be used for any AI request.
  - **Trash button** Remove the key entirely.
  - **NE Arrow button** Shortcut to the provider's console for rotating or revoking the key on their side.

  When an API key is active, a small key icon appears next to that provider's model names in Raycast AI to show that the request will use your provided API key.

**iOS**

**Custom API Keys** will show all available providers you can use.
  - **Key icon** Shows next to providers you have connected an API key with.
  - Tap any active providers and tap ** Remove** to delete the API key.

  When an API key is active, a small key icon appears next to that provider's model names in the AI Chat model picker to show that the request will use your provided API key.

## FAQ

### My key fails to verify when adding to Raycast

Double-check the key is pasted in full with no surrounding whitespace, and confirm it's active in the provider's console. If you've just created the key, give the provider a moment to propagate it on their end.

### I can't see a model I want to use with BYOK in the model picker

Raycast is responsible for the list of AI models available for AI features inside the app. If a brand-new model isn't showing, we may still be working on adding it on our side. The [Raycast AI Models](https://www.raycast.com/core-features/ai/models) page lists all models available from each provider in Raycast AI. If the model is available on [OpenRouter](https://openrouter.ai/models), connecting an OpenRouter API key gives you access to it without waiting on us.

### My requests are using Raycast AI even though I've added my own key

Make sure the key has been enabled in API Keys under **Settings → AI** on desktop or **Account Avatar -> AI -> Custom API Keys** on iOS, then re-pick the model where you wish to use it in Raycast.

### I want to stop using BYOK in Raycast

You can either toggle the API key off in **Settings → AI** to keep the key available for later, or click the **Trash button** icon to remove it entirely. On iOS, you can only remove the key in the **Custom API Keys** settings.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Bring Your Own Keys. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
