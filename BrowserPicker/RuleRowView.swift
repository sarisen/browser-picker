import SwiftUI

struct DraftRule: Identifiable, Equatable {
    let id = UUID()
    var appName: String?
    var urlPattern: String?
    var browserID: String
    var incognito: Bool = false
    var newWindow: Bool = false

    static func == (lhs: DraftRule, rhs: DraftRule) -> Bool {
        lhs.id == rhs.id &&
        lhs.appName == rhs.appName &&
        lhs.urlPattern == rhs.urlPattern &&
        lhs.browserID == rhs.browserID &&
        lhs.incognito == rhs.incognito &&
        lhs.newWindow == rhs.newWindow
    }
}

struct RuleRowView: View {
    @Binding var rule: DraftRule
    let apps: [AppEntry]
    let browsers: [BrowserEntry]
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            reorderControls
            appPicker
            patternField
            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary.opacity(0.4))
            browserPicker
            toggleButtons
            Spacer()
            deleteControl
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }

    private var reorderControls: some View {
        VStack(spacing: 2) {
            Button(action: onMoveUp) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 9, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundColor(canMoveUp ? .secondary : .secondary.opacity(0.3))
            .disabled(!canMoveUp)

            Button(action: onMoveDown) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundColor(canMoveDown ? .secondary : .secondary.opacity(0.3))
            .disabled(!canMoveDown)
        }
    }

    private var appPicker: some View {
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
                }
                .tag(app.name)
            }
        }
        .labelsHidden()
        .frame(width: 110)
    }

    private var patternField: some View {
        TextField("*.example.com", text: Binding(
            get: { rule.urlPattern ?? "" },
            set: { rule.urlPattern = $0.isEmpty ? nil : $0 }
        ))
        .textFieldStyle(.roundedBorder)
        .frame(width: 110)
    }

    private var browserPicker: some View {
        Picker("", selection: $rule.browserID) {
            ForEach(browsers) { browser in
                HStack(spacing: 6) {
                    if let icon = browser.icon { Image(nsImage: icon) }
                    Text(browser.name)
                }
                .tag(browser.id)
            }
        }
        .labelsHidden()
        .frame(width: 110)
    }

    private var toggleButtons: some View {
        HStack(spacing: 4) {
            Button { rule.incognito.toggle() } label: {
                Image(systemName: rule.incognito ? "eye.slash.fill" : "eye.slash")
                    .font(.system(size: 11))
                    .foregroundColor(rule.incognito ? .purple : .secondary.opacity(0.4))
            }
            .buttonStyle(.plain)
            .help("Incognito / Private mode")

            Button { rule.newWindow.toggle() } label: {
                Image(systemName: rule.newWindow ? "macwindow.badge.plus" : "macwindow")
                    .font(.system(size: 11))
                    .foregroundColor(rule.newWindow ? .blue : .secondary.opacity(0.4))
            }
            .buttonStyle(.plain)
            .help("Open in new window")
        }
    }

    private var deleteControl: some View {
        Button(action: onDelete) {
            Image(systemName: "xmark")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
        .opacity(0.5)
    }
}
