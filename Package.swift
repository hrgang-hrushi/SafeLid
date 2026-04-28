// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "SafeLid",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SafeLid", targets: ["SafeLid"])
    ],
    targets: [
        .executableTarget(
            name: "SafeLid",
            path: "SafeLid",
            exclude: ["Info.plist"]
        )
    ]
)