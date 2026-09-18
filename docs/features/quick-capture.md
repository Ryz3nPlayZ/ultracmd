# Quick Capture

Quick Capture turns a typed line into the thing it names, through the launcher's fallback section:
type `Dinner tomorrow 7pm`, `Call mom tomorrow 5pm`, `25m`, `tea 5m`, `coffee near me` or
`directions to SFO`, and the `Use “…” with…` rows offer Add Event, Add Reminder, Start Timer and
Search Maps against it. `New Email`, `New Message` and `New FaceTime` are plain commands that open
Mail, Messages and FaceTime on their compose surfaces.

Everything lives in `Features/QuickCapture/`; the launcher wiring (`CommandID`, `Fallback`,
`FallbackCoordinator`) points here and owns nothing but the routing.

## Invariants

- **The parser is pure.** `QuickCaptureParser` imports Foundation only, takes the line as its only
  input, and is covered by `quick-capture-test`. NSDataDetector resolves relative phrases against
  the current moment, so date assertions in the harness are structural, never absolute.
- **Consent belongs to the capture.** No EventKit store, no Reminders access, no
  notification center exists until a capture runs; permission prompts are raised by the capture
  that needs them, never at launch. See `Permissions.requestRemindersAccess`.
- **Quick Add Event rides the Calendar feature's consent.** The row is offered only while
  `calendarEnabled`, and the save goes through `CalendarStore.createEvent`, so there is exactly one
  calendar gate and one EventKit lifecycle. A no-date line means "soon": half an hour out, one hour
  long.
- **A line the parser cannot split keeps its text.** When NSDataDetector swallows the whole line
  (`Dinner tomorrow at 7pm` reads as one event phrase), the title falls back to the full text
  rather than an empty event.
- **A timer that cannot be read is refused, not guessed.** No duration in the line is a HUD report
  with the shapes that do work; the rest of the line names the notification ("tea 5m" is a tea
  timer), and a line that is only a duration names nothing.
- **Maps routes only on "directions to" / "route to".** Anything else — "near me" included — is a
  plain search; both go through the `maps://` URL scheme, so there is no MapKit dependency and no
  location permission.
- **Compose targets are URL schemes, not AppleScript.** `mailto:`, `sms:` and `facetime:` hand off
  to whatever the system has registered; a missing app is macOS's own report to make.

## What is deliberately not here

Reminders capture writes through EventKit (`EKReminder` on the default list), not AppleScript, so
there is no automation permission and no dependency on the Reminders app's scripting dictionary.
Timer notifications are fire-and-forget: there is no running-timer surface, no cancellation
command, and no persistence — the notification is the whole feature.
