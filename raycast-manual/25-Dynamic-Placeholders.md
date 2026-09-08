> Source: https://manual.raycast.com/dynamic-placeholders
> Scraped from the Raycast Manual (https://manual.raycast.com)

# Dynamic Placeholders

> Available on: Mac, Windows

Insert clipboard contents, dates, cursor position, and calculated values automatically into Snippets and Quicklinks with Dynamic Placeholders.

You can make your [Quicklinks](https://manual.raycast.com/quicklinks), [Snippets](https://manual.raycast.com/snippets), and [AI Commands](https://manual.raycast.com/ai/ai-commands) dynamic with placeholders. The supported placeholders are:

| Name | Placeholder | Description |
| --- | --- | --- |
| Clipboard Text | `{clipboard}` | Inserts your last copied text. The placeholder is removed if no text has been copied recently. |
| Snippets | `{snippet name="…"}` | Inserts the content of the referenced snippet. Only snippets that don't reference other snippets can be inserted. |
| Cursor Position ¹ | `{cursor}` | Moves the cursor to this position when pasted or injected. A snippet can contain only one `{cursor}` placeholder. |
| Date ¹ ³ | `{date}` | Inserts the current date, e.g. 1 Jun 2022. |
| Time ¹ ³ | `{time}` | Inserts the current time, e.g. 3:05 pm. |
| Date & Time ¹ ³ | `{datetime}` | Inserts both date and time, e.g. 1 Jun 2022 at 6:45 pm. |
| Weekday ¹ ³ | `{day}` | Inserts the day of the week, e.g. Monday. |
| UUID ¹ ³ | `{uuid}` | Inserts a universally unique value, e.g. `E621E1F8-C36C-495A-93FC-0C247A3E6E5F`. |
| Selected Text ² ³ | `{selection}` | Inserts the selected text from the frontmost application. In AI Chat, the previous message is inserted instead. |
| Argument | `{argument}` | Prompts for input in the search bar. Replaced by the argument's value. You can add a maximum of 3 different arguments. |
| Calculator ¹ ² ³ | `{calculator}` | Evaluates a math expression. |
| Focused Browser Tab ² ⁴ | `{browser-tab}` | Inserts the content of the focused browser tab. |

¹ Only available in Snippets  
² Only available in AI Commands  
³ Only available in Quicklinks  
⁴ Only available when the [Browser Extension](https://raycast.com/browser-extension) is installed

## Modifiers

Using modifiers, you can transform the value of a placeholder with the `{clipboard | uppercase}` syntax. Modifiers work on all placeholders.

Available modifiers:

- `uppercase` → transforms `Foo` into `FOO`
- `lowercase` → transforms `Foo` into `foo`
- `trim` → transforms `  Foo Bar  ` into `Foo Bar` — removes whitespace from the beginning and end
- `percent-encode` → transforms `Foo Bar` into `Foo%20Bar` — replaces [special characters](https://developer.mozilla.org/en-US/docs/Glossary/Percent-encoding) with percent-encoded equivalents
- `json-stringify` → transforms `Foo "Bar"` into `"Foo \"Bar\""` — ensures the value can be safely used as a JSON string

You can chain multiple modifiers: `{clipboard | trim | uppercase}`.

Depending on where the placeholder is used, Raycast may apply default formatting automatically:

- **Quicklinks** → Special characters are percent-encoded to keep the link valid.
- **AI Commands** → Placeholders are wrapped with `"""` to delimit them for the AI.

To opt out of this default formatting, use the `raw` modifier: `{clipboard | raw}`.

## Date & Time Offset

By default, date and time placeholders use the current date/time when the snippet is inserted. To use a relative date/time, add an offset modifier.

An offset modifier has three parts:

- A `+` or `-` sign for the direction
- A number
- A unit letter: `m` (minutes), `h` (hours), `d` (days), `M` (months), `y` (years)

> [!NOTE]
> `m` (lowercase) is minutes and `M` (uppercase) is months. All units are case-sensitive.

Separate the modifier from the keyword with spaces. You can combine multiple offsets in a single placeholder:

- `{date offset="+2y +5M"}`
- `{time offset="+3h +30m"}`
- `{day offset=-3d}`
- `{datetime offset=+1h}`

> [!NOTE]
> There must be no space after the sign. `{date offset="+ 2d"}` is not valid — the correct form is `{date offset="+2d"}`.

When you type a valid placeholder, the curly braces turn blue. If the keyword or modifier is unrecognized, the braces remain unstyled.

## Custom Date Formats

The default format of date/time placeholders follows your system preferences. You can create a custom format with `{date format="yyyy-MM-dd"}`.

| Placeholder | Output |
| --- | --- |
| `{date format="EEEE, MMM d, yyyy"}` | Wednesday, Jun 15, 2022 |
| `{date format="MM/dd/yyyy"}` | 06/15/2022 |
| `{date format="MM-dd-yyyy HH:mm"}` | 06-15-2022 13:44 |
| `{date format="MMM d, h:mm a"}` | Jun 15, 1:44 PM |
| `{date format="MMMM yyyy"}` | June 2022 |
| `{date format="MMM d, yyyy"}` | Jun 15, 2022 |
| `{date format="E, d MMM yyyy HH:mm:ss Z"}` | Wed, 15 Jun 2022 13:44:39 +0000 |
| `{date format="yyyy-MM-dd'T'HH:mm:ssZ"}` | 2022-06-15T13:44:39+0000 |
| `{date format="dd.MM.yy"}` | 15.06.22 |
| `{date format="HH:mm:ss.SSS"}` | 13:44:39.945 |

Notes:

- You can mix date modifiers with custom formats: `{date format="yyyy-MM-dd" offset="+3M -5d"}`.
- `format` can't be combined with [`locale`](#date-and-time-locale). Pick one or the other.
- All characters inside the format string are **case-sensitive**.
- Wrap literal text in single quotes to include it verbatim: `{date format="h:mm 'on the eve of' MMMM d"}` outputs **8:30 on the eve of June 5**.

### Reference for supported alphabets in custom date format

The following table contains the alphabets you can use in a custom date format and their output. Examples are based on June 15th, 2022 2:45 PM UTC.

> [!NOTE]
> All letters within the double quotes are case-sensitive.

| Alphabet | Output | Description |
| --- | --- | --- |
| **YEAR** | | |
| `y` | 2022 | Year, no padding |
| `yy` | 22 | Year, two digits (padding with a zero if necessary) |
| `yyyy` | 2022 | Year, minimum of four digits (padding with zeros if necessary) |
| **QUARTER** | | |
| `Q` | 2 | The quarter of the year. Use `QQ` if you want zero padding. |
| `QQQ` | Q2 | Quarter including "Q" |
| `QQQQ` | 2nd quarter | Quarter spelled out |
| **MONTH** | | |
| `M` | 6 | The numeric month of the year. A single `M` will use '6' for June. |
| `MM` | 06 | The numeric month of the year. A double `MM` will use '06' for June. |
| `MMM` | Jun | The shorthand name of the month |
| `MMMM` | June | Full name of the month |
| `MMMMM` | J | Narrow name of the month |
| **DAY** | | |
| `d` | 15 | The day of the month. A single `d` will use 1 for June 1st. |
| `dd` | 15 | The day of the month. A double `dd` will use 01 for June 1st. |
| `F` | 3 | The day of week in month (numeric). |
| `E` | Wed | The abbreviation for the day of the week |
| `EEEE` | Wednesday | The wide name of the day of the week |
| `EEEEE` | W | The narrow day of week |
| `EEEEEE` | We | The short day of week |
| **HOUR** | | |
| `h` | 2 | The 12-hour hour |
| `hh` | 02 | The 12-hour hour, padded with a zero if there is only 1 digit |
| `H` | 14 | The 24-hour hour |
| `HH` | 14 | The 24-hour hour, padded with a zero if there is only 1 digit |
| `a` | PM | AM / PM for 12-hour time formats |
| **MINUTE** | | |
| `m` | 45 | The minute, with no padding for zeroes |
| `mm` | 45 | The minute with zero padding |
| **SECOND** | | |
| `s` | 6 | The seconds, with no padding for zeroes |
| `ss` | 06 | The seconds with zero padding |
| `SSS` | 753 | The milliseconds |
| **TIME ZONE** | | |
| `zzz` | IST | The 3-letter name of the time zone. Falls back to GMT-08:00 if the name is not known. |
| `zzzz` | Indian Standard Time | The expanded time zone name. Falls back to GMT-08:00 if name is not known. |
| `ZZZZ` | IST+05:30 | Time zone with abbreviation and offset |
| `Z` | +0530 | RFC 822 GMT format. Can also match a literal Z for Zulu (UTC) time. |
| `ZZZZZ` | +05:30 | ISO 8601 time zone format |

You can read more about date format patterns in the [Unicode Date Format Patterns reference](https://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns).

## Date & Time Locale

By default, date and time placeholders follow your system's regional settings. To format the output for a specific region instead, add a `locale` parameter: `{date locale="fr-FR"}` renders today's date using French conventions.

`locale` works on `{date}`, `{datetime}`, `{time}`, and `{day}`, and combines with an offset:

- `{date locale="fr-FR"}` → 15 juin 2022
- `{date locale="fr-FR" offset="+1d"}` → tomorrow's date, formatted for French
- `{time locale="en-US-u-hc-h23"}` → 13:44. Unicode extensions are supported, so this forces 24-hour time

> [!NOTE]
> Write locales with hyphens, not underscores (`en-US`, not `en_US`), and use a locale your system supports. If the locale isn't recognized, the placeholder isn't valid and won't expand.

> [!WARNING]
> `format` and `locale` can't be used together. A custom format already fully specifies the output, so combining the two is rejected.

## Arguments

### Argument Name

By default, each `{argument}` placeholder creates a new input field in the search bar (up to 3). To reuse the same value across multiple placeholders, give them the same name: `{argument name="tone"}`. Placeholders with matching names are replaced by the same value.

### Argument Default Value

By default, an argument is required and the command cannot run until a value is entered. To make it optional, set a default value: `{argument default="happy"}` or `{argument name="sport" default="skiing"}`.

### Argument Options

To present a predefined set of choices, use the `options` parameter: `{argument name="tone" options="happy, sad, professional"}`.

## Clipboard Offset

By default, `{clipboard}` inserts your most recently copied text. To access older clipboard entries, use an offset:

- `{clipboard offset=1}` → second most recent
- `{clipboard offset=2}` → third most recent

> [!NOTE]
> Using a clipboard offset placeholder requires [Clipboard History](https://manual.raycast.com/clipboard-history) to be enabled.

## Browser Tab

### Browser Tab Format

By default, the tab content is converted to Markdown. You can specify a different format:

- `{browser-tab format="markdown"}` — default
- `{browser-tab format="text"}` — plain text content of the tab, without any styling
- `{browser-tab format="html"}` — full HTML content of the tab

### Browser Tab Selector

To extract a specific part of the page, use a CSS selector: `{browser-tab selector="a.author.text-bold"}`. This lets you create highly targeted commands for specific websites.


---

## Need Help?

Contact Raycast Support if you have any questions or would like help with Dynamic Placeholders. Use the **Send Feedback** command directly in Raycast to report bugs and billing issues, log feature requests, or any other queries you would like to speak to us about.

You can view all Raycast Support contact options at https://manual.raycast.com/contact-support
