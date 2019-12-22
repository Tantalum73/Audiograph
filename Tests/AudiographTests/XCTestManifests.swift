import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AudiographTests.allTests),
        testCase(DataProcessorTests.allTests),
    ]
}
#endif
