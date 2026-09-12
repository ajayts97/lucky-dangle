import AppKit

/// Draws a charm dangling from a string and simulates a lightly damped
/// pendulum. Dragging near the charm "flicks" it; dragging near the anchor
/// (top of the string) re-hangs the whole window elsewhere along the top
/// edge of the screen.
final class CharmView: NSView {

    private var emoji: String = "🍀"
    private let stringLength: CGFloat = 280
    private let anchor: NSPoint

    private var angle: CGFloat = 0.05
    private var angularVelocity: CGFloat = 0
    private let gravity: CGFloat = 9.0
    private let damping: CGFloat = 0.985

    private var timer: Timer?

    private var isDraggingAnchor = false
    private var isDraggingCharm = false
    private var lastDragLocation: NSPoint = .zero
    private var lastDragTime: TimeInterval = 0
    private var dragAngularVelocitySample: CGFloat = 0

    private var flashOpacity: CGFloat = 0

    override init(frame frameRect: NSRect) {
        anchor = NSPoint(x: frameRect.width / 2, y: frameRect.height - 24)
        super.init(frame: frameRect)
        wantsLayer = true
        startPhysicsLoop()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { timer?.invalidate() }

    func setCharm(_ newEmoji: String) {
        emoji = newEmoji
        needsDisplay = true
    }

    /// A small celebratory kick + glow, used for the built-in "ritual"
    /// (⌃S, or the luckydangle://bless URL).
    func performRitual() {
        angularVelocity += 0.55 * (Bool.random() ? 1 : -1)
        flashOpacity = 1.0
    }

    // MARK: - Physics

    private func startPhysicsLoop() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.stepPhysics()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func stepPhysics() {
        let dt: CGFloat = 1.0 / 60.0
        if !isDraggingCharm {
            let restoring = -gravity / stringLength * sin(angle)
            angularVelocity += restoring * dt * 30
            angularVelocity *= damping
            angle += angularVelocity * dt
        }
        if flashOpacity > 0 {
            flashOpacity = max(0, flashOpacity - dt)
        }
        needsDisplay = true
    }

    private func bobPosition() -> NSPoint {
        NSPoint(
            x: anchor.x + stringLength * sin(angle),
            y: anchor.y - stringLength * cos(angle)
        )
    }

    /// True while the user is actively dragging the charm or its anchor —
    /// used by the window to keep receiving events (and keep the click-through
    /// off) for the duration of the gesture.
    var isDraggingCharmOrAnchor: Bool { isDraggingCharm || isDraggingAnchor }

    var screenAnchor: NSPoint? {
        guard let window = window else { return nil }
        let p = convert(anchor, to: nil)
        return NSPoint(x: window.frame.minX + p.x, y: window.frame.minY + p.y)
    }

    var screenBob: NSPoint? {
        guard let window = window else { return nil }
        let p = convert(bobPosition(), to: nil)
        return NSPoint(x: window.frame.minX + p.x, y: window.frame.minY + p.y)
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.clear(dirtyRect)

        let bob = bobPosition()

        ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.55).cgColor)
        ctx.setLineWidth(2.4)
        ctx.move(to: anchor)
        ctx.addLine(to: bob)
        ctx.strokePath()

        ctx.setFillColor(NSColor.white.withAlphaComponent(0.7).cgColor)
        ctx.fillEllipse(in: NSRect(x: anchor.x - 4, y: anchor.y - 4, width: 8, height: 8))

        if flashOpacity > 0 {
            ctx.setFillColor(NSColor.systemYellow.withAlphaComponent(flashOpacity * 0.35).cgColor)
            ctx.fillEllipse(in: NSRect(x: bob.x - 60, y: bob.y - 60, width: 120, height: 120))
        }

        let fontSize: CGFloat = 68
        let str = NSAttributedString(string: emoji, attributes: [.font: NSFont.systemFont(ofSize: fontSize)])
        let size = str.size()
        str.draw(at: NSPoint(x: bob.x - size.width / 2, y: bob.y - size.height / 2))
    }

    // MARK: - Mouse handling

    override func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        lastDragLocation = loc
        lastDragTime = event.timestamp

        if loc.y > anchor.y - 32 {
            isDraggingAnchor = true
        } else {
            isDraggingCharm = true
            angularVelocity = 0
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)

        if isDraggingAnchor, let window = self.window {
            let dx = loc.x - lastDragLocation.x
            var frame = window.frame
            frame.origin.x += dx
            window.setFrameOrigin(frame.origin)
        } else if isDraggingCharm {
            let dx = loc.x - anchor.x
            let dy = anchor.y - loc.y
            angle = max(-1.3, min(1.3, atan2(dx, max(dy, 20))))

            let dt = max(event.timestamp - lastDragTime, 1.0 / 120.0)
            dragAngularVelocitySample = CGFloat((loc.x - lastDragLocation.x) / dt) * 0.01
        }

        lastDragLocation = loc
        lastDragTime = event.timestamp
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        if isDraggingCharm {
            angularVelocity = dragAngularVelocitySample
        }
        isDraggingCharm = false
        isDraggingAnchor = false
    }
}
