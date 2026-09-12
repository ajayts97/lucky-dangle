import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem!
    var overlayWindow: CharmOverlayWindow!
    var charmView: CharmView!
    var toggleMenuItem: NSMenuItem!
    var isVisible = true

    private let charms: [(emoji: String, name: String)] = [
        ("🍀", "Four-Leaf Clover"),
        ("🧿", "Nazar Boncuğu"),
        ("🔔", "Ghanta Bell"),
        ("🪬", "Hamsa"),
        ("🎎", "Daruma"),
        ("🐱", "Maneki-neko"),
        ("🧲", "Horseshoe"),
        ("🐞", "Ladybug")
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupOverlayWindow()
        setupStatusItem()
        setupGlobalHotkeys()
    }

    // MARK: - Status item / menu

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.title = "🍀"

        let menu = NSMenu()

        toggleMenuItem = NSMenuItem(title: "Hide Charm (⌃D)", action: #selector(toggleVisibility), keyEquivalent: "")
        toggleMenuItem.target = self
        menu.addItem(toggleMenuItem)

        let ritualItem = NSMenuItem(title: "Perform Ritual (⌃S)", action: #selector(performRitual), keyEquivalent: "")
        ritualItem.target = self
        menu.addItem(ritualItem)

        menu.addItem(.separator())

        let charmMenu = NSMenu()
        for charm in charms {
            let item = NSMenuItem(title: "\(charm.emoji)  \(charm.name)", action: #selector(chooseCharm(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = charm.emoji
            charmMenu.addItem(item)
        }
        let customItem = NSMenuItem(title: "🔤  Custom Emoji…", action: #selector(chooseCustomEmoji), keyEquivalent: "")
        customItem.target = self
        charmMenu.addItem(.separator())
        charmMenu.addItem(customItem)

        let charmMenuItem = NSMenuItem(title: "Choose Charm", action: nil, keyEquivalent: "")
        menu.setSubmenu(charmMenu, for: charmMenuItem)
        menu.addItem(charmMenuItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Lucky Dangle", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Overlay window

    private func setupOverlayWindow() {
        overlayWindow = CharmOverlayWindow()
        charmView = CharmView(frame: overlayWindow.contentRect)
        overlayWindow.contentView = charmView
        overlayWindow.orderFrontRegardless()
    }

    // MARK: - Hotkeys
    // NOTE: global monitors only fire once the user has granted this app
    // Input Monitoring / Accessibility access in System Settings ▸ Privacy
    // & Security. Without that permission, only the local monitor (which
    // requires this app to be the focused app) will fire.

    private func setupGlobalHotkeys() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleHotkey(event)
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event -> NSEvent? in
            self?.handleHotkey(event)
            return event
        }
    }

    private func handleHotkey(_ event: NSEvent) {
        guard event.modifierFlags.contains(.control) else { return }
        switch event.charactersIgnoringModifiers?.lowercased() {
        case "d": toggleVisibility()
        case "s": performRitual()
        default: break
        }
    }

    // MARK: - Actions

    @objc private func toggleVisibility() {
        isVisible.toggle()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            overlayWindow.animator().alphaValue = isVisible ? 1 : 0
        }
        toggleMenuItem.title = isVisible ? "Hide Charm (⌃D)" : "Show Charm (⌃D)"
    }

    @objc private func performRitual() {
        charmView.performRitual()
    }

    @objc private func chooseCharm(_ sender: NSMenuItem) {
        guard let emoji = sender.representedObject as? String else { return }
        charmView.setCharm(emoji)
    }

    @objc private func chooseCustomEmoji() {
        let alert = NSAlert()
        alert.messageText = "Pick your charm"
        alert.informativeText = "Type any single emoji to hang it instead."
        alert.addButton(withTitle: "Hang It")
        alert.addButton(withTitle: "Cancel")

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        field.placeholderString = "🍀"
        alert.accessoryView = field

        if alert.runModal() == .alertFirstButtonReturn, !field.stringValue.isEmpty {
            charmView.setCharm(field.stringValue)
        }
    }

    // MARK: - luckydangle:// URL scheme
    // e.g. `open "luckydangle://bless"` from a script, shortcut, or git hook.

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where url.scheme == "luckydangle" {
            if url.host == "bless" {
                if !isVisible { toggleVisibility() }
                performRitual()
            }
        }
    }
}
