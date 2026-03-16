import AppKit
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var overlayWindowController: OverlayWindowController?
    private var hotKeyRef: EventHotKeyRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = OrchidIcon.image(size: 18)
            button.image?.isTemplate = false
            button.action = #selector(statusButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp])
            button.target = self
        }

        // Register F4 global hotkey (keyCode 118)
        registerF4HotKey()

        // Request Screen Recording permission silently on launch (no overlay)
        requestScreenCapturePermission {}
    }

    // MARK: - Screen Recording Permission

    private func requestScreenCapturePermission(completion: @escaping () -> Void) {
        if CGPreflightScreenCaptureAccess() {
            completion()
            return
        }

        let granted = CGRequestScreenCaptureAccess()
        if granted {
            completion()
        } else {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "需要屏幕录制权限"
                alert.informativeText = "Orchid 需要「屏幕录制」权限才能截取屏幕内容。\n请前往：系统设置 → 隐私与安全性 → 屏幕录制，勾选 Orchid 后重新启动应用。"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "打开系统设置")
                alert.addButton(withTitle: "稍后")
                NSApp.activate(ignoringOtherApps: true)
                if alert.runModal() == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(
                        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
                    )
                }
            }
        }
    }

    // MARK: - Status Button (left = menu)

    @objc func statusButtonClicked(_ sender: NSStatusBarButton) {
        showContextMenu()
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "截图识别", action: #selector(showOverlay), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "清空图片缓存", action: #selector(clearCache), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出 Orchid", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        // Remove menu so next left-click triggers action directly
        DispatchQueue.main.async { self.statusItem?.menu = nil }
    }

    @objc func showOverlay() {
        guard CGPreflightScreenCaptureAccess() else {
            requestScreenCapturePermission {}
            return
        }
        if overlayWindowController == nil {
            overlayWindowController = OverlayWindowController()
        }
        overlayWindowController?.showOverlay()
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }

    @objc func clearCache() {
        CacheManagerController.shared.clearCache()
    }

    // MARK: - F4 Global Hotkey

    private func registerF4HotKey() {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x4F524344) // 'ORCD'
        hotKeyID.id = 1

        let status = RegisterEventHotKey(
            118, // F4
            0,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if status != noErr {
            print("Orchid: failed to register F4 hotkey, status=\(status)")
            return
        }

        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, _, userData) -> OSStatus in
                guard let userData = userData else { return noErr }
                let delegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async { delegate.showOverlay() }
                return noErr
            },
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
        }
    }
}
