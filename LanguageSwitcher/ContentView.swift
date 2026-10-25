import SwiftUI
import UniformTypeIdentifiers

private enum SwitcherStyle {
    static let mint = Color(red: 0.08, green: 0.49, blue: 0.39)
    static let mintLight = Color(red: 0.59, green: 0.94, blue: 0.81)
    static let ink = Color(red: 0.13, green: 0.16, blue: 0.23)
    static let violet = Color(red: 0.49, green: 0.39, blue: 0.80)
    static let muted = Color(red: 0.39, green: 0.43, blue: 0.51)
}

struct ContentView: View {
    @EnvironmentObject private var appDelegate: AppDelegate
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appURL: URL?
    @State private var appName = ""
    @State private var appIcon: NSImage?
    @State private var languages: [String] = []
    @State private var searchText = ""
    @State private var isDropTargeted = false
    @State private var isLaunching = false
    @State private var errorMessage: String?

    private var filteredLanguages: [String] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return languages.filter { code in
            query.isEmpty || [code, languageName(code), nativeName(code)]
                .contains { $0.localizedStandardContains(query) }
        }
    }

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                topBar
                if appURL == nil {
                    emptyState.transition(.opacity.combined(with: .offset(y: 10)))
                } else {
                    appState.transition(.opacity.combined(with: .offset(y: 10)))
                }
                footer
            }
            .padding(.horizontal, 30)
            .padding(.top, 22)
            .padding(.bottom, 20)
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 16)
                    .fill(SwitcherStyle.mint.opacity(0.06))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(SwitcherStyle.mint.opacity(0.8), lineWidth: 2)
                            .padding(6)
                    }
                    .allowsHitTesting(false)
            }
        }
        .frame(width: 740, height: 680)
        .preferredColorScheme(.light)
        .foregroundStyle(SwitcherStyle.ink)
        .tint(SwitcherStyle.mint)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: appURL)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: isDropTargeted)
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            loadApp(url)
            return true
        } isTargeted: { isDropTargeted = $0 }
        .onReceive(appDelegate.$openedAppURL) { url in
            if let url { loadApp(url) }
        }
        .alert("无法完成操作", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("知道了", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var background: some View {
        ZStack {
            Color(red: 0.97, green: 0.975, blue: 0.99)
            Ellipse()
                .fill(SwitcherStyle.violet.opacity(0.11))
                .frame(width: 520, height: 350).blur(radius: 90)
                .offset(x: -260, y: -260)
            Ellipse()
                .fill(SwitcherStyle.mintLight.opacity(0.24))
                .frame(width: 380, height: 340).blur(radius: 90)
                .offset(x: 300, y: 70)
            LinearGradient(colors: [.white.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 42, height: 42)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("Language Switcher").font(.system(size: 14, weight: .semibold))
                Text("让应用，说你的语言")
                    .font(.system(size: 10)).foregroundStyle(SwitcherStyle.muted)
            }
            Spacer()
            HStack(spacing: 6) {
                Circle().fill(SwitcherStyle.mint).frame(width: 5, height: 5)
                Text("为单个应用选择语言").font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(SwitcherStyle.muted)
        }
        .padding(.bottom, 24)
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            orbitalGlobe.frame(height: 142).padding(.top, 4)
            Text("换种语言，打开新视界。")
                .font(.system(size: 30, weight: .bold)).tracking(-0.8)
                .foregroundStyle(LinearGradient(colors: [SwitcherStyle.ink, Color(red: 0.35, green: 0.32, blue: 0.49)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(.top, 8)
            Text("无需更改系统语言，为喜欢的应用选择另一种表达。")
                .font(.system(size: 12)).foregroundStyle(SwitcherStyle.muted)
                .padding(.top, 10)
            VStack(spacing: 13) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down").foregroundStyle(SwitcherStyle.mint)
                    Text(isDropTargeted ? "松开，即刻探索应用语言" : "将 .app 应用拖到这里")
                        .foregroundStyle(SwitcherStyle.ink.opacity(0.9))
                }
                .font(.system(size: 13, weight: .medium))
                Button(action: chooseApp) {
                    HStack(spacing: 9) {
                        Image(systemName: "plus")
                        Text("选择应用")
                        Text("⌘O").font(.system(size: 10, weight: .medium)).opacity(0.8)
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(red: 0.035, green: 0.12, blue: 0.11))
                    .padding(.horizontal, 20).frame(height: 36)
                    .background(SwitcherStyle.mintLight.gradient, in: RoundedRectangle(cornerRadius: 10))
                    .shadow(color: SwitcherStyle.mint.opacity(0.14), radius: 14, y: 4)
                }
                .buttonStyle(.plain).keyboardShortcut("o")
            }
            .frame(maxWidth: .infinity).padding(.vertical, 23)
            .background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(SwitcherStyle.mint.opacity(isDropTargeted ? 0.8 : 0.21), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
            .padding(.top, 27)
            HStack(spacing: 0) {
                step("01", title: "选择应用", detail: "拖入或从本机选择")
                step("02", title: "找到语言", detail: "自动识别可用语言")
                step("03", title: "点击启动", detail: "用所选语言打开")
            }
            .padding(.top, 26)
            Spacer(minLength: 20)
        }
    }

    private var orbitalGlobe: some View {
        ZStack {
            Circle().fill(SwitcherStyle.mint.opacity(0.12))
                .frame(width: 110, height: 110).blur(radius: 28)
            Ellipse().strokeBorder(SwitcherStyle.violet.opacity(0.24), lineWidth: 1)
                .frame(width: 228, height: 79).rotationEffect(.degrees(-24))
            Ellipse().strokeBorder(SwitcherStyle.mint.opacity(0.2), lineWidth: 1)
                .frame(width: 204, height: 96).rotationEffect(.degrees(28))
            Circle()
                .fill(LinearGradient(colors: [Color(red: 0.94, green: 1, blue: 0.98), Color(red: 0.88, green: 0.88, blue: 1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 108, height: 108)
                .overlay { Circle().strokeBorder(.white.opacity(0.95), lineWidth: 1) }
                .shadow(color: SwitcherStyle.mint.opacity(0.13), radius: 24)
            Image(systemName: "globe.asia.australia")
                .font(.system(size: 68, weight: .ultraLight))
                .foregroundStyle(LinearGradient(colors: [SwitcherStyle.mint, Color(red: 0.36, green: 0.56, blue: 0.66), SwitcherStyle.violet], startPoint: .topLeading, endPoint: .bottomTrailing))
            orbitLabel("你好", color: SwitcherStyle.mint).offset(x: -108, y: -30)
            orbitLabel("Hello", color: SwitcherStyle.violet).offset(x: 103, y: 28)
            Circle().fill(SwitcherStyle.mint).frame(width: 5, height: 5)
                .shadow(color: SwitcherStyle.mint, radius: 6).offset(x: 87, y: -48)
            Circle().fill(SwitcherStyle.violet).frame(width: 4, height: 4).offset(x: -78, y: 52)
        }
        .scaleEffect(isDropTargeted && !reduceMotion ? 1.05 : 1)
        .accessibilityHidden(true)
    }

    private func orbitLabel(_ title: String, color: Color) -> some View {
        Text(title).font(.system(size: 11, weight: .medium)).foregroundStyle(color)
            .padding(.horizontal, 11).padding(.vertical, 7)
            .background(Color.white.opacity(0.95), in: Capsule())
            .overlay { Capsule().strokeBorder(color.opacity(0.24), lineWidth: 1) }
    }

    private func step(_ number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number).font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(SwitcherStyle.mint).padding(.top, 2)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.system(size: 11, weight: .medium)).foregroundStyle(SwitcherStyle.ink.opacity(0.85))
                Text(detail).font(.system(size: 10)).foregroundStyle(SwitcherStyle.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var appState: some View {
        VStack(spacing: 20) {
            HStack(spacing: 15) {
                if let appIcon {
                    Image(nsImage: appIcon).resizable().interpolation(.high)
                        .frame(width: 64, height: 64)
                        .shadow(color: SwitcherStyle.ink.opacity(0.12), radius: 12, y: 5)
                }
                VStack(alignment: .leading, spacing: 7) {
                    Text(appName).font(.system(size: 23, weight: .semibold))
                        .lineLimit(1).truncationMode(.middle).help(appName)
                    Label("已发现 \(languages.count) 种可用语言", systemImage: "globe")
                        .font(.system(size: 11)).foregroundStyle(SwitcherStyle.muted)
                }
                Spacer(minLength: 8)
                Button(action: chooseApp) {
                    Label("更换应用", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 12).padding(.vertical, 9)
                        .background(SwitcherStyle.ink.opacity(0.035), in: Capsule())
                        .overlay { Capsule().strokeBorder(SwitcherStyle.ink.opacity(0.07), lineWidth: 1) }
                }
                .buttonStyle(.plain).keyboardShortcut("o")
            }
            .padding(20)
            .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: SwitcherStyle.ink.opacity(0.035), radius: 18, y: 6)
            .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.95), lineWidth: 1) }
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("选择启动语言").font(.system(size: 16, weight: .semibold))
                    Text("点击卡片，以所选语言打开应用")
                        .font(.system(size: 10)).foregroundStyle(SwitcherStyle.muted)
                }
                Spacer()
                HStack(spacing: 7) {
                    Image(systemName: "magnifyingglass").foregroundStyle(SwitcherStyle.muted)
                    TextField("搜索语言…", text: $searchText)
                        .textFieldStyle(.plain).accessibilityLabel("搜索语言")
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(SwitcherStyle.muted)
                        }
                        .buttonStyle(.plain).accessibilityLabel("清除搜索")
                    }
                }
                .font(.system(size: 12)).padding(10).frame(width: 215)
                .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 10))
                .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(SwitcherStyle.ink.opacity(0.08), lineWidth: 1) }
            }
            if languages.isEmpty {
                messageState(icon: "globe", title: "这个应用没有可识别的语言", detail: "未找到独立语言资源，试试选择其他应用。")
            } else if filteredLanguages.isEmpty {
                messageState(icon: "magnifyingglass", title: "没有匹配的语言", detail: "试试语言名称或代码，例如「中文」或「en」。")
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(filteredLanguages, id: \.self) { code in
                            LanguageCard(code: code, name: languageName(code), nativeName: nativeName(code), isLaunching: isLaunching) {
                                launchApp(code)
                            }
                        }
                    }
                    .padding(3).padding(.bottom, 8)
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(.top, 8).padding(.bottom, 16)
    }

    private func messageState(icon: String, title: String, detail: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 28, weight: .light)).foregroundStyle(SwitcherStyle.violet)
            Text(title).font(.system(size: 15, weight: .medium))
            Text(detail).font(.system(size: 12)).foregroundStyle(SwitcherStyle.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        VStack(spacing: 14) {
            Rectangle().fill(SwitcherStyle.ink.opacity(0.08)).frame(height: 1)
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                Text("仅为本次启动传入语言偏好")
                Spacer()
                if isLaunching {
                    ProgressView().controlSize(.mini)
                    Text("正在启动应用…")
                } else {
                    Text("运行中的应用请先退出")
                }
            }
            .font(.system(size: 10)).foregroundStyle(SwitcherStyle.muted)
        }
    }

    private func languageName(_ code: String) -> String {
        Locale(identifier: "zh-Hans").localizedString(forIdentifier: code) ?? code
    }

    private func nativeName(_ code: String) -> String {
        Locale(identifier: code).localizedString(forIdentifier: code) ?? code
    }

    private func chooseApp() {
        let panel = NSOpenPanel()
        panel.title = "选择要切换语言的应用"
        panel.prompt = "选择应用"
        panel.allowedContentTypes = [.applicationBundle]
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.begin { response in
            if response == .OK, let url = panel.url { loadApp(url) }
        }
    }

    private func loadApp(_ url: URL) {
        let resolvedURL = url.resolvingSymlinksInPath()
        var isDirectory: ObjCBool = false
        guard resolvedURL.pathExtension.lowercased() == "app",
              FileManager.default.fileExists(atPath: resolvedURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue,
              Bundle(url: resolvedURL)?.executableURL != nil else {
            errorMessage = "请选择有效的 macOS .app 应用程序。"
            return
        }
        appURL = resolvedURL
        appName = resolvedURL.deletingPathExtension().lastPathComponent
        appIcon = NSWorkspace.shared.icon(forFile: resolvedURL.path)
        languages = AppLanguageScanner.scanLanguages(at: resolvedURL)
        searchText = ""
        isLaunching = false
    }

    private func launchApp(_ language: String) {
        guard let appURL, !isLaunching else { return }
        isLaunching = true
        AppLanguageScanner.launchApp(at: appURL, withLanguage: language) { succeeded in
            if !succeeded {
                isLaunching = false
                errorMessage = "应用未能启动，请检查应用是否仍在原来的位置。"
            }
        }
    }
}

private struct LanguageCard: View {
    let code: String
    let name: String
    let nativeName: String
    let isLaunching: Bool
    let action: () -> Void
    @State private var isHovered = false
    @FocusState private var isFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var isHighlighted: Bool { isHovered || isFocused }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(String(code.prefix(2)).uppercased())
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isHighlighted ? SwitcherStyle.mint : SwitcherStyle.violet)
                    .frame(width: 42, height: 42)
                    .background((isHighlighted ? SwitcherStyle.mint : SwitcherStyle.violet).opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 5) {
                    Text(name).font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SwitcherStyle.ink).lineLimit(1)
                    Text("\(nativeName) · \(code)").font(.system(size: 10))
                        .foregroundStyle(SwitcherStyle.muted).lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isHighlighted ? SwitcherStyle.mint : SwitcherStyle.muted.opacity(0.6))
                    .offset(x: isHighlighted && !reduceMotion ? 1 : 0, y: isHighlighted && !reduceMotion ? -1 : 0)
            }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(isHighlighted ? SwitcherStyle.mintLight.opacity(0.22) : .white.opacity(0.8), in: RoundedRectangle(cornerRadius: 15))
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(isHighlighted ? SwitcherStyle.mint.opacity(0.4) : SwitcherStyle.ink.opacity(0.07), lineWidth: 1)
            }
            .shadow(color: (isHighlighted ? SwitcherStyle.mint : SwitcherStyle.ink).opacity(isHighlighted ? 0.09 : 0.025), radius: 10, y: 3)
            .contentShape(RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(.plain).focused($isFocused).disabled(isLaunching)
        .onHover { isHovered = $0 }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isHighlighted)
        .accessibilityLabel("以\(name)启动应用，\(code)")
        .help("以\(name)启动应用（\(nativeName)，\(code)）")
    }
}
