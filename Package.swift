// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "FloatTranslate",
    platforms: [
        .macOS("15.0")
    ],
    products: [
        .executable(name: "FloatTranslate", targets: ["FloatTranslate"])
    ],
    targets: [
        .executableTarget(
            name: "FloatTranslate"
        ),
        .testTarget(
            name: "FloatTranslateTests",
            dependencies: ["FloatTranslate"]
        )
    ]
)
