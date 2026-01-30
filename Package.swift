// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SUINavigator",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SUINavigator",
            targets: ["SUINavigator"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SUINavigator"
        ),
        .testTarget(
            name: "SUINavigatorTests",
            dependencies: ["SUINavigator"]
        ),
    ]
)
