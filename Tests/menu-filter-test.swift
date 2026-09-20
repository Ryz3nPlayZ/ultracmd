// Menu type-to-filter harness: the pure predicate the open menu's rows narrow by.
import Foundation

@main
@MainActor
struct MenuFilterTest {
    static func main() {
        var failures = 0

        func check(_ name: String, _ condition: Bool) {
            if condition {
                print("ok       \(name)")
            } else {
                failures += 1
                print("FAIL     \(name)")
            }
        }

        let titles = [
            "Open Application", "Quit Application", "Copy", "Paste to Safari",
            "Reveal in Finder", "Move to Trash"
        ]

        // An empty query is the whole menu.
        check(
            "empty query keeps every row",
            MenuFilter.indexes(ofTitles: titles, query: "") == Array(titles.indices))

        // The user's own example: ⌘K then "quit" finds Quit Application.
        check(
            "quit finds the quit row",
            MenuFilter.indexes(ofTitles: titles, query: "quit") == [1])

        // Prefixes, substrings and subsequence fuzz all narrow.
        check(
            "prefix matches",
            MenuFilter.indexes(ofTitles: titles, query: "pas") == [3])
        check(
            "case folds",
            MenuFilter.indexes(ofTitles: titles, query: "COPY") == [2])
        check(
            "substring inside a word",
            MenuFilter.indexes(ofTitles: titles, query: "cation") == [0, 1])
        check(
            "a subsequence hit keeps its row",
            MenuFilter.keeps("Reveal in Finder", query: "rvl"))

        // A miss is a miss, not a nearest guess.
        check(
            "unmatched query keeps nothing",
            MenuFilter.indexes(ofTitles: titles, query: "zzz").isEmpty)

        // Diacritics and width fold the way the launcher folds.
        check("diacritic folds", MenuFilter.keeps("Révéler", query: "reveler"))
        check("width folds", MenuFilter.keeps("Ｃopy", query: "copy"))

        if failures == 0 {
            print("menu-filter-test: all passed")
        } else {
            print("menu-filter-test: \(failures) FAILED")
            exit(1)
        }
    }
}
