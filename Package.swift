// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SUINavigator",
    platforms: [
        .iOS(.v17),
        .macCatalyst(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SUINavigator",
            targets: ["SUINavigator"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/hariharan-rs-19343/SUICore.git", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SUINavigator",
            dependencies: ["SUICore"]
        ),
        .testTarget(
            name: "SUINavigatorTests",
            dependencies: ["SUINavigator"]
        ),
    ]
)
