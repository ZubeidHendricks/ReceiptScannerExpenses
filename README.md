# ReceiptScannerExpenses

Generated from niche `receipt-expense` (Scanning, tier A, score 79).

**Utility:** Scan receipts → categorized expense log
**Primary ASO keyword:** `receipt scanner`
**Also target:** `expense tracker`, `receipt organizer`, `spending tracker`, `tax receipts`
**Paywall hook:** Unlimited receipts, export CSV, mileage

> Freelancers/tax = high intent. OCR + categorize. Recurring use.

## Build it

```bash
brew install xcodegen        # once
cd ReceiptScannerExpenses
xcodegen generate
open ReceiptScannerExpenses.xcodeproj
```

The app runs immediately on a MockPurchaseProvider (real paywall UI, fake
purchases). To go live:

1. Replace `revenueCatKey` in `Sources/App.swift` with your RevenueCat key.
2. In App Store Connect create products `receipt-expense_yearly` and `receipt-expense_weekly`,
   map them into a RevenueCat offering, entitlement id `premium`.
3. Build the real feature in `Sources/ContentView.swift`.
4. **Guideline 4.3:** make the function, UI, screenshots and keywords genuinely
   distinct from any sibling app. Re-niche, never reskin.

Bundle id: `com.zubeid.receiptexpense`

## Ship to TestFlight

This app ships with a Fastlane lane + GitHub Actions workflow. One-time account
setup (API key, signing) is documented in the kit's `Tools/appgen/DEPLOYMENT.md`.
Once your GitHub secrets are set, trigger the **TestFlight** workflow (or push a
`v*` tag), or run locally:

```bash
bundle install
bundle exec fastlane beta
```
