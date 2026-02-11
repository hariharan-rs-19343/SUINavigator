# SUINavigator

A UIKit-backed custom navigation framework for **iOS**, **iPadOS**, and **Mac Catalyst**. Present SwiftUI views using `UIViewController` presentation with custom transitions — slide from any direction, control size, alignment, and toggle tap-to-dismiss.

## Features

- **UIKit Presentation Engine** — uses `UIPresentationController` and `UIViewControllerAnimatedTransitioning` for native-feel presentations
- **Directional Slides** — slide views in from **left**, **right**, **top**, or **bottom**
- **Flexible Sizing** — fixed points, fractional percentages, or full-screen dimensions
- **Alignment Options** — edge-aligned or centered presentations
- **Background Tap Dismiss** — configurable tap-to-dismiss on the dimmed overlay
- **Visual Customization** — corner radius, shadows, and overlay opacity
- **Builder Pattern** — fluent API for easy configuration
- **Multiple APIs** — `Binding<Bool>`, `Binding<Item?>`, or imperative `Navigator`

## Requirements

| Platform | Minimum Version |
|---|---|
| iOS | 17.0 |
| iPadOS | 17.0 |
| Mac Catalyst | 17.0 |

- Swift 5.9+
- Xcode 15+

## Installation

### Swift Package Manager

Add SUINavigator via **File → Add Package Dependencies…** in Xcode, or in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/hariharan-rs-19343/SUINavigator.git", from: "1.0.0")
]
```

Then add `"SUINavigator"` to your target's dependencies.

## Quick Start

### Boolean Binding (Simple)

```swift
import SwiftUI
import SUINavigator

struct ContentView: View {
    @State private var showSettings = false

    var body: some View {
        Button("Open Settings") {
            showSettings = true
        }
        .znavigator(isPresented: $showSettings, configuration: .bottomSheet) {
            SettingsView()
        }
    }
}
```

### Item Binding (Identifiable)

Present based on an optional `Identifiable` item:

```swift
struct Product: Identifiable {
    let id: Int
    let name: String
}

struct ContentView: View {
    @State private var selectedProduct: Product?
    let products: [Product] = [...]

    var body: some View {
        List(products) { product in
            Button(product.name) {
                selectedProduct = product
            }
        }
        .znavigator(item: $selectedProduct, configuration: .centerCard) { product in
            ProductDetailView(product: product)
        }
    }
}
```

Setting `selectedProduct` to a new item dismisses the current presentation and shows the new one. Setting it to `nil` dismisses.

### Navigator Environment Object (Imperative)

```swift
@main
struct MyApp: App {
    @StateObject private var navigator = Navigator()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(navigator)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var navigator: Navigator

    var body: some View {
        VStack(spacing: 20) {
            Button("Left Panel") {
                navigator.present(configuration: .leftPanel) {
                    SideMenuView()
                }
            }
            Button("Center Card") {
                navigator.present(configuration: .centerCard) {
                    CardView()
                }
            }
        }
    }
}
```

## Configuration

Use the **builder pattern** to create custom configurations:

```swift
let config = NavigatorConfiguration.builder()
    .direction(.bottom)              // Slide direction
    .size(.halfSheet)                // Presentation size
    .alignment(.edge)                // Edge or center alignment
    .backgroundTapDismiss(true)      // Tap background to dismiss
    .backgroundOverlayColor(.black)
    .backgroundOverlayOpacity(0.4)
    .animationDuration(0.35)
    .cornerRadius(16)
    .shadow(enabled: true, radius: 10)
    .build()
```

### Presentation Direction

```swift
.direction(.left)    // Slides from left edge
.direction(.right)   // Slides from right edge
.direction(.top)     // Slides from top edge
.direction(.bottom)  // Slides from bottom edge  (default)
```

### Presentation Size

```swift
// Presets
.size(.fullScreen)   // Full width and height
.size(.halfSheet)    // Full width, 50% height
.size(.sidePanel)    // 40% width, full height
.size(.card)         // 80% width, 60% height

// Custom dimensions
.size(width: .fixed(300), height: .full)
.size(width: .fraction(0.8), height: .fraction(0.5))
```

### Presentation Alignment

```swift
.alignment(.edge)    // Sticks to the slide-in edge (default)
.alignment(.center)  // Centered in the container
```

With `.edge` alignment, a bottom sheet stays pinned to the bottom. With `.center` alignment, the same view appears centered on screen — the direction only controls the animation.

## Built-in Presets

| Preset | Direction | Size | Alignment | Corner Radius | Shadow |
|---|---|---|---|---|---|
| `.default` | Bottom | Full Screen | Edge | 0 | No |
| `.bottomSheet` | Bottom | Full × 50% | Edge | 16 | Yes |
| `.leftPanel` | Left | 40% × Full | Edge | 0 | Yes |
| `.rightPanel` | Right | 40% × Full | Edge | 0 | Yes |
| `.topBanner` | Top | Full × 15% | Edge | 12 | Yes |
| `.centerCard` | Bottom | 80% × 60% | Center | 20 | Yes |

```swift
// Use presets directly
.znavigator(isPresented: $show, configuration: .centerCard) {
    MyView()
}
```

## Examples

### Bottom Sheet

```swift
let sheetConfig = NavigatorConfiguration.builder()
    .direction(.bottom)
    .size(width: .full, height: .fraction(0.6))
    .cornerRadius(20)
    .shadow(enabled: true)
    .build()

.znavigator(isPresented: $showSheet, configuration: sheetConfig) {
    SheetContent()
}
```

### Centered Modal

```swift
let modalConfig = NavigatorConfiguration.builder()
    .direction(.bottom)
    .size(width: .fraction(0.85), height: .fraction(0.5))
    .alignment(.center)
    .cornerRadius(16)
    .backgroundOverlayOpacity(0.5)
    .build()

.znavigator(isPresented: $showModal, configuration: modalConfig) {
    ModalContent()
}
```

### Side Menu

```swift
let menuConfig = NavigatorConfiguration.builder()
    .direction(.left)
    .size(width: .fraction(0.75), height: .full)
    .backgroundTapDismiss(true)
    .shadow(enabled: true, radius: 8)
    .build()

.znavigator(isPresented: $showMenu, configuration: menuConfig) {
    MenuView()
}
```

### Toast Banner

```swift
let toastConfig = NavigatorConfiguration.builder()
    .direction(.top)
    .size(width: .fraction(0.9), height: .fixed(80))
    .alignment(.center)
    .cornerRadius(12)
    .animationDuration(0.25)
    .backgroundOverlayOpacity(0)
    .build()
```

## Dismissing Programmatically

```swift
struct PresentedView: View {
    @EnvironmentObject var navigator: Navigator

    var body: some View {
        VStack {
            Text("Hello!")
            Button("Close") {
                navigator.dismiss()
            }
        }
    }
}
```

### How It Works

1. Your SwiftUI view is wrapped in `NavigatorHostingController` (a `UIHostingController` subclass).
2. A custom `UIViewControllerTransitioningDelegate` vends:
   - **`NavigatorPresentationController`** — manages the dimming overlay, calculates the presented frame (edge or center), and handles tap-to-dismiss.
   - **`NavigatorTransitionAnimator`** — slides the view on/off screen with spring animation.
3. UIKit's `present(_:animated:)` drives the entire lifecycle.

## License

MIT License. See [LICENSE](LICENSE) for details.
