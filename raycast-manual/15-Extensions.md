> Source: https://manual.raycast.com/extensions
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Extensions

> Available on: Mac, Windows

Extensions add commands, integrations, and AI tools to Raycast — install thousands from the Store or build your own to create your perfect workflow.

Extensions are the building blocks of your Raycast experience. Each one adds a focused set of commands, whether that's a quick utility, a search shortcut, or a deep integration with the tools you rely on. Raycast includes a set of built-in extensions out of the box, with thousands more available in the Store. 

## Store

The Store is where you discover and install extensions built by the Raycast community, as well as private extensions if you're part of an organization. Open it using the **Store** command in Root Search.

![Screenshot showing the Store extension in Raycast](https://fz1sd71lwhbqy6sh.public.blob.vercel-storage.com/raycast/images/app/extensions/mac-extensions-store.png)

Browse the Store by name, command, keyword, or category. Only compatible extensions for Raycast on your OS appear in results, so everything you see works on your machine. Open any extension to see its description, commands, screenshots, and author details, then press ⏎ to install. It's added to Raycast instantly, ready to use from the Store listing or from Root Search.

**Teams** If you belong to an organization on Raycast, private extensions appear in the Store alongside public ones. To find them, select **Filter by Organization** in the Navigation Bar and choose your organization. Private extensions are only visible to members and follow the same installation process as public extensions.

### Installed Extensions

Filter the Store to show only installed extensions by opening the **Categories** dropdown in the Navigation Bar and selecting ** Installed**. From there, press `⏎` to go directly to an extension's Store listing, or open the [Action Panel](https://manual.raycast.com/action-panel) to view all available actions including uninstall, configure, or view its source code.

## AI Extensions

AI Extensions give Raycast AI the ability to take action across your installed extensions. Instead of running a command yourself, describe what you want in [AI Chat](https://manual.raycast.com/ai/ai-chat) or [Quick AI](https://manual.raycast.com/ai/quick-ai) and Raycast picks the right tool automatically — whether that's searching your clipboard history, finding a file, checking a Linear ticket, or anything else an extension supports.

Store extensions can ship AI Extensions alongside their regular commands. Raycast's own built-in extensions come with AI Extensions too. You can review and configure which tools are available to AI in **Settings → Extensions**.

Explore the [AI Extensions](https://manual.raycast.com/ai/ai-extensions) page for more information.

## Check for Updates

Raycast automatically applies updates to your installed Store extensions in the background as they become available from the extension's maintainers. If you'd prefer to pull updates manually, or grab one the moment it's published, use the **Check for Extension Updates** command.

Automatic updates only apply to extensions installed from the Store. Local development extensions added via the **Import Extension** command are managed by you and aren't updated from the Store.

## Create Your Own

If you can't find what you're looking for, you can build a Raycast Extension yourself. The Raycast Extension API lets you create extensions using React, TypeScript, and Node, with a built-in UI component library to get you up and running fast.

> [!NOTE]
> When you run `npm run dev` on Mac, your extension opens in Raycast v2 if it's running and falls back to Raycast v1 otherwise. Run `npm install @raycast/api@latest` to ensure your extension picks up the latest dev command behavior.

Check out the [Extension API Manual](https://developers.raycast.com) for more information.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Extensions. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
