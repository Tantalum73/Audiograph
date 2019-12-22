import XCTest
@testable import Audiograph

final class AudiographTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Audiograph().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
