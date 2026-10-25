import Foundation

@main
struct AppLanguageScannerTests {
    static func main() throws {
        let fixture = FileManager.default.temporaryDirectory
            .appendingPathComponent("LanguageSwitcher-tests-\(UUID().uuidString).app")
        defer { try? FileManager.default.removeItem(at: fixture) }

        let traditional = ["zh-Hant", "zh-Hant-HK", "zh_HK", "zh_TW", "Traditional Chinese"]
        let english = ["en", "en-GB", "en_US", "English"]
        let simplified = ["zh", "zh-CN", "zh-Hans", "zh-Hans-TW", "zh_SG", "Simplified Chinese"]
        let other = ["de", "fr", "ja"]
        let resources = fixture.appendingPathComponent("Contents/Resources")
        for language in other + simplified + english + traditional + ["Base"] {
            try FileManager.default.createDirectory(
                at: resources.appendingPathComponent("\(language).lproj"),
                withIntermediateDirectories: true
            )
        }
        try Data().write(to: resources.appendingPathComponent("README.txt"))

        let expected = traditional.sorted() + english.sorted() + simplified.sorted() + other.sorted()
        precondition(AppLanguageScanner.scanLanguages(at: fixture) == expected,
                     "Expected traditional Chinese, English, simplified Chinese, then other languages; Base and unrelated files must be excluded")
        print("PASS: preferred language order, region variants, and Base filtering")

        try FileManager.default.removeItem(at: fixture)
        precondition(AppLanguageScanner.scanLanguages(at: fixture).isEmpty,
                     "Missing resources must return an empty list")
        print("PASS: missing resources")

        // /usr/bin/open starts successfully but exits nonzero for this missing app.
        AppLanguageScanner.launchApp(at: fixture, withLanguage: "en") { succeeded in
            precondition(Thread.isMainThread, "UI completion must run on the main thread")
            precondition(!succeeded, "A failed open must report failure")
            print("PASS: failed launch reports failure without terminating the tool")
            exit(0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            fputs("FAIL: launch completion timed out\n", stderr)
            exit(1)
        }
        RunLoop.main.run()
    }
}
