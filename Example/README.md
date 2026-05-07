# SUINavigator Example

A small SwiftUI showcase app exercising every public API in the SUINavigator
package — built-in presets, the `znavigator(isPresented:)` modifier, the
`znavigator(item:)` modifier, the imperative `Navigator` `EnvironmentObject`,
and the fluent `NavigatorConfiguration.Builder`.

## Run it

```bash
open Example/SUINavigatorExample.xcodeproj
```

Then hit **⌘R** with the **SUINavigatorExample** scheme selected.

The project depends on the **local** SUINavigator package via a relative path
(`relativePath = ".."` in the pbxproj), so there's nothing to fetch — Xcode
resolves it instantly. Verified to build for iOS Simulator on Xcode 26.4.1.

```text
Targets: iOS 17+ · iPadOS 17+ · Mac Catalyst 17+
```

Mac Catalyst is enabled (`SUPPORTS_MACCATALYST = YES`), so you can also pick
**My Mac (Mac Catalyst)** from the run-destination menu.

## What the demo covers

| Section in the app | API exercised |
|---|---|
| **Built-in Presets** | `.bottomSheet`, `.leftPanel`, `.rightPanel`, `.topBanner`, `.centerCard`, `.default` via `.znavigator(isPresented:configuration:)` |
| **Item Binding** | `.znavigator(item: Binding<Identifiable?>, configuration:)` |
| **Imperative API** | `@EnvironmentObject Navigator` + `navigator.present(...)` / `navigator.dismiss()` |
| **Custom Builder** | `NavigatorConfiguration.builder()` with sliders for direction, alignment, width/height fractions, corner radius, animation duration, and tap-to-dismiss |
| **Coordinator Pattern** | `AppCoordinator` (root) + `ShopFlowCoordinator` (child) driving a multi-step detail → checkout → confirmation flow |

## Coordinator Pattern

The "Coordinator Pattern" section demonstrates how to keep navigation
logic out of your views. The architecture in this example:

```text
AppCoordinator              // @EnvironmentObject at scene root
├── navigator: Navigator    // shared with all children
└── children: [Coordinator]
    └── ShopFlowCoordinator // a multi-step subflow
```

Files:

- `Coordinators/Coordinator.swift` — minimal protocol (`func start()`).
- `Coordinators/AppCoordinator.swift` — owns the shared `Navigator`,
  exposes top-level routes (`openProductDetail`, `startShopFlow`),
  retains active child coordinators.
- `Coordinators/ShopFlowCoordinator.swift` — child coordinator that
  chains detail → checkout → confirmation → finish using
  `navigator.dismiss { … navigator.present(…) }`. Reports completion
  through an `onFinish` callback so the parent can drop it.
- `Screens/ShopProductDetailScreen.swift`, `Screens/CheckoutScreen.swift` —
  pure presentational views with callbacks (`onBuy`, `onConfirm`,
  `onCancel`, `onClose`). They have **no knowledge** of navigation.

## Project layout

```text
Example/
├── README.md
├── SUINavigatorExample.xcodeproj/
│   └── project.pbxproj                 # uses PBXFileSystemSynchronizedRootGroup
└── SUINavigatorExample/
    ├── SUINavigatorExampleApp.swift    # @main, sets up AppCoordinator env
    ├── ContentView.swift                # demo list + all .znavigator wirings
    ├── DemoSheet.swift                  # reusable presented content (direct API)
    ├── Models.swift                     # Product type for item-binding demo
    ├── Coordinators/                    # Coordinator pattern
    │   ├── Coordinator.swift
    │   ├── AppCoordinator.swift
    │   └── ShopFlowCoordinator.swift
    ├── Screens/                         # Coordinator-driven views
    │   ├── ShopProductDetailScreen.swift
    │   └── CheckoutScreen.swift
    └── Assets.xcassets/                 # empty AppIcon + tinted AccentColor
```

> The Xcode project uses `PBXFileSystemSynchronizedRootGroup` (Xcode 16+).
> Any `.swift` file you drop into `SUINavigatorExample/` — including
> nested subfolders — is automatically picked up. No pbxproj edit needed.

## Adding your own examples

1. Drop a new `.swift` file into `SUINavigatorExample/` — it's auto-included.
2. From `ContentView.swift`, add a row that flips a `@State` boolean.
3. Add a matching `.znavigator(isPresented:configuration:)` modifier with
   your destination view.

## Troubleshooting

- **"No such module 'SUINavigator'"** — Click the project in the navigator,
  go to **Package Dependencies**, and confirm the local SUINavigator package
  is present. If not, re-add it via **+** → **Add Local…** and pick the repo
  root (one directory above `Example/`).
- **Code-signing errors** — The example ships with `DEVELOPMENT_TEAM = ""`.
  Either select your team in **Signing & Capabilities** or run on the
  simulator (no signing required).
- **Want to test on device** — Change `PRODUCT_BUNDLE_IDENTIFIER` to something
  unique under your team and pick your team in **Signing & Capabilities**.
