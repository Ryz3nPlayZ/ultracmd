> Source: https://manual.raycast.com/ai/custom-providers
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Custom Providers

> Available on: Mac, Windows
> Tier: Pro Exclusive

Connect any compatible provider to Raycast AI and bring your own models, from cloud gateways and team proxies to agents running on your machine.

Custom Providers let you connect any compatible provider to Raycast and bring your own models. The models you define appear in the model picker alongside Raycast AI models, ready to use across AI features. This is the most flexible way to bring outside models into Raycast, covering aggregators, cross-vendor gateways, and self-hosted proxies alike.

![Quick AI in Raycast answering with Claude Fable 5.1, with the model picker open showing models from a custom Vercel AI Gateway provider](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/ai/mac-custom-providers-quickai.png)

> [!NOTE]
> Custom provider requests are routed directly from your device to the provider's servers, bypassing Raycast entirely. Your API keys stay in the file on your device, and you pay the provider's standard rates for messages.

## Get Started

1. Open **Settings → AI** and scroll down to the **Custom Providers** section.
2. Click **Reveal Providers Config**. Raycast opens the config folder and places a `providers.template.yaml` file inside it, documenting the file format.
3. Copy the template to a file named `providers.yaml` in the same folder, then edit it with your providers and models.
4. Save the file. Raycast watches it for changes, so your providers and their model counts appear in the Custom Providers section right away, with no restart needed.

![The Custom Providers section in Raycast's AI settings, listing Vercel AI Gateway, OpenClaw, LM Studio, and LiteLLM with their model counts](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/ai/mac-custom-providers-settings.png)

The file lives at `~/.config/raycast/ai/providers.yaml` inside your user folder on both macOS and Windows.

> [!WARNING]
> If Raycast can't read your file, an **Invalid providers.yaml** badge appears next to Providers Config in Settings. Hover over the badge to see exactly what went wrong. Your previously loaded models keep working while you fix the file.

## Configuration Format

Each entry in the `providers` list needs an `id`, a `name`, an OpenAI API compatible `base_url`, and a list of `models`. Here's a trimmed example connecting a provider with one model:

```yaml
providers:
  - id: my_provider
    name: My Provider
    base_url: https://api.example.com/v1
    api_keys:
      my_provider: YOUR_API_KEY
    models:
      - id: my-model-id
        name: My Model
        provider: my_provider
        description: A short description shown in Raycast
        context: 200000
        abilities:
          temperature:
            supported: true
          vision:
            supported: true
          system_message:
            supported: true
          tools:
            supported: true
          reasoning_effort:
            supported: false
```

### Provider Fields

| Field | Required | Description |
| --- | --- | --- |
| `id` | Yes | Unique identifier for the provider entry |
| `name` | Yes | Provider name shown in Raycast |
| `base_url` | Yes | OpenAI API compatible endpoint, without the `/chat/completions` suffix |
| `api_keys` | No | Map of key aliases to API keys, omit for providers that don't require authentication |
| `additional_parameters` | No | Extra fields added to every `/chat/completions` request |
| `include_user_email` | No | Set to `true` to send your signed-in Raycast email as an `X-User-Email` header, useful for per-user attribution on a shared gateway |
| `models` | Yes | List of models to register, providers without any valid models are skipped |

### Model Fields

| Field | Required | Description |
| --- | --- | --- |
| `id` | Yes | Model identifier, must match the id the provider's API expects |
| `name` | Yes | Model name shown in Raycast |
| `provider` | No | Selects which alias in `api_keys` to use, defaults to the first key |
| `description` | No | Short description shown in Raycast |
| `context` | No | Context window size in tokens, refer to the provider's documentation |
| `abilities` | No | Capability flags for the model, see below |

### Abilities

Each ability is optional and takes a `supported: true` or `supported: false` value. When omitted, Raycast assumes system messages and temperature are supported, and tool use and vision are not. Declaring an ability the model doesn't actually support can make requests fail.

| Ability | Enables |
| --- | --- |
| `temperature` | Sending a temperature value with requests |
| `vision` | Image attachments in prompts |
| `system_message` | Sending a system message |
| `tools` | Tool use, required for AI Extensions |
| `reasoning_effort` | Reasoning effort control for reasoning models |

The `providers.template.yaml` file installed next to your config documents the same format with complete annotated examples.

> [!NOTE]
> The OpenAI API is not a formal standard, so we can't guarantee that every provider works correctly with Raycast AI. Refer to your provider's API documentation for model identifiers and capabilities.

## Examples

<Tabs.Root defaultValue="gateway">
  <Tabs.List>
    <Tabs.Trigger value="gateway">Vercel AI Gateway</Tabs.Trigger>
    <Tabs.Trigger value="proxy">LiteLLM Proxy</Tabs.Trigger>
    <Tabs.Trigger value="bedrock">AWS Bedrock</Tabs.Trigger>
    <Tabs.Trigger value="lmstudio">LM Studio</Tabs.Trigger>
    <Tabs.Trigger value="openclaw">OpenClaw</Tabs.Trigger>
    <Tabs.Trigger value="hermes">Hermes Agent</Tabs.Trigger>
  </Tabs.List>
  <Tabs.Content value="gateway">
    Cross-vendor gateways such as [Vercel AI Gateway](https://vercel.com/docs/ai-gateway) or [Cloudflare AI Gateway](https://developers.cloudflare.com/ai-gateway/) put models from every major lab behind a single endpoint and a single key, with usage tracking and spend controls in one dashboard:

    ```yaml
providers:
  - id: vercel_ai_gateway
    name: Vercel AI Gateway
    base_url: https://ai-gateway.vercel.sh/v1
    api_keys:
      vercel: VERCEL_AI_GATEWAY_KEY
    models:
      - id: anthropic/claude-fable-5.1
        name: "Claude Fable 5.1"
        context: 1000000
        abilities:
          temperature:
            supported: true
          vision:
            supported: true
          system_message:
            supported: true
          tools:
            supported: true
          reasoning_effort:
            supported: true
    ```
  </Tabs.Content>
  <Tabs.Content value="proxy">
    Team proxies such as [LiteLLM](https://docs.litellm.ai/) let one gateway hold the vendor keys while everyone on the team points Raycast at it. Turn on the optional email header so the proxy can attribute usage to each person:

    ```yaml
providers:
  - id: litellm
    name: LiteLLM
    base_url: http://localhost:4000
    # Sends your signed-in Raycast email as an `X-User-Email` header,
    # e.g. for per-user attribution or quotas on a shared gateway
    include_user_email: true
    models:
      - id: anthropic/claude-sonnet-5
        name: "Claude Sonnet 5"
        context: 1000000
        abilities:
          temperature:
            supported: true
          vision:
            supported: true
          system_message:
            supported: true
          tools:
            supported: true
    ```
  </Tabs.Content>
  <Tabs.Content value="bedrock">
    Cloud platforms like [Amazon Bedrock](https://docs.aws.amazon.com/bedrock/latest/userguide/inference-chat-completions.html) let you use models under your existing cloud account and billing. Bedrock exposes an OpenAI compatible endpoint per region, authenticated with a Bedrock API key:

    ```yaml
providers:
  - id: bedrock
    name: AWS Bedrock
    base_url: https://bedrock-runtime.us-east-1.amazonaws.com/openai/v1
    api_keys:
      bedrock: YOUR_BEDROCK_API_KEY
    models:
      - id: moonshotai.kimi-k2-thinking # use the Chat Completions model id from the Bedrock model catalog
        name: "Kimi K2 Thinking"
        context: 256000
        abilities:
          temperature:
            supported: true
          system_message:
            supported: true
          tools:
            supported: true
    ```
  </Tabs.Content>
  <Tabs.Content value="lmstudio">
    Local runners such as [LM Studio](https://lmstudio.ai/) serve open models straight from your own machine, with no API key and no data leaving your computer. Enable the server in LM Studio's Developer tab, then list the models you've downloaded:

    ```yaml
providers:
  - id: lmstudio
    name: LM Studio
    base_url: http://localhost:1234/v1
    # No `api_keys` - the local server doesn't require authentication
    models:
      - id: qwen/qwen3-14b # use the model id shown in LM Studio's server page
        name: "Qwen 3 14B"
        context: 32000
        abilities:
          temperature:
            supported: true
          system_message:
            supported: true
          tools:
            supported: true
    ```
  </Tabs.Content>
  <Tabs.Content value="openclaw">
    Local agents work too. [OpenClaw](https://docs.openclaw.ai/gateway/openai-http-api)'s gateway exposes an OpenAI compatible API, so you can chat with an agent that has its own tools and memory straight from Raycast:

    ```yaml
providers:
  - id: openclaw
    name: OpenClaw
    base_url: http://127.0.0.1:18789/v1
    api_keys:
      # Your gateway token from `gateway.auth.token` or OPENCLAW_GATEWAY_TOKEN
      openclaw: YOUR_GATEWAY_TOKEN
    models:
      - id: openclaw/default # stable alias for your default agent
        name: "OpenClaw"
        description: Your local OpenClaw agent
        abilities:
          temperature:
            supported: true
          system_message:
            supported: true
    ```
  </Tabs.Content>
  <Tabs.Content value="hermes">
    You can also use [Hermes Agent](https://hermes-agent.nousresearch.com/docs/user-guide/features/api-server) inside Raycast AI, complete with its own tools, memory, and skills. Enable its API server with `API_SERVER_ENABLED=true` and an `API_SERVER_KEY` in `~/.hermes/.env`, start it with `hermes gateway`, then point Raycast at it:

    ```yaml
providers:
  - id: hermes
    name: Hermes Agent
    base_url: http://127.0.0.1:8642/v1
    api_keys:
      # The API_SERVER_KEY value from ~/.hermes/.env
      hermes: YOUR_API_SERVER_KEY
    models:
      - id: hermes-agent # the default profile, or use a profile name
        name: "Hermes Agent"
        description: Your local Hermes agent
        abilities:
          temperature:
            supported: true
          vision:
            supported: true
          system_message:
            supported: true
    ```
  </Tabs.Content>
</Tabs.Root>

## Using Custom Models

Custom provider models show up in the model picker grouped under the provider's name you set in the file. Pick them anywhere you'd pick a Raycast AI model, including [Quick AI](https://manual.raycast.com/ai/quick-ai), [AI Chat](https://manual.raycast.com/ai/ai-chat), and [AI Commands](https://manual.raycast.com/ai/ai-commands). Since Raycast has no benchmark data for custom models, they don't show speed or intelligence scores in the model settings.

If you only want models from OpenRouter, adding an OpenRouter API key via [Bring Your Own Keys](https://manual.raycast.com/ai/bring-your-own-keys) unlocks its full catalog automatically. If you run local models with Ollama, Raycast supports this natively with [Local Models](https://manual.raycast.com/ai/local-models) and detects your models automatically for you.

## FAQ

### Should I use Custom Providers or Bring Your Own Keys?

They solve different problems. [Bring Your Own Keys](https://manual.raycast.com/ai/bring-your-own-keys) is for when you want to keep using the models Raycast AI already offers, but pay Anthropic, Google, OpenAI, or OpenRouter directly with your own API key. Setup is a single key, and Raycast handles the rest.

Custom Providers are for going beyond what Raycast AI supports natively. Use them to reach models from providers Raycast doesn't offer, or to route requests through a gateway, a team proxy, a local agent, or any other OpenAI API compatible endpoint. You describe the models yourself in a config file, in exchange for full control over where requests go.

### Can I manage custom providers for everyone in an organization?

Yes, Enterprise organizations can upload a [Custom Provider Configuration](https://manual.raycast.com/enterprise/custom-provider) that applies to every member. When one is configured, it replaces your local `providers.yaml`, and the Custom Providers section in settings shows that your organization manages the configuration.

### Are my API keys sent to Raycast?

No. Your keys stay in the `providers.yaml` file on your device, and every request goes directly from your device to the provider. Raycast's servers never see your keys or your prompts for custom models.

### Do custom models count against Raycast AI usage limits?

No. Custom provider requests never pass through Raycast's servers, so they don't count towards your [Raycast AI usage limits](https://manual.raycast.com/ai/usage-limits). Your only limits are the ones your provider sets for your key.

### Does my providers.yaml sync between devices?

No. The file lives on disk outside of Cloud Sync, so each machine needs its own copy. Keep the file somewhere you can copy it from, or manage it with your own dotfiles setup.

## Troubleshooting

### I deleted or broke the template file

Click **Reveal Providers Config** in **Settings → AI** again. Raycast rewrites `providers.template.yaml` on every reveal, so it always documents the current schema.

### My custom model returns errors or behaves oddly

First, test the same `base_url` and model id outside Raycast, for example with `curl`, to rule out a provider or key problem. If that works, the cause is almost always the `abilities` block. Double-check the model `id` matches the provider's identifier exactly, and review each ability against the provider's documentation. Declaring an unsupported ability, such as `tools` on a model without tool support, is the most common cause of failed requests.

### My models don't appear in the model picker after saving

Work through these in order:

1. Open **Settings → AI** and check for an **Invalid providers.yaml** badge next to Providers Config. Hover over it to see the parse error.
2. Make sure the file is named exactly `providers.yaml`, not `providers.template.yaml`, and sits in the `ai` folder that **Reveal Providers Config** opens.
3. Make sure each provider has at least one model with both an `id` and a `name`. Providers without valid models are skipped silently.
4. Check that the Custom Providers section doesn't say **Managed by your organization**. An organization configuration replaces your local file.
5. Confirm your Raycast Pro subscription is active, since custom models are Pro-only.

### Still having issues?

If none of the above resolves it, gather the following and send it to us via the [Send Feedback](raycast://extensions/raycast/raycast/send-feedback) command so we can investigate (see [Contact Support](https://manual.raycast.com/contact-support) for more ways to get in touch):

1. **Your OS version** and **Raycast version** (found in **Settings → About**).
2. **Your `providers.yaml` contents**, with every value under `api_keys` replaced by `REDACTED`. Never share your real API keys.
3. The **error text** from the **Invalid providers.yaml** badge tooltip, if one is shown.
4. The **model** you picked and the **AI feature** you used when the request failed.
5. Whether a **direct request to the provider works** outside Raycast, for example with `curl` against the same `base_url` and model.
6. **Your Raycast logs**: use the built-in **Copy Raycast Logs** command to copy your latest log files to the clipboard, or **Reveal Raycast Logs** to open your log folder.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Custom Providers. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
