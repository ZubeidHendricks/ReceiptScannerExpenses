import SwiftUI
import PhotosUI
import AppFactoryKit

// Receipt Scanner & Expenses — photograph a receipt, on-device OCR pulls the
// merchant and total, you confirm and log it. Free tier caps entries; Pro is
// unlimited + CSV export.
struct ContentView: View {
    @EnvironmentObject private var factory: AppFactory
    @StateObject private var store = ExpenseStore()
    private let parser: ReceiptParsing = OnDeviceReceiptParser()

    @State private var pickerItem: PhotosPickerItem?
    @State private var isProcessing = false
    @State private var pending: ParsedReceipt?
    @State private var errorText: String?
    @State private var shareItem: ShareItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    totalCard
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label("Scan a Receipt", systemImage: "doc.text.viewfinder")
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.borderedProminent).tint(.green)
                    if isProcessing { ProgressView() }
                    if let pending { pendingCard(pending) }
                    if let errorText { Text(errorText).font(.footnote).foregroundStyle(.red) }
                    list
                }
                .padding(20)
            }
            .navigationTitle("Expenses")
            .toolbar {
                if !store.expenses.isEmpty {
                    Button { exportCSV() } label: { Image(systemName: "square.and.arrow.up") }
                }
            }
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task { await scan(item) }
        }
        .sheet(item: $shareItem) { ActivityView(items: $0.items) }
    }

    private var totalCard: some View {
        VStack(spacing: 4) {
            Text(store.total, format: .currency(code: "USD")).font(.system(size: 40, weight: .bold))
            Text("\(store.expenses.count) expenses logged").foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 18)
        .background(RoundedRectangle(cornerRadius: 18).fill(.green.opacity(0.12)))
    }

    private func pendingCard(_ r: ParsedReceipt) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(r.merchant).font(.headline)
            Text(r.amount, format: .currency(code: "USD")).font(.title2.bold())
            Button {
                if store.reachedFreeLimit(isSubscribed: factory.subscriptions.isSubscribed) {
                    factory.presentPaywall(placement: "expense_limit")
                } else {
                    store.add(Expense(merchant: r.merchant, amount: r.amount, date: Date(), category: "General"))
                    pending = nil
                }
            } label: { Label("Add Expense", systemImage: "plus.circle.fill").frame(maxWidth: .infinity, minHeight: 46) }
            .buttonStyle(.borderedProminent).tint(.green)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16).background(RoundedRectangle(cornerRadius: 14).fill(.quaternary.opacity(0.5)))
    }

    private var list: some View {
        VStack(spacing: 8) {
            ForEach(store.sorted) { e in
                HStack {
                    VStack(alignment: .leading) {
                        Text(e.merchant)
                        Text(e.date, style: .date).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(e.amount, format: .currency(code: "USD"))
                    Button { store.remove(e) } label: { Image(systemName: "minus.circle") }
                        .buttonStyle(.plain).foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func scan(_ item: PhotosPickerItem) async {
        errorText = nil; pending = nil
        guard let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) else {
            errorText = "Couldn't load that photo."; return
        }
        isProcessing = true
        defer { isProcessing = false }
        do { pending = try await parser.parse(img) }
        catch { errorText = "Couldn't find a total — try a flatter, clearer shot." }
    }

    private func exportCSV() {
        factory.requirePremium(feature: "export_csv") {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("expenses.csv")
            try? store.csv().write(to: url, atomically: true, encoding: .utf8)
            shareItem = ShareItem(items: [url])
        }
    }
}

struct ShareItem: Identifiable { let id = UUID(); let items: [Any] }

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
