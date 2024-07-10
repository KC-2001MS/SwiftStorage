// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "SwiftStorage",
    platforms: [.iOS(.v17),.macOS(.v14),.macCatalyst(.v17),.visionOS(.v1),.tvOS(.v17),.watchOS(.v10)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftStorage",
            targets: ["SwiftStorage"]
        ),
        .executable(
            name: "SwiftStorageClient",
            targets: ["SwiftStorageClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "510.0.2"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "SwiftStorageMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(name: "SwiftStorage", dependencies: ["SwiftStorageMacros"]),

        // A client of the library, which is able to use the macro in its own code.
        .executableTarget(name: "SwiftStorageClient", dependencies: ["SwiftStorage"]),

    ]
)
