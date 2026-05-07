import SwiftUI

/// Coordinator-driven product detail.
///
/// Notice the view has zero knowledge of how navigation works. It owns
/// no state machine, no `@State` flags, no `Binding<Bool>`. It simply
/// reports user intent ("buy", "close") through callbacks. The
/// `ShopFlowCoordinator` decides what to do next.
struct ShopProductDetailScreen: View {

    let product: Product
    /// Optional — set when the screen participates in a multi-step
    /// purchase flow. `nil` hides the buy button (single-step demo).
    var onBuy: (() -> Void)?
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            grabber

            Text(product.emoji)
                .font(.system(size: 64))

            Text(product.name)
                .font(.title.bold())

            Text(product.blurb)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                if let onBuy {
                    Button(action: onBuy) {
                        Label("Buy Now", systemImage: "cart.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button(action: onClose) {
                    Text(onBuy == nil ? "Close" : "Cancel")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }

    private var grabber: some View {
        Capsule()
            .fill(.tertiary)
            .frame(width: 36, height: 5)
            .padding(.top, 8)
    }
}

#Preview {
    ShopProductDetailScreen(
        product: .samples[0],
        onBuy: {},
        onClose: {}
    )
}
