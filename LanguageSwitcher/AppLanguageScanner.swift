import Foundation
import AppKit

struct AppLanguageScanner {
    static func scanLanguages(at appURL: URL) -> [String] {
        let resourcesURL = appURL.appendingPathComponent("Contents/Resources")

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: resourcesURL,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }

        let languages = contents
            .filter { $0.pathExtension == "lproj" && $0.deletingPathExtension().lastPathComponent != "Base" }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted { lhs, rhs in
                let lhsPriority = languagePriority(lhs)
                let rhsPriority = languagePriority(rhs)
                return lhsPriority == rhsPriority ? lhs < rhs : lhsPriority < rhsPriority
            }

        return languages
    }

    private static func languagePriority(_ language: String) -> Int {
        let code = language.replacingOccurrences(of: "_", with: "-").lowercased()
        let parts = code.split(separator: "-")
        let isTraditionalChinese = parts.first == "zh" && (
            parts.contains("hant") ||
            (!parts.contains("hans") && parts.contains { ["tw", "hk", "mo"].contains($0) })
        )
        if isTraditionalChinese || code == "traditional chinese" { return 0 }
        if parts.first == "en" || code == "english" { return 1 }
        let isSimplifiedChinese = parts.first == "zh" && (
            parts.contains("hans") || parts.count == 1 ||
            parts.contains { ["cn", "sg"].contains($0) }
        )
        if isSimplifiedChinese || code == "simplified chinese" { return 2 }
        return 3
    }

    static func launchApp(at appURL: URL, withLanguage language: String, completion: ((Bool) -> Void)? = nil) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [
            "-a",
            appURL.path,
            "--args",
            "-AppleLanguages",
            "(\(language))"
        ]

        process.terminationHandler = { finishedProcess in
            let succeeded = finishedProcess.terminationReason == .exit && finishedProcess.terminationStatus == 0
            DispatchQueue.main.async {
                completion?(succeeded)
                if succeeded {
                    NSApplication.shared.terminate(nil)
                }
            }
        }

        do {
            try process.run()
        } catch {
            print("启动失败: \(error.localizedDescription)")
            completion?(false)
        }
    }
}
