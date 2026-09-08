> Source: https://manual.raycast.com/ai/local-models
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Local Models

> Available on: Mac, Windows
> Tier: Pro Exclusive

Run open models on your own Mac or PC through Ollama and use them across Raycast AI. No internet, no usage limits, nothing leaves your machine.

Local Models let you use AI models running on your own machine through [Ollama](https://ollama.com/) in Raycast AI. Everything stays local on your own computer. Download a model once and it's yours: it works with no internet connection, keeps every prompt on your machine, and never touches a usage limit. Raycast detects the models you've installed automatically and adds them to the model picker alongside other Raycast AI models.

> [!NOTE]
> Requests to local models go straight from Raycast to the Ollama server on your machine. Nothing is sent to Raycast's servers or to any third party.

## Get Started

1. Install the [Ollama app](https://ollama.com/download) if you don't have it yet. You can also click **Install Ollama app** in **Settings → AI → Local Models**.
2. Open **Settings → AI** and scroll down to the **Local Models** section.
3. Type a model name into **Install Ollama Model**, for example `qwen3.8:latest`, and click **Install**. Click **Model Library** to browse all available models on ollama.com.
4. Once the download finishes, the model appears in the model picker under the **Local** section, ready to use.

Models you've downloaded directly with `ollama pull` are detected too. If one hasn't shown up yet, click **Sync Models**. The status line at the bottom of the section in Settings shows how many models are installed and when Raycast last synced.

> [!NOTE]
> Raycast starts the Ollama server for you when you use a local model, so you don't need to keep the Ollama app open.

## Using Local Models

Local models work in [Quick AI](https://manual.raycast.com/ai/quick-ai), [AI Chat](https://manual.raycast.com/ai/ai-chat), and [AI Commands](https://manual.raycast.com/ai/ai-commands). Pick them from the model picker like any other model. Raycast reads each model's capabilities from Ollama, so models that support vision accept image attachments, models that support tool use work with AI Extensions, and thinking models show their reasoning.

Since Raycast has no benchmark data for local models, they don't show speed or intelligence scores in the model settings. Performance depends entirely on your hardware and the model size you choose. Smaller models respond faster, while larger models give better answers at the cost of speed and memory.

> [!NOTE]
> Local models don't power the Extension AI API or Emoji Search. Those features continue to use Raycast AI.

## Managing Models

- **Install a model** from the **Local Models** section in **Settings → AI**, or with `ollama pull` in your terminal.
- **Delete a model** from **Settings → AI → Models**. Click **Actions menu** on a local model and choose ** Delete Model**. This removes the download from your disk, so Raycast asks you to confirm first.
- **Disable a model** without deleting it by unchecking it in **Settings → AI → Models**, the same as any other model.

## Remote Ollama Servers

If you run Ollama on another machine, such as a home server with a bigger GPU, point Raycast at it with the **Ollama Host** field in **Settings → AI → Local Models**. Enter the host in the same form as the default, for example `http://192.168.1.20:11434`. Leave the field empty to use Ollama on your own machine.

> [!WARNING]
> Raycast doesn't start remote servers for you. Make sure the remote Ollama server is running and reachable from your machine, otherwise its models won't load.

## FAQ

### Which model should I install?

It depends on the hardware available on your machine. A general-purpose model such as `qwen3.8:latest` runs well on most modern laptops. If you have plenty of memory, larger variants of a model give better and more detailed answers. Look for models tagged with vision and tools on the [Ollama model library](https://ollama.com/search) if you want image attachments and AI Extensions.

### Is anything sent to Raycast when I use a local model?

No. Your prompts, attachments, and the model's responses stay between Raycast and the Ollama server on your machine. Raycast only stores your chat history locally, and in Cloud Sync if you have it enabled.

### Do local models count against Raycast AI usage limits?

No. Local model requests never reach Raycast's servers, so they don't count towards your [Raycast AI usage limits](https://manual.raycast.com/ai/usage-limits).

### Can I use LM Studio or another local server instead of Ollama?

Yes, through [Custom Providers](https://manual.raycast.com/ai/custom-providers). Any local server with an OpenAI compatible API works, though you'll describe the models yourself in a config file rather than having Raycast detect them.

## Troubleshooting

### Settings says Ollama is not installed, but I have it

Raycast looks for the Ollama app, the `ollama` command line tool, or a running server. If you installed Ollama in an unusual location, start the Ollama app once so its server is running, then click **Sync Models**. Setting the **Ollama Host** field explicitly also tells Raycast where to look.

### A model I installed doesn't appear in the picker

Click **Sync Models** in **Settings → AI → Local Models** to re-scan the server. If the model still doesn't appear, run `ollama list` in your terminal to confirm Ollama sees it. Models that Ollama lists but Raycast can't inspect are left as they were until the next successful sync.

### Responses are slow or the model runs out of memory

Switch to a smaller model, or a smaller variant of the same model. Local models run on your hardware, so a model that's too large for your memory will be slow or fail to load. Raycast also caps the context sent to local models at 64k tokens to keep responses reliable.

### Still having issues?

If none of the above resolves it, gather the following and send it to us via the [Send Feedback](raycast://extensions/raycast/raycast/send-feedback) command so we can investigate (see [Contact Support](https://manual.raycast.com/contact-support) for more ways to get in touch):

1. **Your OS version** and **Raycast version** (found in **Settings → About**).
2. **Your Ollama version**, from `ollama --version`, and whether you use a custom **Ollama Host**.
3. The **model** you were using, and the output of `ollama list`.
4. The **AI feature** you used when the problem occurred, and what happened.
5. **Your Raycast logs**: use the built-in **Copy Raycast Logs** command to copy your latest log files to the clipboard, or **Reveal Raycast Logs** to open your log folder.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Local Models. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
