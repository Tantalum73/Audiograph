import XCTest
@testable import Audiograph

final class AudiographTests: XCTestCase {
    let generator = SoundGenerator(sampleRate: 44100.0, volumeCorrectionFactor: 1)
    
    func test_indexOfLatestChangeInSign_whenEndIsPositive() {
        let input: [Double] = [-2, -1, 1, 2]
        let expectedRemovedElements = 2
        
        let resultIndex = input.numberOfElementsToRemovedUntilLatestChangeInSignTowardsPositive()
        
        XCTAssertEqual(resultIndex, expectedRemovedElements)
    }
    
    func test_indexOfLatestChangeInSign_whenEndIsNegative() {
        let input: [Double] = [-2, -1, 1, 2, 1, -1]
        let expectedRemovedElements = 4
        
        let resultIndex = input.numberOfElementsToRemovedUntilLatestChangeInSignTowardsPositive()
        
        XCTAssertEqual(resultIndex, expectedRemovedElements)
    }
    func test_indexOfLatestChangeInSign_whenNoChange_negative() {
        let input: [Double] = [-2, -1, -1, -2, -1, -1]
        let expectedRemovedElements: Int? = nil
        
        let resultIndex = input.numberOfElementsToRemovedUntilLatestChangeInSignTowardsPositive()
        
        XCTAssertEqual(resultIndex, expectedRemovedElements)
    }
    func test_indexOfLatestChangeInSign_whenNoChange_positive() {
        let input: [Double] = [2, 1, 1, 2, 1, 1]
        let expectedIndex: Int? = nil
        
        let resultIndex = input.numberOfElementsToRemovedUntilLatestChangeInSignTowardsPositive()
        
        XCTAssertEqual(resultIndex, expectedIndex)
    }
    
    func test_cutOffIndex_whenEndingOnPositive() {
        var input: [Double] = [-2, -1, 1, 2, 1]
        let expect: [Double] = [-2, -1, 0]
        
        input.postprocess()
        XCTAssertEqual(input, expect)
    }
    
    func test_cutOffIndex_whenEndingOnNegative() {
        var input: [Double] = [-2, -1, 1, 2, 1, -1]
        let expect: [Double] = [-2, -1, 0]
        
        input.postprocess()
        XCTAssertEqual(input, expect)
    }
    
    func test_cutOffIndex_whenNoZeroIncluded() {
        var input: [Double] = [2, 1, 1, 2, 1, 1]
        let expect: [Double] = [2, 1, 1, 2, 1, 1, 0]
        
        input.postprocess()
        XCTAssertEqual(input, expect)
    }
    
    
    func test_edgeCaseNoCrash_emptyInput() {
        let audiograph = Audiograph(localizationProvider: AudiographLocalizations.defaultEnglish)
        audiograph.volumeCorrectionFactor = 0
        
        let input = [CGPoint]()
        audiograph.play(graphContent: input)
    }
    func test_edgeCaseNoCrash_oneInput() {
        let audiograph = Audiograph(localizationProvider: AudiographLocalizations.defaultEnglish)
        audiograph.volumeCorrectionFactor = 0
        
        let input = [CGPoint(x: 10, y: 10)]
        audiograph.play(graphContent: input)
    }
    func test_edgeCaseNoCrash_input_zero() {
        let audiograph = Audiograph(localizationProvider: AudiographLocalizations.defaultEnglish)
        audiograph.volumeCorrectionFactor = 0
        
        let input = [CGPoint(x: 0, y: 0)]
        audiograph.play(graphContent: input)
    }
    func test_edgeCaseNoCrash_inputTimes_negative() {
        let audiograph = Audiograph(localizationProvider: AudiographLocalizations.defaultEnglish)
        audiograph.volumeCorrectionFactor = 0
        
        let input = [CGPoint(x: -10, y: 10)]
        audiograph.play(graphContent: input)
    }
    func test_edgeCaseNoCrash_inputFrequency_negative() {
        let audiograph = Audiograph(localizationProvider: AudiographLocalizations.defaultEnglish)
        audiograph.volumeCorrectionFactor = 0
        
        let input = [CGPoint(x: 10, y: -10)]
        audiograph.play(graphContent: input)
    }
    func test_edgeCaseNoCrash_noTimeDifference() {
        let audiograph = Audiograph(localizationProvider: AudiographLocalizations.defaultEnglish)
        audiograph.volumeCorrectionFactor = 0
        
        let input = [CGPoint(x: 10, y: 10),
                     CGPoint(x: 10, y: 20)]
        audiograph.play(graphContent: input)
    }
    
    func test_edgeCaseNoCrash_noFrequencyDifference() {
        let audiograph = Audiograph(localizationProvider: AudiographLocalizations.defaultEnglish)
        audiograph.volumeCorrectionFactor = 0
        
        let input = [CGPoint(x: 10, y: 10),
                     CGPoint(x: 20, y: 10)]
        audiograph.play(graphContent: input)
    }
    
    func test_edgeCaseNoCrash_sameDataMultipleTimes() {
        let audiograph = Audiograph(localizationProvider: AudiographLocalizations.defaultEnglish)
        audiograph.volumeCorrectionFactor = 0
        
        let input = [
            CGPoint(x: 10, y: 10),
            CGPoint(x: 10, y: 10),
            CGPoint(x: 20, y: 20)
        ]
        audiograph.play(graphContent: input)
    }
    
    func test_edgeCaseNoCrash_inputNotSorted() {
        let audiograph = Audiograph(localizationProvider: AudiographLocalizations.defaultEnglish)
        audiograph.volumeCorrectionFactor = 0
        
        let input = [
            CGPoint(x: 10, y: 10),
            CGPoint(x: 5, y: 30),
            CGPoint(x: 20, y: 20)
        ]
        audiograph.play(graphContent: input)
    }
    
    // MARK: - Performance
    func test_performance_realData() {
        let points = TestData.points
        let audiograph = Audiograph(localizationProvider: AudiographLocalizations.defaultEnglish)
        
        let options: XCTMeasureOptions = XCTMeasureOptions()
        options.iterationCount = 11
        options.invocationOptions = [.manuallyStop]
        audiograph.volumeCorrectionFactor = 0
        
        if #available(iOS 13.0, *), #available(OSX 10.15, *) {
            measure(options: options) {
                
                let expectation = XCTestExpectation(description: "Wait for audio completion.")
                audiograph.processingCompletion = {
                    expectation.fulfill()
                }
                audiograph.play(graphContent: points)
                
                wait(for: [expectation], timeout: 10.0)
                self.stopMeasuring()
            }
        }
        
    }
}
