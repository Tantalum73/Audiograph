import XCTest
@testable import Audiograph

final class AudiographTests: XCTestCase {
    static var allTests = [
        ("test_indexOfLatestChangeInSign_whenEndIsPositive", test_indexOfLatestChangeInSign_whenEndIsPositive),
        ("test_indexOfLatestChangeInSign_whenEndIsNegative", test_indexOfLatestChangeInSign_whenEndIsNegative),
        ("test_indexOfLatestChangeInSign_whenNoChange_negative", test_indexOfLatestChangeInSign_whenNoChange_negative),
        ("test_indexOfLatestChangeInSign_whenNoChange_positive", test_indexOfLatestChangeInSign_whenNoChange_positive),
        ("test_cutOffIndex_whenEndingOnPositive", test_cutOffIndex_whenEndingOnPositive),
        ("test_cutOffIndex_whenEndingOnNegative", test_cutOffIndex_whenEndingOnNegative),
        ("test_cutOffIndex_whenNoZeroIncluded", test_cutOffIndex_whenNoZeroIncluded),
        ("test_edgeCaseNoCrash_NoInput", test_edgeCaseNoCrash_NoInput),
        ("test_edgeCaseNoCrash_OneInput", test_edgeCaseNoCrash_OneInput),
        ("test_edgeCaseNoCrash_input_zero", test_edgeCaseNoCrash_input_zero),
        ("test_edgeCaseNoCrash_inputTimes_negative", test_edgeCaseNoCrash_inputTimes_negative),
        ("test_edgeCaseNoCrash_inputFrequency_negative", test_edgeCaseNoCrash_inputFrequency_negative),
        ("test_edgeCaseNoCrash_noTimeDifference", test_edgeCaseNoCrash_noTimeDifference),
        ("test_edgeCaseNoCrash_noFrequencyDifference", test_edgeCaseNoCrash_noFrequencyDifference),
        ("test_edgeCaseNoCrash_sameDataMultipleTimes", test_edgeCaseNoCrash_sameDataMultipleTimes),
        ("test_edgeCaseNoCrash_inputNotSorted", test_edgeCaseNoCrash_inputNotSorted)
    ]
    
    let generator = SoundGenerator(sampleRate: 44100.0)
    
    func test_indexOfLatestChangeInSign_whenEndIsPositive() {
        let input: [Float32] = [-2, -1, 1, 2]
        let expectedRemovedElements = 2
        
        let resultIndex = input.numberOfElementsToRemovedUntilLatestChangeInSignTowardsPositive()
        
        XCTAssertEqual(resultIndex, expectedRemovedElements)
    }
    
    func test_indexOfLatestChangeInSign_whenEndIsNegative() {
        let input: [Float32] = [-2, -1, 1, 2, 1, -1]
        let expectedRemovedElements = 4
        
        let resultIndex = input.numberOfElementsToRemovedUntilLatestChangeInSignTowardsPositive()
        
        XCTAssertEqual(resultIndex, expectedRemovedElements)
    }
    func test_indexOfLatestChangeInSign_whenNoChange_negative() {
        let input: [Float32] = [-2, -1, -1, -2, -1, -1]
        let expectedRemovedElements: Int? = nil
        
        let resultIndex = input.numberOfElementsToRemovedUntilLatestChangeInSignTowardsPositive()
        
        XCTAssertEqual(resultIndex, expectedRemovedElements)
    }
    func test_indexOfLatestChangeInSign_whenNoChange_positive() {
        let input: [Float32] = [2, 1, 1, 2, 1, 1]
        let expectedIndex: Int? = nil
        
        let resultIndex = input.numberOfElementsToRemovedUntilLatestChangeInSignTowardsPositive()
        
        XCTAssertEqual(resultIndex, expectedIndex)
    }
    
    func test_cutOffIndex_whenEndingOnPositive() {
        var input: [Float32] = [-2, -1, 1, 2, 1]
        let expect: [Float32] = [-2, -1, 0]
        
        input.postprocess()
        XCTAssertEqual(input, expect)
    }
    
    func test_cutOffIndex_whenEndingOnNegative() {
        var input: [Float32] = [-2, -1, 1, 2, 1, -1]
        let expect: [Float32] = [-2, -1, 0]
        
        input.postprocess()
        XCTAssertEqual(input, expect)
    }
    
    func test_cutOffIndex_whenNoZeroIncluded() {
        var input: [Float32] = [2, 1, 1, 2, 1, 1]
        let expect: [Float32] = [2, 1, 1, 2, 1, 1, 0]
        
        input.postprocess()
        XCTAssertEqual(input, expect)
    }
    
    
    func test_edgeCaseNoCrash_NoInput() {
        let audiograph = Audiograph()
        
        let input = [CGPoint]()
        audiograph.play(graphContent: input)
    }
    func test_edgeCaseNoCrash_OneInput() {
        let audiograph = Audiograph()
        
        let input = [CGPoint(x: 10, y: 10)]
        audiograph.play(graphContent: input)
    }
    func test_edgeCaseNoCrash_input_zero() {
        let audiograph = Audiograph()
        
        let input = [CGPoint(x: 0, y: 0)]
        audiograph.play(graphContent: input)
    }
    func test_edgeCaseNoCrash_inputTimes_negative() {
        let audiograph = Audiograph()
        
        let input = [CGPoint(x: -10, y: 10)]
        audiograph.play(graphContent: input)
    }
    func test_edgeCaseNoCrash_inputFrequency_negative() {
        let audiograph = Audiograph()
        
        let input = [CGPoint(x: 10, y: -10)]
        audiograph.play(graphContent: input)
    }
    func test_edgeCaseNoCrash_noTimeDifference() {
        let audiograph = Audiograph()
        
        let input = [CGPoint(x: 10, y: 10),
                     CGPoint(x: 10, y: 20)]
        audiograph.play(graphContent: input)
    }
    
    func test_edgeCaseNoCrash_noFrequencyDifference() {
        let audiograph = Audiograph()
        
        let input = [CGPoint(x: 10, y: 10),
                     CGPoint(x: 20, y: 10)]
        audiograph.play(graphContent: input)
    }
    
    func test_edgeCaseNoCrash_sameDataMultipleTimes() {
        let audiograph = Audiograph()
        
        let input = [
            CGPoint(x: 10, y: 10),
            CGPoint(x: 10, y: 10),
            CGPoint(x: 20, y: 20)
        ]
        audiograph.play(graphContent: input)
    }
    
    func test_edgeCaseNoCrash_inputNotSorted() {
        let audiograph = Audiograph()
        
        let input = [
            CGPoint(x: 10, y: 10),
            CGPoint(x: 5, y: 30),
            CGPoint(x: 20, y: 20)
        ]
        audiograph.play(graphContent: input)
    }
}
