> Source: https://manual.raycast.com/calendar
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Calendar

> Available on: Mac

View upcoming meetings, join calls instantly, and manage your day from Raycast — a built-in calendar always one shortcut away.

Raycast makes it easy to check your upcoming schedule, create events, and join conference calls without switching context. Raycast's Calendar features are built on the native macOS Calendar via EventKit, so any accounts already configured in the macOS Calendar app — Google, iCloud, Microsoft/Exchange, and more — work automatically.

## Check Your Schedule

Use the My Schedule command to quickly check your availability, block focus time, or get an overview of your day.

- The summary at the top shows your next upcoming meeting.
- The sections below are dynamic. They help you focus on the here and now: this week is represented as days, followed by sections for the next week, the rest of the month, and the upcoming months.
- Press `⌘ K` to open the [Action Panel](https://manual.raycast.com/action-panel) to join conference calls, accept or decline invitations, block time, email attendees, or copy your availability.
- Use the Search Bar to filter events by title.
- Configure which calendars appear in the extension's preferences. You can fine-tune exactly which calendars show up in My Schedule.

## Create Events

Use the Create Event command to quickly add a new event without leaving Raycast.

- Set the title, start and end times, target calendar, attendees, location, URL, notes, and reminders.
- Events are written to the macOS Calendar and sync with whichever account the chosen calendar belongs to.

## Ask Calendar (AI)

Type `@calendar` in [AI Chat](https://manual.raycast.com/ai/ai-chat) to ask natural-language questions about your schedule or make changes hands-free. Examples:

- What's on my calendar tomorrow?
- Schedule a meeting with Sam at 3pm on Thursday
- Move my 2pm meeting to 4pm
- Block off Friday afternoon
- Who's attending my next meeting?

Ask Calendar can read, create, edit, and delete events on your behalf.

## Join Events

Raycast shows your next event at the top of [Root Search](https://manual.raycast.com/search-bar) to make it convenient to join. Just hit `⏎` to open the conference call. If a native app is installed for the conference service (for example the Zoom or Microsoft Teams desktop client), the app is opened directly without an extra browser tab.

- Google Meet links can be configured to open in a specific browser via the extension preferences — useful if you prefer Chromium-based browsers for Google features.

## Auto-Join Events

Raycast can automatically join events when they are about to begin. When enabled, Raycast will automatically join events with meeting links in your enabled calendars that you are attending.

- Confirmation alert: by default an alert with a confirmation prompt is shown before joining. Disabling this is useful if your conferencing app already has its own confirmation screen.
- Open camera before joining: optionally open the Mac's camera (preview) just before a meeting starts, so you can check framing before you're live.
- Auto-transcribe meetings: optionally transcribe meetings automatically as they happen, with an exclusion list so specific meetings (matched by keyword) are skipped.

Auto-join is disabled initially but can be enabled in the preferences of the My Schedule command, alongside the options above.

## Menu Bar Agenda

Raycast can show your next event in the macOS menu bar so you always know what's coming up. Configure in the Calendar extension preferences:

- Choose when to show the next event: never, always, only when an event is upcoming, or when it starts within a set number of minutes.
- Meetings only: filter out all-day and non-meeting events so only joinable meetings appear.
- Auto-hide after the event ends or after a custom number of minutes.
- Menu actions include: Open My Schedule, Open the Calendar app, Join meeting, and Dismiss event.

## Supported Conference Providers

Raycast detects and launches conference links for the following providers from event URLs, locations, and descriptions:

- Zoom
- Google Meet
- Microsoft Teams
- Slack Huddles
- Webex
- FaceTime
- Skype
- BlueJeans
- Amazon Chime
- Whereby
- Jitsi
- Around
- Chorus
- Riverside
- StreamYard

## Keyboard Shortcuts

- `⏎` to open the event in the macOS Calendar app
- `⌘ ⏎` to join a conference call
- `⌃ A` to accept the event (when RSVP is pending)
- `⌃ D` to decline the event (when RSVP is pending)
- `⇧ ⌘ B` to block time
- `⇧ ⌘ E` to email all attendees
- `⌃ ⌥ A` to copy your availability
- `⌘ .` to copy event details
- `⇧ ⌘ .` to copy event title
- `⇧ ⌘ ,` to copy event attendees
- `⌃ X` to delete event

## Troubleshooting

The Calendar extension accesses the native macOS calendars. If you can't see events or can't join meetings:

1. Make sure Raycast has access to your calendars in **System Settings → Privacy & Security → Calendars**.
2. Make sure the accounts you want are set up and syncing in the native macOS **Calendar** app.
3. Make sure the individual calendars you're interested in are enabled in **Settings → Extensions**. You can fine-tune exactly which events appear in the My Schedule command.
4. If Auto-Join doesn't trigger, make sure the event has a valid conference URL in its Location, URL, or Notes field — Raycast looks for a recognized provider URL in any of these.
5. If Open-Camera-Before-Joining doesn't work, grant Raycast camera access in **System Settings → Privacy & Security → Camera**.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Calendar. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
