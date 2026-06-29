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
}
