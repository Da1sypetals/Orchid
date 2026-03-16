import AppKit

// Borderless NSWindow 默认 canBecomeKey = false，导致键盘事件无法到达 contentView
// 子类化后强制返回 true
private class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

class OverlayWindowController: NSObject {
    private var window: NSWindow?

    func showOverlay() {
        // 已有 overlay 正在显示，不重复触发
        guard window == nil else { return }

        guard let screen = NSScreen.main else { return }

        // 先截全屏冻结画面，再显示 overlay（此时 overlay 窗口还不存在，不会截进去）
        let frozenImage = CGWindowListCreateImage(
            screen.frame,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        )

        let win = KeyableWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        win.level = .screenSaver
        // 窗口本身不透明，背景由 SelectionView 绘制冻结截图
        win.backgroundColor = .black
        win.isOpaque = true
        win.hasShadow = false
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        win.ignoresMouseEvents = false

        let selectionView = SelectionView(frame: screen.frame)
        selectionView.frozenScreenshot = frozenImage
        selectionView.onConfirm = { [weak self] in
            self?.dismissOverlay()
        }
        win.contentView = selectionView
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        win.makeFirstResponder(selectionView)

        self.window = win
    }

    func dismissOverlay() {
        window?.orderOut(nil)
        window = nil
    }
}
