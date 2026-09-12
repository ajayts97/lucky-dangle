import AppKit

/// A small, borderless, transparent, click-through-everywhere-except-itself
/// window that hangs at the top of the screen. Because it's sized to just
/// the charm + string (not the full screen), it never intercepts clicks
/// anywhere else on the desktop.
final class CharmOverlayWindow: NSWindow {

    static let windowSize = NSSize(width: 140, height: 240)

    var contentRect: NSRect { NSRect(origin: .zero, size: Self.windowSize) }

    init() {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = NSPoint(
            x: screenFrame.midX - Self.windowSize.width / 2,
            y: screenFrame.maxY - Self.windowSize.height
        )
        let frame = NSRect(origin: origin, size: Self.windowSize)

        super.init(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        isMovableByWindowBackground = false
        ignoresMouseEvents = false
    }

    // Never take keyboard focus away from whatever app the user is in —
    // the charm reacts to mouse clicks/drags but shouldn't steal typing.
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
