// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LuckyDangle",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "LuckyDangle",
            path: "Sources/LuckyDangle",
            exclude: ["Info.plist"],
            linkerSettings: [
                // Embeds Info.plist into the built binary's __TEXT,__info_plist
                // section so macOS honors LSUIElement (no Dock icon) and the
                // luckydangle:// URL scheme even without a full .app bundle.
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/LuckyDangle/Info.plist"
                ])
            ]
        )
    ]
)
