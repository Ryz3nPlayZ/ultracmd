> Source: https://manual.raycast.com/ai/model-context-protocol
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Model Context Protocol

> Available on: Mac, Windows, iOS
> Tier: Pro Exclusive

Connect Model Context Protocol (MCP) servers to Raycast AI to extend Chat with custom tools, data sources, and integrations from across your stack.

Model Context Protocol (MCP) is how you plug external tools and data sources into Raycast AI. Once a server is connected, its tools become available to AI Chat, Quick AI, and AI Commands alongside everything Raycast already knows about you and your installed extensions.

## Install MCP Servers

**Desktop**

To add a new MCP server, search for the **Install MCP Server** command or use the **Install New Server** action in the **Manage MCP Servers** command then fill out the form. Give the server a name & icon, select the transport & connection details, optionally a description.

  Press **Install MCP Server** (`⌘ ↵`/`Ctrl ↵`) and Raycast saves the config, starts the connection, and pulls in the tool list automatically. Stdio servers run as soon as they're installed; HTTP servers with OAuth will prompt you to **Sign In** before any tools become available.

> [!TIP]
> If a stdio command relies on something on your `PATH`, restart Raycast after updating your environment variables so the new values are picked up.

**iOS**

1. Tap **Account Avatar → AI → MCP Servers**.
  2. Tap **Plus icon** in the top right to add a server, or pick one from **Popular MCP Servers** to prefill the form.
  3. Give the server a **Name** and its **URL**, and optionally a **Description** and **Custom Instructions**. Choose the **OAuth Type** and add any **HTTP Headers** the server needs.
  4. Tap **Save**. Raycast connects, prompts you to sign in if the server uses OAuth, and pulls in its tool list automatically.

  You can also ask **AI Chat** to set one up. Ask the chat something like "add the Linear MCP server" and Raycast AI finds the right endpoint, fills in the details, and asks you to confirm before connecting to the MCP server.

### Configuration Fields

- **Name & Icon**: How the server appears in lists, mentions, and the Action Panel.
- **Transport**: *Standard Input/Output* or *HTTP*. iOS is always HTTP.
- **Command** *(stdio)*: The executable to run, e.g. `npx` or a path to a binary.
- **Arguments** *(stdio)*: Passed to the command. Accepts a space‑separated string or a JSON array.
- **Environment** *(stdio)*: Key/value pairs injected into the server's environment, e.g. API tokens.
- **URL** *(HTTP)*: The server's MCP endpoint.
- **HTTP Headers** *(HTTP)*: Key/value pairs sent on every request.
- **OAuth Type** *(HTTP)*: *Dynamic* if the server supports OAuth Dynamic Client Registration, *Static* if you need to provide your own credentials.
- **Client ID / Client Secret / Scopes** *(HTTP, Static OAuth only)*: Pre‑registered OAuth credentials and the scopes to request.
- **Custom Instructions**: Optional guidance for how Raycast AI should use the server (see [Using MCP Servers](#using-mcp-servers)).
- **Description**: Optional shown in the details pane.

### Transports

Raycast supports two ways of talking to an MCP server:

- _(Available on Mac and Windows)_ **Standard Input/Output**: A local process that Raycast launches and pipes JSON‑RPC over stdin/stdout. Good for anything you'd run from the terminal: `npx`, a Python script, a compiled binary.
- _(Available on Mac, Windows, and iOS)_ **HTTP**: A remote endpoint that speaks MCP over HTTP (including the Streamable HTTP variant). Good for hosted services, and the only transport available on iOS.

### Authentication

For HTTP servers that require OAuth, Raycast handles the full flow. Dynamic OAuth uses Dynamic Client Registration with PKCE: select **Sign In** and Raycast registers itself as a client. Static OAuth uses a Client ID (and optional Secret) you provide, which services like Slack require. Tokens are stored encrypted, per server.

On Desktop, the **Logout Server** action in the **Manage MCP Servers** command clears saved tokens for an HTTP server without removing it.

### Popular MCP Servers
_(Only on iOS)_

The **MCP Servers** tab in Settings suggests popular servers you can connect to, including GitHub, Linear, PostHog, and Shape. Tap **Connect** to start the OAuth flow, or **Set Up** for servers that need an access token, and Raycast prefills the form for you. Once connected, the popular MCP server will move to the connected servers list.

## Manage MCP Servers

**Desktop**

Search **Manage MCP Servers** in Raycast to see every installed server with its status, tool list, and details in one place. Each server is either **Running** (connected and serving tools), **Stopped** (installed but not connected), or in an **Error** state. The details pane shows the full output from the server or transport.

  From this command, you can start a new chat with the selected server or open the Action Panel for more options: Add Server, Refresh, Start, Stop, Restart, Logout, and Uninstall.

**iOS**

Tap **Account Avatar → AI → MCP Servers** to see every server you've connected. Each row shows its tool count and URL, or a red error message if the connection failed. Tap a server to edit its details, headers, OAuth, and custom instructions.

  Swipe a server left to ** Refresh** its tools or ** Delete** it, or tap **Refresh icon** in the top bar to refresh every server at once. Deleting a server also clears its saved OAuth tokens.

## Using MCP Servers

Every server gets a `@-mention` name, just like AI Extensions. In AI Chat or Quick AI, type `@` and enter the server's name to scope a question to it — type `@linear what's assigned to me?` to ask the Linear MCP server directly.

_(Available on Mac and Windows)_ Raycast also adds an **Ask** command for each installed server to Root Search (e.g. **Ask Linear**), prefilling Quick AI with that mention.

### Custom Instructions

Each server has an optional **Custom Instructions** field. Use it to steer how Raycast AI works with that server, for example "default my Linear queries to the Platform team." The AI reads these instructions whenever it considers using the server's tools.

### Permissions
_(Available on Mac and Windows)_

By default, Raycast asks for approval before running any tool from an MCP server. You can change the default option in **Settings → AI → Permissions**, or override it for a single chat from the AI Chat's Chat Settings menu.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Model Context Protocol. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
