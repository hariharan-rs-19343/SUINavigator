import SwiftUI
import SUINavigator

/// Child coordinator orchestrating a two-step "shop" subflow:
/// **product detail → checkout → finish**.
///
/// Demonstrates how a child coordinator owns its slice of navigation,
/// chains presentations through the shared `Navigator`, and tells its
/// parent when it's done so the parent can release it.
///
/// SUINavigator presents one view at a time, so chained presentations
/// require a `dismiss(completion:) { … present(…) }` handoff. That's
/// encapsulated here — call sites just see semantic methods like
/// `proceedToCheckout()` and `confirmPurchase()`.
@MainActor
final class ShopFlowCoordinator: Coordinator {

    // MARK: - Dependencies

    private let navigator: Navigator
    private let product: Product
    private let onFinish: (ShopFlowCoordinator) -> Void

    // MARK: - Init

    init(
        navigator: Navigator,
        product: Product,
        onFinish: @escaping (ShopFlowCoordinator) -> Void
    ) {
        self.navigator = navigator
        self.product = product
        self.onFinish = onFinish
    }

    // MARK: - Coordinator

    func start() {
        showDetail()
    }

    // MARK: - Steps

    /// Step 1: present the product detail.
    private func showDetail() {
        navigator.present(configuration: shopSheet) { [weak self] in
            ShopProductDetailScreen(
                product: self?.product ?? .samples[0],
                onBuy: { [weak self] in self?.proceedToCheckout() },
                onClose: { [weak self] in self?.finish() }
            )
        }
    }

    /// Step 2: dismiss the detail, then present checkout. The dismiss
    /// completion is critical — `Navigator` enforces a single active
    /// presentation at a time, so we must wait for the prior view to
    /// animate out before presenting the next.
    private func proceedToCheckout() {
        navigator.dismiss { [weak self] in
            guard let self else { return }
            self.navigator.present(configuration: self.shopSheet) { [weak self] in
                CheckoutScreen(
                    product: self?.product ?? .samples[0],
                    onConfirm: { [weak self] in self?.confirmPurchase() },
                    onCancel: { [weak self] in self?.finish() }
                )
            }
        }
    }

    /// Optional success flourish: dismiss checkout, briefly show a
    /// confirmation card, then auto-finish the flow.
    private func confirmPurchase() {
        navigator.dismiss { [weak self] in
            guard let self else { return }
            self.navigator.present(configuration: .centerCard) { [weak self] in
                OrderConfirmedScreen(
                    product: self?.product ?? .samples[0],
                    onDone: { [weak self] in self?.finish() }
                )
            }
        }
    }

    /// Tear-down: dismiss whatever is on screen, then notify the parent
    /// so it can drop us from its `children` array.
    private func finish() {
        navigator.dismiss { [weak self] in
            guard let self else { return }
            self.onFinish(self)
        }
    }

    // MARK: - Configurations

    /// Slightly punchier than the stock `.bottomSheet` so the flow has
    /// its own visual identity.
    private var shopSheet: NavigatorConfiguration {
        NavigatorConfiguration.builder()
            .direction(.bottom)
            .size(.halfSheet)
            .alignment(.edge)
            .cornerRadius(20)
            .springDamping(0.85)
            .springVelocity(0.4)
            .backgroundOverlayOpacity(0.5)
            .build()
    }
}
