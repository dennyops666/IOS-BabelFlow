// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Services",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "Services",
            targets: ["Services"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    ],
    targets: [
        .target(
            name: "Services",
            dependencies: ["KeychainAccess"],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]),
        .testTarget(
            name: "ServicesTests",
            dependencies: ["Services"]),
    ]
)
