# Support

One window, one outbound link, and no reminder. **This fork takes no money**: the button credits
the original project — `SupportCoordinator.checkout` opens Tinycast's repository, the project
UltraCMD is a rebranded fork of, and `AppCore.start()` leaves `supportReminders.onDue` unset so the
window never reopens itself. The command, the app menu and Settings → About still show it on demand.

## Invariants

- **The reminder never fires.** The store is wired but unarmed: `onDue` is nil and `start()` is
  never called, so the schedule file never advances an anchor. `presentIfDue()` stays for the day
  the fork wants asks again.
- **One button, one link.** `SupportCoordinator.checkout` is the only destination, and no surface
  restates what is behind it — the repository page owns that, so nothing here can fall out of step
  with it. Adding a second button means adding a second thing to keep in sync.
- **The button is the composition, not its footer.** It sits under the hero at 46pt tall, because this
  window asks where the update window reports — an actions row pinned to the bottom edge reads as a
  utility dialog.
- **Brand colour appears exactly twice**: the app icon, which is violet on its own, and the button.
- **Support's views are Support's own.** `SupportActionButton` is private to `SupportWindowView`
  rather than reaching for Onboarding's card rows, which are that window's.

## How it is put together

| Piece | Holds |
| --- | --- |
| `Model/SupportReminderSchedule.swift` | pure — seconds until the next ask, clamped at both ends |
| `Service/SupportReminderStore.swift` | the JSON state, and the one `Task` pump that offers the ask |
| `UI/SupportCoordinator.swift` | the window's lifecycle, the checkout link, the anchor write |
| `UI/SupportWindowView.swift` | the window: hero, the button, and the reminder checkbox |

`SupportReminderStore.advance()` is one turn of the pump: it answers how long to sleep, and calls
`onDue` when the wait has reached zero. `AppCore.start()` wires that closure to
`supportCoordinator.presentIfDue()`. The store itself never presents anything and never writes the
anchor on its own — that write belongs to the coordinator, so there is exactly one of it.

The wait after an offer is floored at the retry interval. Showing the window is what moves the anchor,
and the floor is what stops the pump spinning if it did not.

## The window

`AppWindowController` at 460pt wide, taking the height its content measured through
`.onGeometryChange` → `fit(height:)`. It is titled and transparent-titlebar'd, so `ActivationPolicy`
brings the Dock icon in and out on its own, and `⌘W` or the close button dismisses it.

The composition is centred: a shadowed 76pt app icon, the ask in `.title2`, one line of copy, then
the button and the reminder switch. Nothing carries a keyboard shortcut —
with a custom button style there is no focus ring to advertise one, and ↵ silently opening a payment
page is a surprise rather than a convenience.

Only the mechanism is shared with the Software Update window — `AppWindowController`, the
content-measured height and the `sheen` gradient. The layout deliberately is not: that window reports
and closes, so its actions belong in a trailing row; this one asks, so the ask is the centrepiece.

## Where it is reachable from

The palette's bottom-left menu circle (between About and Settings), Settings → About, the menu bar
menu, and the launcher as `CommandID.support`. All four land on `showSupport()`. The launcher arm
hides the palette first, the way `.about` does; the menu-circle row does not, because the panel
dismisses itself on `windowDidResignKey`.
