> Source: https://manual.raycast.com/games
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Games

> Available on: Windows

Launch every game on your PC from Raycast — automatically discovers titles from Steam, Epic, GOG, and more, with Game Mode to silence hotkeys while you play.

Games turns Raycast into a single launcher for the games installed on your PC. Grouped with your apps, per-game actions for launching, and smart enough to step out of the way while you play by silencing global hotkeys in Game Mode.

## Getting Started

- Open **Settings → Games**. The extension is enabled by default. If you've disabled it previously, toggle it on in the top right.
- Type a game's name in [Root Search](https://manual.raycast.com/search-bar) to Open it.
- Run the **Game Launcher** command to browse every installed game and launcher in one place.
- (Optional) On the Games settings page, turn on **Game Mode** to pause Raycast hotkeys while a game window is detected in the foreground.

## Discovery

When Raycast is open on your system, it will automatically scan your system for games installed through the following launchers:

- Steam
- Epic Games Launcher
- GOG Galaxy
- Battle.net
- Ubisoft Connect
- EA (EA app / Origin)
- itch.io
- Xbox app (Microsoft Store / MSIX titles)
- NVIDIA GeForce NOW
- Riot Games
- Rockstar Games
- Battlestate Games
- Roblox

In addition to these launchers, Raycast will treat any app as a game when registered with Windows' Game Config Store.

### Game Mode

When Game Mode is enabled, Raycast monitors the active foreground window. If it detects a game (either from Raycast's classification, the Windows Game Config Store, or a full-screen exclusive Direct3D window), it temporarily pauses all Raycast hotkeys. As soon as you switch windows or the game loses focus, hotkeys are resumed.

> [!NOTE]
> Game Mode only pauses hotkeys for the active window. Running a game in the background won't pause the Raycast hotkeys.

## Tips

Search "Games" in Raycast to view all your games and game launchers. If a game is mistreated as an Application, press `Ctrl K` and select **Mark as Game** to update the classification. You can also use this to reclassify Applications that are incorrectly marked as Games.

## FAQ

### Do I need to connect Raycast to the launchers?

No. Game discovery is local on your system and Raycast reads installed-game metadata from disk and the registry, not from online libraries.

### What exactly does Game Mode do?

It pauses all hotkeys, including the Raycast hotkey, whenever a game window is in the foreground. As soon as the game window loses focus, hotkeys are resumed.

### Can I exclude a specific game from Game Mode?

Not directly. The best option to do this would be to reclassify the game as an application by using the **Treat as Application** action. Once an item is reclassified as a regular app, it no longer trips the foreground-game check.

### Why don't I have the Games settings page?

The Games settings page (and Game Mode) is only shown in Raycast for Windows version 0.35 and above. On macOS, there's no Games extension to configure.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Games. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
