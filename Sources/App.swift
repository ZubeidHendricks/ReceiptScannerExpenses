import SwiftUI
import AppFactoryKit

// Receipt Scanner & Expenses — payments via native StoreKit 2 (no third-party SDK).
private enum Product {
    static let yearly = "receipts_pro_yearly"
    static let weekly = "receipts_pro_weekly"
}

@MainActor
enum ReceiptScannerFactory {
    static func make() -> AppFactory {
        let config = AppFactoryConfiguration(
            appName: "Receipt Scanner",
            purchaseProvider: StoreKit2PurchaseProvider(productIDs: [Product.yearly, Product.weekly]),
            onboarding: OnboardingConfiguration(
                slides: [
                    .init(systemImage: "doc.text.viewfinder",
                          title: "Snap Your Receipts",
                          message: "Photograph any receipt — the total and merchant are read automatically, on-device."),
                    .init(systemImage: "chart.pie",
                          title: "Expenses, Organized",
                          message: "Every receipt lands in a tidy expense log you can export at tax time.")
                ],
                presentsPaywallOnFinish: true,
                accent: .green
            ),
            paywall: PaywallConfiguration(
                headline: "Unlock Receipt Scanner Pro",
                subheadline: "Never lose a deductible expense again.",
                benefits: [
                    .init(systemImage: "infinity", title: "Unlimited receipts"),
                    .init(systemImage: "tablecells", title: "CSV export for taxes"),
                    .init(systemImage: "text.viewfinder", title: "Automatic total detection"),
                    .init(systemImage: "nosign", title: "No ads")
                ],
                productIDs: [Product.yearly, Product.weekly],
                highlightedProductID: Product.yearly,
                ctaTitle: "Continue",
                dismissButtonDelay: 4,
                isDismissable: true,
                termsURL: URL(string: "https://zubeidhendricks.github.io/ReceiptScannerExpenses/terms.html"),
                privacyURL: URL(string: "https://zubeidhendricks.github.io/ReceiptScannerExpenses/privacy.html"),
                style: PaywallStyle(accent: .green, heroSystemImage: "doc.text.viewfinder")
            )
        )
        return AppFactory(config)
    }
}

@main
struct ReceiptScannerApp: App {
    @StateObject private var factory = ReceiptScannerFactory.make()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .appFactoryRoot(factory)
                .tint(.green)
        }
    }
}
