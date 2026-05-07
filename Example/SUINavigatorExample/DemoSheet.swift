import SwiftUI

/// Reusable content shown inside a `znavigator` presentation. Uses
/// `@Environment(\.dismiss)` so it works with both the modifier and the
/// imperative `Navigator.present(...)` paths.
struct DemoSheet: View {
    let title: String
    let subtitle: String
    var accent: Color = .accentColor

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(.tertiary)
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(accent)

            Text(title)
                .font(.title.bold())

            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer(minLength: 0)

            Button {
                dismiss()
            } label: {
                Text("Close")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(accent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}

struct ProductDetail: View {
    let product: Product

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text(product.emoji)
                .font(.system(size: 72))

            Text(product.name)
                .font(.title.bold())

            Text(product.blurb)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer(minLength: 0)

            Button {
                dismiss()
            } label: {
                Text("Close")
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

#Preview("DemoSheet") {
    DemoSheet(title: "Demo", subtitle: "Lorem ipsum dolor sit amet.")
}
