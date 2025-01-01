// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "IOS-BabelFlow",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "IOS-BabelFlow",
            targets: ["IOS-BabelFlow"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    ],
    targets: [
        .target(
            name: "IOS-BabelFlow",
            dependencies: ["KeychainAccess"],
            resources: [
                .process("Resources")
            ]),
        .testTarget(
            name: "IOS-BabelFlowTests",
            dependencies: ["IOS-BabelFlow"]),
    ]
)
