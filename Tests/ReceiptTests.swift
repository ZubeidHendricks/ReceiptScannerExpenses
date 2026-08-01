import XCTest
// ReceiptService.swift compiled into this test target.

final class ReceiptTests: XCTestCase {
    func testPrefersTotalLine() throws {
        let lines = ["Store ABC", "Item 1  5.00", "Item 2  12.50", "TOTAL  17.50"]
        let v = try XCTUnwrap(OnDeviceReceiptParser.largestAmount(in: lines))
        XCTAssertEqual(v, 17.50, accuracy: 0.001)
    }

    func testFallsBackToLargest() throws {
        let lines = ["a 3.00", "b 9.99", "c 1.00"]
        let v = try XCTUnwrap(OnDeviceReceiptParser.largestAmount(in: lines))
        XCTAssertEqual(v, 9.99, accuracy: 0.001)
    }

    func testNoAmountReturnsNil() {
        XCTAssertNil(OnDeviceReceiptParser.largestAmount(in: ["no numbers here"]))
    }

    func testCSVHeader() {
        XCTAssertTrue(ExpenseStore().csv().hasPrefix("Date,Merchant,Category,Amount"))
    }

    // Competence-feedback logic (see ../PLAYBOOK.md).
    private func expense(_ amount: Double, _ y: Int, _ m: Int, _ d: Int = 5) -> Expense {
        Expense(merchant: "M", amount: amount,
                date: Calendar.current.date(from: DateComponents(year: y, month: m, day: d))!,
                category: "General")
    }

    func testMonthTotalOnlyCountsThatMonth() {
        let expenses = [expense(10, 2026, 7), expense(15, 2026, 7), expense(99, 2026, 6), expense(30, 2025, 7)]
        XCTAssertEqual(ExpenseStore.monthTotal(in: expenses, year: 2026, month: 7), 25, accuracy: 0.001)
    }

    func testBestMonthTotalPicksTopMonth() {
        let expenses = [expense(10, 2026, 1), expense(40, 2026, 2), expense(35, 2026, 2, 20), expense(60, 2026, 3)]
        XCTAssertEqual(ExpenseStore.bestMonthTotal(in: expenses), 75, accuracy: 0.001)
    }

    func testBestMonthTotalEmptyIsZero() {
        XCTAssertEqual(ExpenseStore.bestMonthTotal(in: []), 0)
    }
}
