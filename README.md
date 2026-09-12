# Lucky Dangle (unofficial clone)

A menu-bar charm that hangs from the top of your screen and sways like a
pendulum — inspired by [luckydangle.app](https://luckydangle.app/). This is
an independent, from-scratch implementation, not their code.

**Tech stack:** Swift 5.9 + AppKit (native macOS, no Electron/web view — this
kind of always-on-top, click-through, menu-bar-only app is exactly what
AppKit is built for and it keeps the app tiny and fast). Packaged as a Swift
Package so you can build it with just the Swift toolchain that ships with
Xcode — no separate Xcode project to hand-maintain.

## What it does

- Lives only in the menu bar (🍀 icon) — no Dock icon, no app window.
- A charm hangs from a thin string near the top-center of your screen and
  swings with simple pendulum physics (gravity + damping).
- Click-drag the charm to flick it; drag the string's anchor point to
  re-hang it anywhere along the top edge.
- `⌃D` toggles the charm's visibility, `⌃S` performs its "ritual" (a little
  kick + glow).
- Menu bar dropdown lets you pick from a handful of charms or type any
  custom emoji.
- Listens for `luckydangle://bless` so a script, Shortcut, or git hook can
  call it forward — e.g. `open "luckydangle://bless"` before a deploy.

## Requirements

- macOS 13 or later
- Xcode 15+ (for its Swift 5.9 toolchain) — Xcode Command Line Tools alone
  also work if you just want to build from Terminal

## Running it

**Fastest way to try it (Terminal):**

```bash
cd LuckyDangle
swift run
```

The charm should appear near the top of your main display and the 🍀 icon
will show up in the menu bar. `Ctrl-C` in Terminal quits it.

**Open in Xcode instead:** `File ▸ Open…` and pick the `LuckyDangle` folder
(the one containing `Package.swift`). Xcode will treat it as a Swift
Package — press ▶ to run.

**Build a proper double-clickable .app:**

```bash
cd LuckyDangle
./Scripts/build_app.sh
```

This produces `Lucky Dangle.app` in the project folder, ad-hoc signed so
its permission grants (see below) stick across launches. Drag it into
`/Applications` and launch it from there like any other app.

## One important permission note

Global keyboard shortcuts (`⌃D` / `⌃S` working even when some other app is
focused) require **Input Monitoring** access:
`System Settings ▸ Privacy & Security ▸ Input Monitoring` → enable
"Lucky Dangle". macOS will prompt for this automatically the first time it
tries to install the global monitor; if you miss the prompt, add it there
manually. Without this permission the shortcuts still work while Lucky
Dangle's own (invisible) window happens to have focus, just not globally —
this is a genuine macOS security gate, not a bug in the app.

## How it works, briefly

- `main.swift` boots a plain `NSApplication` with `.accessory` activation
  policy (no Dock icon, no app menu).
- `AppDelegate` owns the `NSStatusItem` (menu bar icon + menu) and the
  overlay window, and wires up the global/local key monitors and the
  `luckydangle://` URL handler.
- `CharmOverlayWindow` is a small (140×240pt), borderless, transparent,
  always-on-top (`level = .statusBar`) `NSWindow`. Because it's sized to
  just the charm rather than the whole screen, it never blocks clicks
  anywhere else on the desktop — there's no need for the trickier
  "ignore mouse events except in this one spot" pattern a full-screen
  overlay would require.
- `CharmView` does the drawing (Core Graphics: a string line + an emoji
  glyph) and a very small pendulum simulation stepped by a 60Hz `Timer`:
  angular acceleration from gravity pulling toward vertical, velocity
  damping so it settles, and drag gestures that either set the angle
  directly (grab-and-hold) or impart an angular-velocity "flick" on
  release.
- `Info.plist` is embedded directly into the built binary via a linker
  flag (`-sectcreate __TEXT __info_plist`), which is what makes
  `LSUIElement` (hide from Dock) and the custom URL scheme work even
  before you wrap it in a `.app` bundle.

## Ideas if you want to extend it

- Swap the `Timer`-driven loop for `CVDisplayLink` for tighter frame
  timing.
- Persist the chosen charm and window position with `UserDefaults` so it
  restores on relaunch.
- Add a couple more built-in rituals (e.g. the Daruma's "paint one eye,
  then the other" two-stage ritual from the original).
- Multi-display support: pick which `NSScreen` to hang from.
