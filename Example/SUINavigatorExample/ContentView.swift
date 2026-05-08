import SwiftUI
import SUINavigator

struct ContentView: View {

    // MARK: - Built-in preset bindings
    @State private var showBottomSheet = false
    @State private var showLeftPanel = false
    @State private var showRightPanel = false
    @State private var showTopBanner = false
    @State private var showCenterCard = false
    @State private var showFullScreen = false

    // MARK: - Item-binding demo
    @State private var selectedProduct: Product?

    // MARK: - Custom builder demo
    @State private var customDirection: PresentationDirection = .bottom
    @State private var customAlignment: PresentationAlignment = .edge
    @State private var customWidthFraction: CGFloat = 0.85
    @State private var customHeightFraction: CGFloat = 0.5
    @State private var customCornerRadius: CGFloat = 16
    @State private var customDuration: TimeInterval = 0.30
    @State private var customTapDismiss = true
    @State private var showCustom = false

    // MARK: - Imperative API
    @EnvironmentObject private var navigator: Navigator

    // MARK: - Coordinator pattern
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        NavigationStack {
            List {
                presetsSection
                itemBindingSection
                imperativeSection
                customBuilderSection
                coordinatorSection
            }
            .navigationTitle("SUINavigator")
            .navigationBarTitleDisplayMode(.large)
            // MARK: - Preset presentations
            .znavigator(isPresented: $showBottomSheet, configuration: .sheet) {
                DemoSheet(title: "Bottom Sheet",
                          subtitle: "Half-height sheet sliding up from the bottom.",
                          accent: .blue)
            }
            .znavigator(isPresented: $showLeftPanel, configuration: .leftPanel) {
                DemoSheet(title: "Left Panel",
                          subtitle: "40% wide side panel — great for menus.",
                          accent: .purple)
            }
            .znavigator(isPresented: $showRightPanel, configuration: .rightPanel) {
                DemoSheet(title: "Right Panel",
                          subtitle: "Mirror of the left panel — good for inspectors.",
                          accent: .pink)
            }
            .znavigator(isPresented: $showTopBanner, configuration: .topBanner) {
                DemoSheet(title: "Top Banner",
                          subtitle: "Notification-style banner.",
                          accent: .orange)
            }
            .znavigator(isPresented: $showCenterCard, configuration: .centerCard) {
                DemoSheet(title: "Center Card",
                          subtitle: "Centered modal with rounded corners.",
                          accent: .green)
            }
            .znavigator(isPresented: $showFullScreen, configuration: .default) {
                DemoSheet(title: "Full Screen",
                          subtitle: "The default preset — full screen, slides up.",
                          accent: .indigo)
            }
            // MARK: - Item-driven presentation
            .znavigator(item: $selectedProduct, configuration: .centerCard) { product in
                ProductDetail(product: product)
            }
            // MARK: - Custom configuration
            .znavigator(isPresented: $showCustom, configuration: customConfig) {
                DemoSheet(title: "Custom",
                          subtitle: configurationSummary,
                          accent: .teal)
            }
        }
    }

    // MARK: - Sections

    private var presetsSection: some View {
        Section {
            row("Bottom Sheet", systemImage: "rectangle.portrait.bottomhalf.filled") {
                showBottomSheet = true
            }
            row("Left Panel", systemImage: "sidebar.left") {
                showLeftPanel = true
            }
            row("Right Panel", systemImage: "sidebar.right") {
                showRightPanel = true
            }
            row("Top Banner", systemImage: "rectangle.portrait.tophalf.filled") {
                showTopBanner = true
            }
            row("Center Card", systemImage: "rectangle.center.inset.filled") {
                showCenterCard = true
            }
            row("Full Screen (default)", systemImage: "rectangle.portrait.fill") {
                showFullScreen = true
            }
        } header: {
            Text("Built-in Presets")
        } footer: {
            Text("Each preset is a ready-made `NavigatorConfiguration`. Open the SDK to see how they're composed.")
        }
    }

    private var itemBindingSection: some View {
        Section {
            ForEach(Product.samples) { product in
                Button {
                    selectedProduct = product
                } label: {
                    HStack(spacing: 12) {
                        Text(product.emoji).font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(product.name).foregroundStyle(.primary)
                            Text(product.blurb)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        } header: {
            Text("Item Binding")
        } footer: {
            Text("`.znavigator(item:)` presents a destination built from an `Identifiable` item. Setting the item to a new value swaps the presentation.")
        }
    }

    private var imperativeSection: some View {
        Section {
            Button {
                navigator.present(configuration: .bottomSheet) {
                    ImperativeDemoSheet()
                }
            } label: {
                Label("Present via Navigator", systemImage: "wand.and.rays")
            }

            Button {
                navigator.present(configuration: .leftPanel) {
                    ImperativeDemoSheet()
                }
            } label: {
                Label("Present a Left Panel", systemImage: "sidebar.left")
            }
        } header: {
            Text("Imperative API")
        } footer: {
            Text("Inject `Navigator` as an `@EnvironmentObject` and call `present(...)` / `dismiss()` from anywhere — no `@State` binding needed.")
        }
    }

    private var customBuilderSection: some View {
        Section {
            Picker("Direction", selection: $customDirection) {
                Text("Top").tag(PresentationDirection.top)
                Text("Bottom").tag(PresentationDirection.bottom)
                Text("Left").tag(PresentationDirection.left)
                Text("Right").tag(PresentationDirection.right)
            }

            Picker("Alignment", selection: $customAlignment) {
                Text("Edge").tag(PresentationAlignment.edge)
                Text("Center").tag(PresentationAlignment.center)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Width")
                    Spacer()
                    Text("\(Int(customWidthFraction * 100)) %")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $customWidthFraction, in: 0.2...1.0)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Height")
                    Spacer()
                    Text("\(Int(customHeightFraction * 100)) %")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $customHeightFraction, in: 0.2...1.0)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Corner radius")
                    Spacer()
                    Text("\(Int(customCornerRadius)) pt")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $customCornerRadius, in: 0...40)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Animation")
                    Spacer()
                    Text(customDuration, format: .number.precision(.fractionLength(2)))
                        .foregroundStyle(.secondary) + Text(" s").foregroundStyle(.secondary)
                }
                Slider(value: $customDuration, in: 0.10...1.00)
            }

            Toggle("Tap background to dismiss", isOn: $customTapDismiss)

            Button {
                showCustom = true
            } label: {
                Label("Present with Configuration", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        } header: {
            Text("Custom Builder")
        } footer: {
            Text("Tweak the controls and press present to see the resulting configuration in action.")
        }
    }

    private var coordinatorSection: some View {
        Section {
            Button {
                coordinator.openProductDetail(.samples[0])
            } label: {
                Label("Open Product Detail", systemImage: "cube.box")
            }

            Button {
                coordinator.startShopFlow(for: .samples[1])
            } label: {
                Label("Start Shop Flow", systemImage: "cart")
            }
        } header: {
            Text("Coordinator Pattern")
        } footer: {
            Text("""
            Navigation is owned by `AppCoordinator` (root) and `ShopFlowCoordinator` (child). \
            The "Shop Flow" demonstrates a chained presentation: detail → checkout → confirmation. \
            Views are pure — they only know which callback to call.
            """)
        }
    }

    // MARK: - Helpers

    private var customConfig: NavigatorConfiguration {
        NavigatorConfiguration.builder()
            .direction(customDirection)
            .size(width: .fraction(customWidthFraction),
                  height: .fraction(customHeightFraction))
            .alignment(customAlignment)
            .cornerRadius(customCornerRadius)
            .animationDuration(customDuration)
            .backgroundTapDismiss(customTapDismiss)
            .build()
    }

    private var configurationSummary: String {
        let widthPct = Int(customWidthFraction * 100)
        let heightPct = Int(customHeightFraction * 100)
        return """
        \(customDirection) • \(customAlignment) • \(widthPct)×\(heightPct)% • \
        radius \(Int(customCornerRadius)) • \
        \(String(format: "%.2f", customDuration))s
        """
    }

    @ViewBuilder
    private func row(_ title: String,
                     systemImage: String,
                     action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
    }
}

// MARK: - Imperative-only sheet

/// Demonstrates `Navigator.dismiss()` from inside a presented view.
/// Captures the navigator from the surrounding closure rather than reading
/// it from the environment, since `Navigator.present(...)` builds the
/// destination view tree outside the presenter's `@EnvironmentObject`
/// inheritance.
private struct ImperativeDemoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        DemoSheet(title: "Imperative",
                  subtitle: "Presented via `navigator.present(...)`. Tap close to call `dismiss`.",
                  accent: .red)
    }
}

#Preview(traits: .landscapeLeft, .fixedLayout(width: 1800, height: 1169)) {
    let coordinator = AppCoordinator()
    return ContentView()
        .environmentObject(coordinator)
        .environmentObject(coordinator.navigator)
}

#Preview(traits: .landscapeLeft, .fixedLayout(width: 1024, height: 665)) {
    let coordinator = AppCoordinator()
    return ContentView()
        .environmentObject(coordinator)
        .environmentObject(coordinator.navigator)
}
