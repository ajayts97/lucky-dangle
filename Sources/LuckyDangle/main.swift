import AppKit

// No Dock icon, no menu bar app menu, no main window — just the
// status item and the floating charm overlay. LSUIElement in
// Info.plist reinforces this at the OS level too.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
