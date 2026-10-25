import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @Published var openedAppURL: URL?
    private var hasOpenedFile = false

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first, url.pathExtension.lowercased() == "app" else { return }

        hasOpenedFile = true
        showWindowAndLoadApp(url: url)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = self

        // 延迟检查，给 application:open: 时间执行
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }

            if !self.hasOpenedFile {
                // 如果没有通过拖入文件启动，显示窗口等待用户操作
                self.showWindow()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    private func showWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
            window.center()
        }
    }

    private func showWindowAndLoadApp(url: URL) {
        // Retain the URL so cold launches can load it before the view subscribes.
        openedAppURL = url
        showWindow()
    }

    @objc func handleDraggedLanguage(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        guard let data = pboard.data(forType: .string),
              let text = String(data: data, encoding: .utf8) else {
            return
        }

        let components = text.components(separatedBy: "||||")
        guard components.count == 2 else { return }

        let appPath = components[0]
        let language = components[1]
        let appURL = URL(fileURLWithPath: appPath)

        AppLanguageScanner.launchApp(at: appURL, withLanguage: language)
    }
}
