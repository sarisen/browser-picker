import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @State private var tab: Tab = .rules

    enum Tab: String, CaseIterable {
        case rules   = "Rules"
        case general = "General"
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ZStack {
                RulesTab()
                    .opacity(tab == .rules   ? 1 : 0)
                GeneralTab()
                    .opacity(tab == .general ? 1 : 0)
            }
        }
        .background(WindowTitleSetter(title: "Browser Picker"))
        .frame(width: 560, height: 480)
    }

    private var header: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { t in
                Button(action: { withAnimation(.easeInOut(duration: 0.15)) { tab = t } }) {
                    Text(t.rawValue)
                        .font(.system(size: 13, weight: tab == t ? .semibold : .regular))
                        .foregroundColor(tab == t ? .primary : .secondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .background(
                    VStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(tab == t ? .accentColor : .clear)
                    }
                )
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Rules Tab

private struct RulesTab: View {
    @State private var defaultBrowserID = ""
    @State private var rules: [DraftRule] = []
    @State private var browsers: [BrowserEntry] = []
    @State private var apps: [AppEntry] = []
    @State private var statusMessage = ""
    @State private var hasError = false
    @State private var loading = true

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 16) {
                    defaultBrowserRow
                    Divider()
                    rulesSection
                }
                .padding(24)
            }
            Divider()
            bottomBar
        }
        .onAppear {
            browsers = BrowserScanner.all()
            apps = AppScanner.all()
            reloadFromDisk()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { loading = false }
        }
        .onChange(of: defaultBrowserID) { _, _ in autosave() }
        .onChange(of: rules)           { _, _ in autosave() }
    }

    private var defaultBrowserRow: some View {
        HStack(spacing: 12) {
            Label("Default Browser", systemImage: "globe")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)

            Spacer()

            Picker("", selection: $defaultBrowserID) {
                ForEach(browsers) { b in
                    HStack(spacing: 6) {
                        if let icon = b.icon { Image(nsImage: icon) }
                        Text(b.name)
                    }
                    .tag(b.id)
                }
            }
            .labelsHidden()
            .fixedSize()

            Text("when no rule matches")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ROUTING RULES")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                Text("· first match wins")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
            }

            if rules.isEmpty {
                emptyState
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(rules.enumerated()), id: \.element.id) { i, _ in
                        RuleCard(
                            rule: $rules[i],
                            index: i,
                            total: rules.count,
                            apps: apps,
                            browsers: browsers,
                            onMoveUp:   { swap(i, by: -1) },
                            onMoveDown: { swap(i, by:  1) },
                            onDelete:   { rules.remove(at: i) }
                        )
                    }
                }
            }

            Button {
                rules.append(DraftRule(browserID: defaultBrowserID))
            } label: {
                Label("Add Rule", systemImage: "plus.circle.fill")
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)
            .padding(.top, 2)
        }
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 28))
                    .foregroundStyle(.tertiary)
                Text("No rules yet")
                    .font(.callout).foregroundStyle(.secondary)
                Text("All links open in your default browser")
                    .font(.caption).foregroundStyle(.tertiary)
            }
            .padding(.vertical, 28)
            Spacer()
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5),
                    in: RoundedRectangle(cornerRadius: 10))
    }

    private var bottomBar: some View {
        HStack {
            Button {
                NSWorkspace.shared.open(ConfigStore.shared.directoryURL)
            } label: {
                Label("Config Folder", systemImage: "folder")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer()

            if !statusMessage.isEmpty {
                HStack(spacing: 4) {
                    if !hasError {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 11))
                    }
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(hasError ? .red : .green)
                }
            }

            Button("Reload", action: reloadFromDisk)
                .font(.system(size: 12))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
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
        for (i, rule) in rules.enumerated() {
            if rule.appName == nil && (rule.urlPattern ?? "").isEmpty {
                statusMessage = "Rule \(i + 1): needs app or domain"
                hasError = true; return
            }
            if rule.browserID.isEmpty {
                statusMessage = "Rule \(i + 1): no browser"
                hasError = true; return
            }
        }
        let routingRules: [RoutingRule] = rules.enumerated().map { i, d in
            RoutingRule(
                id: "rule-\(i + 1)",
                priority: rules.count - i,
                app: d.appName.map { AppMatcher(name: $0) },
                url: (d.urlPattern?.isEmpty == false) ? URLMatcher(pattern: d.urlPattern) : nil,
                browserID: d.browserID,
                incognito: d.incognito,
                newWindow: d.newWindow
            )
        }
        let config = PickerConfig(defaultBrowserID: defaultBrowserID, rules: routingRules)
        do {
            try ConfigStore.shared.save(config)
            statusMessage = "Saved"
            hasError = false
            NotificationCenter.default.post(name: .configDidChange, object: nil)
        } catch {
            statusMessage = error.localizedDescription
            hasError = true
        }
    }

    private func swap(_ index: Int, by offset: Int) {
        let t = index + offset
        guard t >= 0 && t < rules.count else { return }
        rules.swapAt(index, t)
    }
}

// MARK: - Rule Card (replaces RuleRowView in Settings)

private struct RuleCard: View {
    @Binding var rule: DraftRule
    let index: Int
    let total: Int
    let apps: [AppEntry]
    let browsers: [BrowserEntry]
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Priority badge
            Text("\(index + 1)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 18)

            // App picker
            Picker("", selection: Binding(
                get: { rule.appName ?? "__any__" },
                set: { rule.appName = $0 == "__any__" ? nil : $0 }
            )) {
                Text("Any app").tag("__any__")
                Divider()
                ForEach(apps) { app in
                    HStack(spacing: 6) {
                        if let icon = app.icon { Image(nsImage: icon) }
                        Text(app.name)
                    }.tag(app.name)
                }
            }
            .labelsHidden()
            .frame(width: 108)

            TextField("*.example.com", text: Binding(
                get: { rule.urlPattern ?? "" },
                set: { rule.urlPattern = $0.isEmpty ? nil : $0 }
            ))
            .textFieldStyle(.roundedBorder)
            .frame(width: 108)

            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.tertiary)

            Picker("", selection: $rule.browserID) {
                ForEach(browsers) { b in
                    HStack(spacing: 6) {
                        if let icon = b.icon { Image(nsImage: icon) }
                        Text(b.name)
                    }.tag(b.id)
                }
            }
            .labelsHidden()
            .frame(width: 108)

            Spacer(minLength: 0)

            // Option toggles
            HStack(spacing: 2) {
                Toggle(isOn: $rule.incognito) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 11))
                }
                .toggleStyle(.button)
                .tint(rule.incognito ? .purple : .secondary.opacity(0.3))
                .help("Incognito mode")
                .controlSize(.mini)

                Toggle(isOn: $rule.newWindow) {
                    Image(systemName: "macwindow.badge.plus")
                        .font(.system(size: 11))
                }
                .toggleStyle(.button)
                .tint(rule.newWindow ? .blue : .secondary.opacity(0.3))
                .help("New window")
                .controlSize(.mini)
            }

            // Reorder
            VStack(spacing: 0) {
                Button(action: onMoveUp) {
                    Image(systemName: "chevron.up").font(.system(size: 8, weight: .bold))
                }
                .buttonStyle(.plain)
                .disabled(index == 0)
                .foregroundStyle(index == 0 ? .quaternary : .secondary)

                Button(action: onMoveDown) {
                    Image(systemName: "chevron.down").font(.system(size: 8, weight: .bold))
                }
                .buttonStyle(.plain)
                .disabled(index == total - 1)
                .foregroundStyle(index == total - 1 ? .quaternary : .secondary)
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(nsColor: .separatorColor).opacity(0.6), lineWidth: 0.5))
    }
}

// MARK: - General Tab

private struct GeneralTab: View {
    @State private var isDefault = false
    @State private var launchAtLogin = false
    @State private var hideIcon = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                statusCard
                preferencesCard
                configCard
                Spacer(minLength: 0)
            }
            .padding(24)
        }
        .onAppear {
            isDefault = SystemBrowser.isDefault
            launchAtLogin = SMAppService.mainApp.status == .enabled
            hideIcon = UserDefaults.standard.bool(forKey: "hideMenuBarIcon")
        }
    }

    private var statusCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isDefault ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: isDefault ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(isDefault ? .green : .orange)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(isDefault ? "Active as default browser" : "Not set as default browser")
                    .font(.system(size: 13, weight: .medium))
                Text(isDefault
                     ? "All links will be routed through Browser Picker"
                     : "Set Browser Picker as default to start routing links")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !isDefault {
                Button("Set Default") { SystemBrowser.openSystemSettings() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            } else {
                Button(action: { isDefault = SystemBrowser.isDefault }) {
                    Image(systemName: "arrow.clockwise").font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(isDefault ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1))
    }

    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("PREFERENCES")
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(.secondary).tracking(0.5)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                preferenceRow(
                    icon: "arrow.up.right.circle",
                    label: "Launch at Login",
                    detail: "Start Browser Picker automatically",
                    isOn: $launchAtLogin,
                    onChange: setLaunchAtLogin
                )
                Divider().padding(.leading, 44)
                preferenceRow(
                    icon: "menubar.arrow.up.rectangle",
                    label: "Hide Menu Bar Icon",
                    detail: "Reopen the app to show it again",
                    isOn: $hideIcon,
                    onChange: setHideIcon
                )
            }
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(Color(nsColor: .separatorColor).opacity(0.6), lineWidth: 0.5))
        }
    }

    private func preferenceRow(icon: String, label: String, detail: String,
                                isOn: Binding<Bool>, onChange: @escaping (Bool) -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.system(size: 13))
                Text(detail).font(.caption).foregroundStyle(.tertiary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .onChange(of: isOn.wrappedValue) { _, v in onChange(v) }
                .labelsHidden()
                .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var configCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("DATA")
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(.secondary).tracking(0.5)
                .padding(.bottom, 10)

            HStack(spacing: 12) {
                Image(systemName: "doc.text")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Config File").font(.system(size: 13))
                    Text(ConfigStore.shared.configURL.path)
                        .font(.caption).foregroundStyle(.tertiary)
                        .lineLimit(1).truncationMode(.middle)
                }

                Spacer()

                Button("Reveal") {
                    NSWorkspace.shared.open(ConfigStore.shared.directoryURL)
                }
                .controlSize(.small)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(Color(nsColor: .separatorColor).opacity(0.6), lineWidth: 0.5))
        }
    }

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

// MARK: - Helpers

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
