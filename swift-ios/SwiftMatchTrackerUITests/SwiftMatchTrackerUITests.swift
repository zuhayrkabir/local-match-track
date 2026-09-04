import XCTest

final class SwiftMatchTrackerUITests: XCTestCase {
    func testApplicationLaunches() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }
}
