import AppKit

final class CacheManagerController {
    static let shared = CacheManagerController()
    private init() {}

    private let storageDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".orchid/storage")

    func clearCache() {
        // MARK: Step 1 — Confirm dialog
        let confirm = NSAlert()
        confirm.messageText = "清空图片缓存"
        confirm.informativeText = "将删除所有已保存的截图（\(cachedFileCount()) 张）。此操作不可撤销。"
        confirm.alertStyle = .warning
        confirm.addButton(withTitle: "清空")
        confirm.addButton(withTitle: "取消")
        NSApp.activate(ignoringOtherApps: true)
        guard confirm.runModal() == .alertFirstButtonReturn else { return }

        // MARK: Step 2 — Progress panel
        let panel = makeProgressPanel()
        panel.makeKeyAndOrderFront(nil)

        // MARK: Step 3 — Delete in background
        DispatchQueue.global(qos: .userInitiated).async {
            var deletedCount = 0
            var errorOccurred = false

            do {
                let fm = FileManager.default
                let files = try fm.contentsOfDirectory(
                    at: self.storageDir,
                    includingPropertiesForKeys: nil
                ).filter { $0.pathExtension.lowercased() == "png" }

                for file in files {
                    do {
                        try fm.removeItem(at: file)
                        deletedCount += 1
                    } catch {
                        print("Orchid: failed to delete \(file.lastPathComponent): \(error)")
                        errorOccurred = true
                    }
                }
            } catch {
                // storageDir might not exist yet — treat as 0 files
                print("Orchid: cache dir not found or unreadable: \(error)")
            }

            // MARK: Step 4 — Update panel on main thread
            DispatchQueue.main.async {
                self.showDoneState(in: panel, count: deletedCount, hadError: errorOccurred)
            }
        }
    }

    // MARK: - Helpers

    private func cachedFileCount() -> Int {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: storageDir,
            includingPropertiesForKeys: nil
        ) else { return 0 }
        return files.filter { $0.pathExtension.lowercased() == "png" }.count
    }

    // Builds a small floating panel with a spinner + label
    private func makeProgressPanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 90),
            styleMask: [.titled, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "清空缓存"
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.center()

        let spinner = NSProgressIndicator()
        spinner.style = .spinning
        spinner.controlSize = .regular
        spinner.isIndeterminate = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimation(nil)

        let label = NSTextField(labelWithString: "正在删除，请稍候…")
        label.font = NSFont.systemFont(ofSize: 13)
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.identifier = NSUserInterfaceItemIdentifier("statusLabel")

        let stack = NSStackView(views: [spinner, label])
        stack.orientation = .horizontal
        stack.spacing = 10
        stack.alignment = .centerY
        stack.translatesAutoresizingMaskIntoConstraints = false

        let content = panel.contentView!
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: content.centerYAnchor),
        ])

        panel.identifier = NSUserInterfaceItemIdentifier("cacheProgressPanel")
        return panel
    }

    // Replaces spinner+label with a checkmark + count, adds OK button
    private func showDoneState(in panel: NSPanel, count: Int, hadError: Bool) {
        guard let content = panel.contentView else { return }

        // Remove existing subviews
        content.subviews.forEach { $0.removeFromSuperview() }

        let icon = NSTextField(labelWithString: hadError ? "⚠️" : "✅")
        icon.font = NSFont.systemFont(ofSize: 24)
        icon.translatesAutoresizingMaskIntoConstraints = false

        let message = hadError
            ? "部分文件删除失败，已删除 \(count) 张。"
            : (count == 0 ? "缓存本来就是空的。" : "已删除 \(count) 张截图。")
        let label = NSTextField(labelWithString: message)
        label.font = NSFont.systemFont(ofSize: 13)
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let okButton = NSButton(title: "好", target: nil, action: nil)
        okButton.bezelStyle = .rounded
        okButton.keyEquivalent = "\r"
        okButton.translatesAutoresizingMaskIntoConstraints = false
        okButton.onAction { [weak panel] in panel?.close() }

        let topStack = NSStackView(views: [icon, label])
        topStack.orientation = .horizontal
        topStack.spacing = 8
        topStack.alignment = .centerY
        topStack.translatesAutoresizingMaskIntoConstraints = false

        let mainStack = NSStackView(views: [topStack, okButton])
        mainStack.orientation = .vertical
        mainStack.spacing = 14
        mainStack.alignment = .centerX
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        content.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            mainStack.centerYAnchor.constraint(equalTo: content.centerYAnchor),
        ])

        panel.makeKeyAndOrderFront(nil)
    }
}

// MARK: - Tiny NSButton action helper (avoids target/selector boilerplate)
private var actionKey = 0
extension NSButton {
    func onAction(_ handler: @escaping () -> Void) {
        objc_setAssociatedObject(self, &actionKey, handler, .OBJC_ASSOCIATION_RETAIN)
        self.target = self
        self.action = #selector(invokeAction)
    }

    @objc private func invokeAction() {
        if let handler = objc_getAssociatedObject(self, &actionKey) as? () -> Void {
            handler()
        }
    }
}
