import UIKit
import Vision
import Foundation
import Combine

struct Expense: Identifiable, Codable {
    var id = UUID()
    var merchant: String
    var amount: Double
    var date: Date
    var category: String
}

struct ParsedReceipt {
    let merchant: String
    let amount: Double
    let lines: [String]
}

enum ReceiptError: Error { case badImage, noTotal, notConfigured }

protocol ReceiptParsing {
    func parse(_ image: UIImage) async throws -> ParsedReceipt
}

/// On-device: Vision OCR reads the receipt; we heuristically extract the merchant
/// (top line) and the total (largest currency-looking amount). A trained
/// receipt-understanding model is the Remote upgrade.
struct OnDeviceReceiptParser: ReceiptParsing {
    func parse(_ image: UIImage) async throws -> ParsedReceipt {
        guard let cg = image.cgImage else { throw ReceiptError.badImage }
        let lines: [String] = await withCheckedContinuation { cont in
            let request = VNRecognizeTextRequest { req, _ in
                let ls = (req.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string } ?? []
                cont.resume(returning: ls)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            try? VNImageRequestHandler(cgImage: cg, options: [:]).perform([request])
        }
        guard !lines.isEmpty else { throw ReceiptError.noTotal }

        let merchant = lines.first { $0.count > 2 && $0.rangeOfCharacter(from: .letters) != nil } ?? "Receipt"
        guard let amount = Self.largestAmount(in: lines) else { throw ReceiptError.noTotal }
        return ParsedReceipt(merchant: merchant.capitalized, amount: amount, lines: lines)
    }

    static func largestAmount(in lines: [String]) -> Double? {
        // Prefer lines mentioning "total"; else the largest amount overall.
        let pattern = try! NSRegularExpression(pattern: #"(\d{1,6}[.,]\d{2})"#)
        func amounts(_ s: String) -> [Double] {
            let range = NSRange(s.startIndex..., in: s)
            return pattern.matches(in: s, range: range).compactMap {
                guard let r = Range($0.range(at: 1), in: s) else { return nil }
                return Double(s[r].replacingOccurrences(of: ",", with: "."))
            }
        }
        let totalLines = lines.filter { $0.lowercased().contains("total") }
        let pool = totalLines.flatMap(amounts)
        if let m = pool.max() { return m }
        return lines.flatMap(amounts).max()
    }
}

struct RemoteReceiptParser: ReceiptParsing {
    let apiKey: String
    func parse(_ image: UIImage) async throws -> ParsedReceipt { throw ReceiptError.notConfigured }
}

/// Persisted expense log. Free tier caps total entries; Pro is unlimited + export.
final class ExpenseStore: ObservableObject {
    @Published private(set) var expenses: [Expense] = []
    static let freeLimit = 10
    private let key = "expenses.v1"

    init() { load() }

    var total: Double { expenses.reduce(0) { $0 + $1.amount } }
    var sorted: [Expense] { expenses.sorted { $0.date > $1.date } }

    // Competence feedback per ../PLAYBOOK.md: this month's captured total plus
    // a "best month" personal record — evidence of real receipts captured,
    // never app opens. Static so tests can drive the logic with fixed arrays.
    static func monthTotal(in expenses: [Expense], year: Int, month: Int, calendar: Calendar = .current) -> Double {
        expenses.filter {
            let c = calendar.dateComponents([.year, .month], from: $0.date)
            return c.year == year && c.month == month
        }.reduce(0) { $0 + $1.amount }
    }
    static func bestMonthTotal(in expenses: [Expense], calendar: Calendar = .current) -> Double {
        Dictionary(grouping: expenses) { e -> String in
            let c = calendar.dateComponents([.year, .month], from: e.date)
            return "\(c.year ?? 0)-\(c.month ?? 0)"
        }
        .values.map { $0.reduce(0) { $0 + $1.amount } }.max() ?? 0
    }
    var thisMonthTotal: Double {
        let c = Calendar.current.dateComponents([.year, .month], from: Date())
        return Self.monthTotal(in: expenses, year: c.year ?? 0, month: c.month ?? 0)
    }
    var bestMonthTotal: Double { Self.bestMonthTotal(in: expenses) }
    func reachedFreeLimit(isSubscribed: Bool) -> Bool { !isSubscribed && expenses.count >= Self.freeLimit }

    func add(_ e: Expense) { expenses.append(e); save() }
    func remove(_ e: Expense) { expenses.removeAll { $0.id == e.id }; save() }

    func csv() -> String {
        var out = "Date,Merchant,Category,Amount\n"
        let df = ISO8601DateFormatter()
        for e in sorted { out += "\(df.string(from: e.date)),\(e.merchant),\(e.category),\(e.amount)\n" }
        return out
    }

    private func load() {
        guard let d = UserDefaults.standard.data(forKey: key),
              let v = try? JSONDecoder().decode([Expense].self, from: d) else { return }
        expenses = v
    }
    private func save() {
        if let d = try? JSONEncoder().encode(expenses) { UserDefaults.standard.set(d, forKey: key) }
    }
}
