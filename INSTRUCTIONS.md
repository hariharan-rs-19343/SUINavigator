# SUINavigator – Quick Reference / Memory File

> Scope: a Swift Package that lets SwiftUI views be presented through UIKit's
> `UIViewController` presentation system with custom directions, sizes,
> alignments, and tap-to-dismiss behavior.

---

## 1. Project Identity

| Item | Value |
|---|---|
| Package name | `SUINavigator` |
| Library product | `SUINavigator` (single target) |
| Test target | `SUINavigatorTests` (uses Swift `Testing` framework) |
| `swift-tools-version` | `6.2` |
| Platforms | iOS 17+, Mac Catalyst 17+ |
| License | MIT |
| Repo path | `/Users/hari-19343/Documents/home/SUINavigator` |
| Remote (per README) | `https://github.com/hariharan-rs-19343/SUINavigator.git` |

The package re-exports SwiftUI: `@_exported import SwiftUI` in
`Sources/SUINavigator/SUINavigator.swift`. **No third-party dependencies.**

---

## 2. Folder Layout

```text
SUINavigator/
├── Package.swift
├── README.md
├── INSTRUCTIONS.md                   // this file
├── LICENSE
├── Sources/SUINavigator/
│   ├── SUINavigator.swift            // umbrella (re-exports SwiftUI)
│   ├── Core/
│   │   └── Navigator.swift           // ObservableObject, present/dismiss API
│   ├── Model/
│   │   ├── NavigatorConfiguration.swift   // Configuration + Builder + presets
│   │   └── PresentationModels.swift       // Direction / Size / Alignment enums
│   ├── Modifier/
│   │   └── NavigatorPresentationModifier.swift // .znavigator(...) View ext.
│   ├── Controller/
│   │   ├── NavigatorHostingController.swift     // UIHostingController subclass
│   │   └── NavigatorPresentationController.swift // dim + frame + tap dismiss
│   └── TransitionManager/
│       ├── NavigatorTransitioningDelegate.swift  // vends the above + animator
│       └── NavigatorTransitionAnimator.swift     // slide animation + styling
├── Tests/SUINavigatorTests/SUINavigatorTests.swift  // placeholder only
└── Example/                          // SwiftUI showcase app (see §14)
    ├── README.md
    ├── SUINavigatorExample.xcodeproj/
    └── SUINavigatorExample/          // synced root group (Xcode 16+)
```

---

## 3. Public API Surface

### 3.1 Types

- `Navigator` – `public final class … : ObservableObject`
  - `public init()` (must stay public so consumers can `@StateObject` it)
  - `@Published public private(set) var isPresented: Bool`
  - `@MainActor func present<Content: View>(configuration:content:)`
  - `@MainActor func present<Item: Identifiable, Content: View>(item:configuration:content:)`
  - `@MainActor func dismiss(completion:)`

- `NavigatorConfiguration` – `public struct, Equatable`
  - Fields (all `let`):
    - `direction: PresentationDirection`
    - `size: PresentationSize`
    - `cornerRadius: CGFloat`
    - `backgroundTapDismissEnabled: Bool`
    - `animationDuration: TimeInterval`
    - `alignment: PresentationAlignment`
    - `springDamping: CGFloat`
    - `springVelocity: CGFloat`
    - `backgroundOverlayColor: UIColor`
    - `backgroundOverlayOpacity: CGFloat`
  - Manual `Equatable` `==` (UIColor uses `isEqual`, not Swift `==`).
  - `static func builder() -> Builder`
  - Built-in presets (all `@MainActor`): `.default`, `.bottomSheet`,
    `.leftPanel`, `.rightPanel`, `.topBanner`, `.centerCard`

- `NavigatorConfiguration.Builder` (public class, fluent, `@discardableResult`)
  - `direction(_:)`, `size(_:)`, `size(width:height:)`,
    `backgroundTapDismiss(_:)`, `animationDuration(_:)`,
    `cornerRadius(_:)`, `alignment(_:)`,
    `springDamping(_:)`, `springVelocity(_:)`,
    `backgroundOverlayColor(_:)`, `backgroundOverlayOpacity(_:)`, `build()`
  - `build()` clamps `springDamping` to `0.1...1.0`, floors
    `springVelocity` at `0`, and clamps `backgroundOverlayOpacity` to
    `0.0...1.0`.

- Enums / structs in `PresentationModels.swift` (all `Sendable, Equatable`):
  - `PresentationDirection`: `.left | .right | .top | .bottom`
  - `PresentationAlignment`: `.edge | .center`
  - `PresentationSize`
    - `width: Dimension`, `height: Dimension`
    - `Dimension`: `.fixed(CGFloat) | .fraction(CGFloat) | .full`
    - Presets: `.fullScreen`, `.halfSheet`, `.sidePanel`, `.card`

### 3.2 View modifiers (in `NavigatorPresentationModifier.swift`)

```swift
public extension View {
    func znavigator<Destination: View>(
        isPresented: Binding<Bool>,
        configuration: NavigatorConfiguration = .default,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View

    func znavigator<Item: Identifiable, Destination: View>(
        item: Binding<Item?>,
        configuration: NavigatorConfiguration = .default,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder destination: @escaping (Item) -> Destination
    ) -> some View
}
```

The internal `ViewModifier`s (`NavigatorPresentationModifier`,
`NavigatorItemModifier`) are **`internal`**, not public. Item-binding
modifier dismisses the previous presentation before showing a new item id.

---

## 4. Builder Defaults (source of truth: `NavigatorConfiguration.Builder`)

| Property | Default |
|---|---|
| `direction` | `.bottom` |
| `size` | `.fullScreen` |
| `cornerRadius` | `0` |
| `backgroundTapDismissEnabled` | `true` |
| `animationDuration` | `0.30` |
| `alignment` | **`.center`** |
| `springDamping` | `1.0` (critical damping, no overshoot) |
| `springVelocity` | `0.0` (start from rest) |
| `backgroundOverlayColor` | `.black` |
| `backgroundOverlayOpacity` | `0.40` (visible dim — was `0.065`, almost invisible) |

> ⚠️ The README claims the default alignment is `.edge`. The actual builder
> default in code is `.center`. Don't rely on the README for this.

---

## 5. How a Presentation Flows (call graph)

1. SwiftUI side: `View.znavigator(...)` attaches `NavigatorPresentationModifier`
   (or `NavigatorItemModifier`).
2. The modifier embeds an invisible `ViewControllerResolver`
   (`UIViewControllerRepresentable`) to grab the parent `UIViewController`.
3. On `isPresented == true` (or new `item.id`):
   - Builds a `NavigatorHostingController(rootView: destination())`.
   - Calls `configure(with: configuration)`:
     - Creates a `NavigatorTransitioningDelegate` (strong-retained on the
       hosting controller because UIKit only keeps a weak ref).
     - Sets `transitioningDelegate` and `modalPresentationStyle = .custom`.
     - Sets `view.backgroundColor = .clear`.
   - Sets `onDismiss` to flip the binding back to `false` / `nil`.
   - Calls `presenter.present(hc, animated: true)`.
4. UIKit asks the delegate for:
   - `NavigatorPresentationController(...)` – manages dimming, frame, tap.
   - `NavigatorTransitionAnimator(isPresenting: true/false)` – slides the view.
5. `NavigatorHostingController.viewDidDisappear` fires `onDismiss` on
   `isBeingDismissed || isMovingFromParent` so swipe / tap dismissals
   keep the binding in sync.

Imperative path (`Navigator`): `Navigator.present(...)` walks the window
hierarchy via `topViewController(...)` to find the presenting VC, then
performs steps 3–5 directly. `Navigator.dismiss()` calls
`presentedHostingController?.dismiss(animated: true)`.

---

## 6. Frame Calculation – `NavigatorPresentationController`

- Resolves `PresentationSize.Dimension`:
  - `.fixed(v)` → `min(v, available)`
  - `.fraction(r)` → `available * clamp(r, 0...1)`
  - `.full` → `available`
- `alignment == .center` → centered rect in container.
- `alignment == .edge` → pinned to the slide edge (centered on the cross axis).
- `containerViewWillLayoutSubviews` re-applies the dimming view's frame on
  rotation / size changes (and re-applies the presented view's frame only
  when `presentedView.transform.isIdentity` — see §7).
- Dimming view background color comes from `configuration.backgroundOverlayColor`;
  the alpha is animated `0 → configuration.backgroundOverlayOpacity` alongside
  the slide animation, and back to `0` on dismissal.
- Tap gesture is added only if `backgroundTapDismissEnabled`.

---

## 7. Animation – `NavigatorTransitionAnimator`

- Duration: `configuration.animationDuration` for present;
  `animationDuration * 0.85` for dismiss (asymmetric — exits feel snappier
  this way).
- **Both directions** route through the private `animateWithSpring(...)`
  helper (`UIView.animate(...usingSpringWithDamping:initialSpringVelocity:)`)
  with `options: [.beginFromCurrentState, .curveLinear, .allowUserInteraction]`.
  - With `usingSpringWithDamping`, UIKit derives the timing curve from
    spring physics and ignores any `.curveEase*` option. `.curveLinear`
    is passed to make this explicit.
  - Default damping `1.0` is critically damped: snappy stop, no overshoot,
    actual duration tracks `withDuration:` closely. Lower damping → more
    overshoot/bounce **and** longer perceived duration as the spring settles.
  - Default velocity `0.0` starts from rest. Higher values give the view
    momentum at the start of the animation — useful for "thrown" exits.
- **Animated property is `view.transform`, not `view.frame`.** Critical for
  smoothness: `transform` is GPU-composited and does *not* invalidate
  layout. Animating `frame` forces a layout pass each tick, which makes
  `UIHostingController` re-validate its SwiftUI body — the most common
  cause of "presentation feels heavy/slow" with SwiftUI content.
- **`layoutIfNeeded()` is called once before the animation starts**, so
  SwiftUI's first body evaluation happens while the view is still
  off-screen. Without it, you can see a one-frame "pop" mid-slide as
  SwiftUI catches up.
- `NavigatorPresentationController.containerViewWillLayoutSubviews` skips
  `presentedView.frame =` while `presentedView.transform.isIdentity == false`
  (Apple docs: setting `frame` with a non-identity transform is undefined).
  This protects the in-flight animation from a stomping layout pass.
- Off-screen offset is computed by `offScreenTransform(for:in:)` — a pure
  `CGAffineTransform.translationX/Y` placing the view fully outside
  `containerBounds` based on `configuration.direction`.
- `applyStyling(to:)` on the presented view (called only on present):
  - Sets `cornerRadius` from configuration.
  - `maskedCorners`: all four if `.center`, otherwise the inner two for
    the slide edge (e.g. bottom slide rounds top-left + top-right).
  - **Hardcoded** shadow: black, opacity `0.3`, offset `.zero`, radius `8`.
  - `clipsToBounds = true` — note this clips the layer's shadow too, so
    the shadow code in `applyStyling` is currently a no-op for the view
    bounds. Remove `clipsToBounds` (or use a wrapper view) if you want
    the shadow to actually render.

> Tuning recipes:
> - **Snappy / no bounce** (default): `damping = 1.0`, `velocity = 0.0`.
> - **iOS-system-sheet feel**: `damping = 0.85`, `velocity = 0.4`.
> - **Bouncy modal**: `damping = 0.65`, `velocity = 0.6`.
> - **Whip exit**: pair any of the above with a higher
>   `animationDuration * 0.75` multiplier in the animator (currently 0.85).

---

## 8. Built-in Presets (actual values in code)

| Preset | direction | size | alignment | cornerRadius |
|---|---|---|---|---|
| `.default` | bottom | fullScreen | **center** (builder default) | 0 |
| `.bottomSheet` | bottom | halfSheet (full × 0.5) | center (builder default) | 16 |
| `.leftPanel` | left | sidePanel (0.4 × full) | center (builder default) | 0 |
| `.rightPanel` | right | sidePanel (0.4 × full) | center (builder default) | 0 |
| `.topBanner` | top | full × 0.15 | center (builder default) | 12 |
| `.centerCard` | bottom | card (0.8 × 0.6) | **center** (explicit) | 20 |

> ⚠️ None of the presets call `.alignment(.edge)`. Because the builder default
> is `.center`, every preset (incl. `bottomSheet`, `leftPanel`, `rightPanel`,
> `topBanner`) ends up centered, not edge-pinned. This contradicts the README's
> "Built-in Presets" table. Fix either the builder default or the presets if
> the documented behavior is desired.

---

## 9. Documentation vs. Code Discrepancies (Watch Out)

These README claims are **not** backed by the current code – do not assume they
work without adding the implementation:

1. README builder examples reference:
   - `.backgroundOverlayColor(.black)` – **now implemented** ✓
   - `.backgroundOverlayOpacity(0.4)` – **now implemented** ✓
   - `.shadow(enabled: true, radius: 10)` – **still not implemented**
   The shadow is still hardcoded in `NavigatorTransitionAnimator.applyStyling`
   (and effectively no-op'd by `clipsToBounds = true`). `Builder` *also*
   exposes `.springDamping(_:)` and `.springVelocity(_:)` which the README
   does not document.
2. Default alignment: README says `.edge`; code says `.center`.
3. Preset alignment column in README ("Edge / Center"): all presets actually
   resolve to `.center` (see §8).
4. README mentions Swift 5.9+ / Xcode 15+, but `Package.swift` declares
   `swift-tools-version: 6.2`, which requires a newer toolchain.

If you change builder defaults or add the missing builder methods, update the
README at the same time.

---

## 10. Tests

`Tests/SUINavigatorTests/SUINavigatorTests.swift` contains a single empty
`@Test func example()` placeholder using the new Swift `Testing` framework
(`import Testing`). There is **no real test coverage yet**. Adding tests for:

- `NavigatorConfiguration.Builder` defaults / fluent chaining
- `PresentationSize.Dimension` resolution (use a pure helper extracted from
  `NavigatorPresentationController.resolveSize` if you want to test it)
- `NavigatorTransitionAnimator.offScreenOrigin` per direction

would be a high-value, low-risk first PR.

---

## 11. Build / Run

```bash
swift build
swift test
```

Open in Xcode via `Package.swift` (or `xed .`). The package is iOS / Mac
Catalyst only – it will not build for plain macOS, watchOS, tvOS, or visionOS.

To run the showcase app:

```bash
open Example/SUINavigatorExample.xcodeproj
```

then ⌘R with the **SUINavigatorExample** scheme. See §14 for details.

---

## 12. Common Editing Tasks – Where to Touch

| Task | Files |
|---|---|
| Add a new builder option (e.g. shadow toggle) | `Model/NavigatorConfiguration.swift` (add field + builder method + thread through to controllers/animator) |
| Add a new preset | bottom of `NavigatorConfiguration.swift` `extension` |
| New presentation direction | `PresentationModels.swift`, `NavigatorPresentationController.frameOfPresentedViewInContainerView`, `NavigatorTransitionAnimator.offScreenOrigin` + `maskedCorners(for:)` |
| Customize dimming overlay | `NavigatorPresentationController.dimmingView` |
| Customize slide-in animation curve | `NavigatorTransitionAnimator.animateWithSpring` (single helper) — or change `springDamping`/`springVelocity` per call site via the builder |
| Tune dismiss-vs-present asymmetry | `animateDismissal`'s duration multiplier (currently `0.85`) |
| Add a new public modifier | `Modifier/NavigatorPresentationModifier.swift` (mirror existing `znavigator(...)`) |
| Imperative API surface | `Core/Navigator.swift` |

---

## 13. Conventions / Style Notes

- Naming uses the `Navigator` prefix on UIKit types
  (`NavigatorHostingController`, `NavigatorPresentationController`,
  `NavigatorTransitionAnimator`, `NavigatorTransitioningDelegate`).
- The public SwiftUI modifier is **`znavigator`** (lowercase `z`) –
  intentionally namespaced to avoid clashing with system `navigation*`.
- All UI-mutating APIs on `Navigator` are `@MainActor`.
- `Navigator.init()` **must remain `public`** — Swift's synthesized init is
  `internal`, which silently breaks consumers (we hit this when wiring up
  the example app). Don't let it regress.
- `NavigatorHostingController` retains its `transitioningDelegate` because
  UIKit only stores it weakly. Don't drop that retention if refactoring.
- `Equatable` / `Sendable` are conformed where possible on configuration types.

---

## 14. Example App (`Example/SUINavigatorExample`)

A SwiftUI showcase that consumes the local SPM package via a relative path
(`relativePath = ".."` in the pbxproj). Verified to build for iOS Simulator
on Xcode 26.4.1.

### Run it

```bash
open Example/SUINavigatorExample.xcodeproj
# then ⌘R, scheme = SUINavigatorExample
```

### What it covers

| Section in the app | API exercised |
|---|---|
| Built-in Presets | `.bottomSheet`, `.leftPanel`, `.rightPanel`, `.topBanner`, `.centerCard`, `.default` via `.znavigator(isPresented:configuration:)` |
| Item Binding | `.znavigator(item: Binding<Identifiable?>, configuration:)` |
| Imperative API | `@EnvironmentObject Navigator` + `navigator.present/dismiss` |
| Custom Builder | `NavigatorConfiguration.builder()` driven by SwiftUI sliders/toggles |

### Project structure

- `SUINavigatorExample.xcodeproj` uses **`PBXFileSystemSynchronizedRootGroup`**
  (Xcode 16+ feature). Drop a `.swift` file into `SUINavigatorExample/`
  and it's auto-included — no need to register it in the pbxproj.
- Target settings: iOS 17 deployment, `SUPPORTS_MACCATALYST = YES`,
  `GENERATE_INFOPLIST_FILE = YES` (no separate Info.plist),
  `DEVELOPMENT_TEAM = ""` (set yours for device runs).
- SPM dependency wired via `XCLocalSwiftPackageReference { relativePath = ".."; }`
  → `XCSwiftPackageProductDependency { productName = SUINavigator; }`.

### Files

```text
Example/SUINavigatorExample/
├── SUINavigatorExampleApp.swift   // @main, @StateObject AppCoordinator
├── ContentView.swift               // List with Sections + every .znavigator
├── DemoSheet.swift                 // Reusable presented content (direct API)
├── Models.swift                    // Product (Identifiable) for item demo
├── Coordinators/                   // Coordinator pattern demo
│   ├── Coordinator.swift           // protocol Coordinator: AnyObject { start() }
│   ├── AppCoordinator.swift        // root, owns the shared Navigator + children
│   └── ShopFlowCoordinator.swift   // child: detail → checkout → confirmation
├── Screens/                        // Coordinator-driven views (callback-based)
│   ├── ShopProductDetailScreen.swift
│   └── CheckoutScreen.swift        // also defines OrderConfirmedScreen
└── Assets.xcassets/                // empty AppIcon + tinted AccentColor
```

> Subfolders (`Coordinators/`, `Screens/`) are picked up automatically
> because `PBXFileSystemSynchronizedRootGroup` recurses. No pbxproj edit
> needed when adding new folders or files.

### Coordinator architecture in the example

```text
AppCoordinator                  // @EnvironmentObject root
├── owns: Navigator             // also exposed via .environmentObject
└── children: [Coordinator]
    └── ShopFlowCoordinator     // active during a multi-step purchase flow
        ├── showDetail()        // present ShopProductDetailScreen
        ├── proceedToCheckout() // dismiss → present CheckoutScreen
        ├── confirmPurchase()   // dismiss → present OrderConfirmedScreen
        └── finish()            // dismiss → onFinish(self) → parent removes
```

Two demo entry points in the **Coordinator Pattern** section of the app:

1. **Open Product Detail** — single-step `AppCoordinator.openProductDetail(_:)`.
2. **Start Shop Flow** — multi-step `AppCoordinator.startShopFlow(for:)` that
   creates a `ShopFlowCoordinator` and lets it drive the rest.

### Gotcha codified in the example

`@EnvironmentObject` is **not** inherited by views built inside
`Navigator.present(_:content:)` (the SDK passes `content()` directly to
`UIHostingController`'s init without re-applying environment objects).

The example sidesteps this two ways:

- **Direct-API demos** rely on `@Environment(\.dismiss)` (works for any
  view inside a `UIHostingController` modal).
- **Coordinator demos** pass coordinator references via *closure callbacks*
  (`onBuy`, `onConfirm`, `onClose`) so views never reach into the
  environment for navigation. This is the cleanest pattern even if/when
  the SDK starts forwarding environment objects.

If you want `Navigator` (or `AppCoordinator`) available in imperatively
presented views, wrap `content()` with `.environmentObject(self)` inside
`Navigator.present(...)` — currently a known DX gap.
