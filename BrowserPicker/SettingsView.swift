import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @State private var defaultBrowserID = ""
    @State private var rules: [DraftRule] = []
    @State private var browsers: [BrowserEntry] = []
    @State private var apps: [AppEntry] = []
    @State private var isDefault = true
    @State private var launchAtLogin = false
    @State private var hideIcon = false
    @State private var statusMessage = ""
    @State private var hasError = false
    @State private var loading = true

    var body: some View {
        VStack(spacing: 0) {
            notDefaultBanner
            mainContent
            Divider()
            footer
        }
        .background(WindowTitleSetter(title: "Browser Picker"))
        .frame(width: 560, height: 520)
        .onAppear(perform: bootstrap)
        .onChange(of: defaultBrowserID) { _, _ in autosave() }
        .onChange(of: rules) { _, _ in autosave() }
    }

    @ViewBuilder
    private var notDefaultBanner: some View {
        if !isDefault {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                Text("Browser Picker is not your default browser")
                    .font(.callout)
                Spacer()
                Button("Fix...") { SystemBrowser.openSystemSettings() }
                    .buttonStyle(.link)
                Button(action: refreshStatus) {
                    Image(systemName: "arrow.clockwise").font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.1))
        }
    }

    private var mainContent: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 12) {
                optionToggles
                Divider()
                defaultBrowserPicker
                Divider()
                rulesEditor
                Divider()
                configActions
                Divider()
                statusBar
                Spacer(minLength: 12)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }

    private var optionToggles: some View {
        HStack(spacing: 24) {
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .toggleStyle(.checkbox)
                .onChange(of: launchAtLogin) { _, val in setLaunchAtLogin(val) }

            Toggle("Hide Menu Bar Icon", isOn: $hideIcon)
                .toggleStyle(.checkbox)
                .onChange(of: hideIcon) { _, val in setHideIcon(val) }

            Spacer()
        }
    }

    private var defaultBrowserPicker: some View {
        SettingsSection(title: "DEFAULT BROWSER") {
            HStack(spacing: 12) {
                Picker("", selection: $defaultBrowserID) {
                    ForEach(browsers) { b in
                        HStack(spacing: 8) {
                            if let icon = b.icon { Image(nsImage: icon) }
                            Text(b.name)
                        }
                        .tag(b.id)
                    }
                }
                .labelsHidden()
                .fixedSize()

                Text("Used when no rule matches")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Spacer()
            }
        }
    }

    private var rulesEditor: some View {
        SettingsSection(title: "RULES", subtitle: "First match wins — drag to reorder") {
            if rules.isEmpty {
                HStack {
                    Text("No rules yet").foregroundStyle(.secondary).font(.callout)
                    Spacer()
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
                .overlay(RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 1))
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(rules.enumerated()), id: \.element.id) { i, _ in
                        RuleRowView(
                            rule: $rules[i],
                            apps: apps,
                            browsers: browsers,
                            canMoveUp: i > 0,
                            canMoveDown: i < rules.count - 1,
                            onMoveUp: { swap(i, by: -1) },
                            onMoveDown: { swap(i, by: 1) },
                            onDelete: { rules.remove(at: i) }
                        )
                    }
                }
            }

            Button {
                rules.append(DraftRule(browserID: defaultBrowserID))
            } label: {
                Label("Add Rule", systemImage: "plus.circle.fill").font(.callout)
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)
            .padding(.top, 4)
        }
    }

    private var configActions: some View {
        SettingsSection(title: "CONFIG") {
            HStack(spacing: 12) {
                Button {
                    NSWorkspace.shared.open(ConfigStore.shared.directoryURL)
                } label: {
                    Label("Open Config Folder", systemImage: "folder")
                }

                Spacer()

                if !statusMessage.isEmpty {
                    HStack(spacing: 4) {
                        if statusMessage == "Saved" {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                        }
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundColor(hasError ? .red : (statusMessage == "Saved" ? .green : .secondary))
                            .lineLimit(1)
                    }
                }

                Button("Reload", action: reloadFromDisk)
            }
        }
    }

    private var statusBar: some View {
        SettingsSection(title: "STATUS") {
            HStack(spacing: 8) {
                if isDefault {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    Text("Browser Picker is your default browser")
                        .font(.callout).foregroundStyle(.secondary)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                    Text("Not set as default browser")
                        .font(.callout).foregroundStyle(.secondary)
                    Spacer()
                    Button("Open Settings...") { SystemBrowser.openSystemSettings() }
                    Button(action: refreshStatus) {
                        Image(systemName: "arrow.clockwise").font(.system(size: 11))
                    }
                    .buttonStyle(.plain).foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Quit Browser Picker") { NSApp.terminate(nil) }
                .controlSize(.large)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    private func bootstrap() {
        browsers = BrowserScanner.all()
        apps = AppScanner.all()
        reloadFromDisk()
        refreshStatus()
        launchAtLogin = SMAppService.mainApp.status == .enabled
        hideIcon = UserDefaults.standard.bool(forKey: "hideMenuBarIcon")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { loading = false }
    }

    private func reloadFromDisk() {
        let config = ConfigStore.shared.loadOrDefault()
        defaultBrowserID = config.defaultBrowserID
        rules = config.rules.map { rule in
            DraftRule(
                appName: rule.app?.name,
                urlPattern: rule.url?.pattern ?? rule.url?.contains,
                browserID: rule.browserID,
                incognito: rule.incognito,
                newWindow: rule.newWindow
            )
        }
        statusMessage = ""
        hasError = false
    }

    private func autosave() {
        guard !loading else { return }
        saveConfig()
    }

    private func saveConfig() {
        for (i, rule) in rules.enumerated() {
            if rule.appName == nil && (rule.urlPattern ?? "").isEmpty {
                statusMessage = "Rule \(i + 1): needs an app or domain"
                hasError = true
                return
            }
            if rule.browserID.isEmpty {
                statusMessage = "Rule \(i + 1): no browser selected"
                hasError = true
                return
            }
        }

        for i in 0..<rules.count {
            for j in (i + 1)..<rules.count {
                if rules[i].appName == rules[j].appName &&
                   rules[i].urlPattern == rules[j].urlPattern &&
                   rules[i].browserID == rules[j].browserID {
                    statusMessage = "Rules \(i + 1) & \(j + 1) are identical"
                    hasError = true
                    return
                }
            }
        }

        let routingRules: [RoutingRule] = rules.enumerated().map { i, draft in
            RoutingRule(
                id: "rule-\(i + 1)",
                priority: rules.count - i,
                app: draft.appName.map { AppMatcher(name: $0) },
                url: (draft.urlPattern?.isEmpty == false) ? URLMatcher(pattern: draft.urlPattern) : nil,
                browserID: draft.browserID,
                incognito: draft.incognito,
                newWindow: draft.newWindow
            )
        }

        let config = PickerConfig(defaultBrowserID: defaultBrowserID, rules: routingRules)

        do {
            try ConfigStore.shared.save(config)
            statusMessage = "Saved"
            hasError = false
            NotificationCenter.default.post(name: .configDidChange, object: nil)
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
            hasError = true
        }
    }

    private func swap(_ index: Int, by offset: Int) {
        let target = index + offset
        guard target >= 0 && target < rules.count else { return }
        rules.swapAt(index, target)
    }

    private func refreshStatus() { isDefault = SystemBrowser.isDefault }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func setHideIcon(_ hidden: Bool) {
        UserDefaults.standard.set(hidden, forKey: "hideMenuBarIcon")
        NotificationCenter.default.post(name: .menuBarVisibilityChanged, object: nil)
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption).fontWeight(.medium)
                    .foregroundStyle(.secondary).textCase(.uppercase)
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.tertiary)
                }
            }
            content()
        }
    }
}

private struct WindowTitleSetter: NSViewRepresentable {
    let title: String

    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async {
            guard let w = v.window else { return }
            w.title = title
            w.titleVisibility = .visible
            w.titlebarAppearsTransparent = false
            w.styleMask.insert(.titled)
            w.toolbar = nil
        }
        return v
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
