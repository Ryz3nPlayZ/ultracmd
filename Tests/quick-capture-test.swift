import Foundation

@main
struct QuickCaptureTest {
    static func main() {
        var failures = 0

        func check(_ description: String, _ condition: @autoclosure () -> Bool) {
            if condition() {
                print("PASS  \(description)")
            } else {
                print("FAIL  \(description)")
                failures += 1
            }
        }

        // MARK: - Durations

        check("plain minutes", QuickCaptureParser.parseDuration("25m") == 1500)
        check("hours and minutes", QuickCaptureParser.parseDuration("1h 30m") == 5400)
        check("seconds", QuickCaptureParser.parseDuration("90 seconds") == 90)
        check("case insensitive", QuickCaptureParser.parseDuration("2 Hours") == 7200)
        check("decimal minutes", QuickCaptureParser.parseDuration("1.5m") == 90)
        check("mins spelling", QuickCaptureParser.parseDuration("10mins") == 600)
        check("no duration in text", QuickCaptureParser.parseDuration("hello world") == nil)
        check("zero duration rejected", QuickCaptureParser.parseDuration("0m") == nil)
        check("bare number rejected", QuickCaptureParser.parseDuration("25") == nil)

        // MARK: - Dates and titles

        let plain = QuickCaptureParser.parseDateAndTitle("Remember the milk")
        check("no date leaves the title whole", plain.title == "Remember the milk")
        check("no date in a dateless line", plain.date == nil)

        let dated = QuickCaptureParser.parseDateAndTitle("Dinner tomorrow at 7pm")
        check("a dated line yields a date", dated.date != nil)
        // NSDataDetector reads "Dinner tomorrow at 7pm" as one event phrase, so the title
        // falls back to the whole line rather than losing it.
        check("a wholly-dated line keeps its text", dated.title == "Dinner tomorrow at 7pm")

        let reminder = QuickCaptureParser.parseDateAndTitle("Call mom tomorrow 5pm")
        check("a reminder line yields a date", reminder.date != nil)
        check("the reminder title keeps the doing", reminder.title == "Call mom")

        // NSDataDetector resolves "friday" against today, so the date must land within 8 days.
        if let friday = QuickCaptureParser.parseDateAndTitle("Standup friday 9am").date {
            let days = friday.timeIntervalSinceNow / 86_400
            check("friday lands within the coming week", days > -1 && days < 8)
        } else {
            check("friday line yields a date", false)
        }

        let onlyDate = QuickCaptureParser.parseDateAndTitle("tomorrow")
        check(
            "a line that is all date keeps its text as the title",
            onlyDate.title == "tomorrow")

        // MARK: - Maps destinations

        check(
            "a place query searches",
            MapsDestination.parse("coffee near me") == .search("coffee near me"))
        check(
            "directions to routes",
            MapsDestination.parse("directions to SFO") == .directions("SFO"))
        check(
            "the route spelling routes too",
            MapsDestination.parse("Route to Ferry Building") == .directions("Ferry Building"))
        check(
            "directions with no destination searches instead",
            MapsDestination.parse("directions to ") == .search("directions to"))

        let searchURL = MapsDestination.parse("coffee").url
        check(
            "a search builds a maps:// URL",
            searchURL?.scheme == "maps" && searchURL?.query?.contains("q=coffee") == true)
        let routeURL = MapsDestination.parse("directions to SFO").url
        check(
            "a route carries the destination and driving flag",
            routeURL?.query?.contains("daddr=SFO") == true
                && routeURL?.query?.contains("dirflg=d") == true)

        // MARK: - Web search engines

        check(
            "google builds its query URL",
            WebSearchEngine.google.url(for: "swift tips")?.absoluteString
                == "https://www.google.com/search?q=swift%20tips")
        check(
            "duckduckgo builds its query URL",
            WebSearchEngine.duckduckgo.url(for: "swift tips")?.absoluteString
                == "https://duckduckgo.com/?q=swift%20tips")
        check(
            "bing builds its query URL",
            WebSearchEngine.bing.url(for: "swift tips")?.absoluteString
                == "https://www.bing.com/search?q=swift%20tips")
        check(
            "an empty query still builds a URL",
            WebSearchEngine.google.url(for: "") != nil)

        print(failures == 0 ? "\nALL PASSED" : "\n\(failures) FAILED")
        exit(failures == 0 ? 0 : 1)
    }
}
