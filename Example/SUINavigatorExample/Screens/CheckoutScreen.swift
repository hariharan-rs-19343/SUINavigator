import SwiftUI

/// Step 2 of the shop flow. Pure presentation — coordinator decides
/// what each callback means.
struct CheckoutScreen: View {

    let product: Product
    var onConfirm: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(.tertiary)
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            Text("Checkout")
                .font(.title.bold())

            HStack(spacing: 12) {
                Text(product.emoji).font(.largeTitle)
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.name).font(.headline)
                    Text("Qty 1 · Free shipping")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("$199")
                    .font(.headline.monospacedDigit())
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                Button(action: onConfirm) {
                    Label("Confirm Purchase", systemImage: "checkmark.seal.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)

                Button(action: onCancel) {
                    Text("Cancel")
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
}

/// Brief success card auto-dismissed by the coordinator.
struct OrderConfirmedScreen: View {

    let product: Product
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(.green)

            Text("Order Confirmed")
                .font(.title.bold())

            Text("Your \(product.name) is on its way.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer(minLength: 0)

            Button(action: onDone) {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}

#Preview("Checkout") {
    CheckoutScreen(product: .samples[0], onConfirm: {}, onCancel: {})
}

#Preview("Order Confirmed") {
    OrderConfirmedScreen(product: .samples[0], onDone: {})
}
