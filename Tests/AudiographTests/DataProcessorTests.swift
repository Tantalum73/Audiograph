//
//  DataProcessorTests.swift
//  ChartAndSoundTests
//
//  Created by Andreas Neusüß on 14.12.19.
//  Copyright © 2019 Anerma. All rights reserved.
//


import XCTest
@testable import Audiograph

final class DataProcessorTests: XCTestCase {
    
    var dataProcessor: DataProcessor!

    override func setUp() {
        dataProcessor = DataProcessor()
    }
    
    // MARK: Scaling Frequencies
    func test_scalingFrequenciesMinMax() {
        dataProcessor.playingDuration = .short
        
        let inputFrequencies: [Double] = [1, 2, 3]
        let inputTimes = [0.0, 0.3, 0.8]
        
        let inputInformation = AudioInformation(relativeTimes: inputTimes, frequencies: inputFrequencies)
        
        let result = try! dataProcessor.scaledInFrequencyAndTime(information: inputInformation)
        assertFrequenciesAndTime(in: result, haveDurationOf: 2.0)
    }
    
    // MARK: Scaling Times and Frequencies
    func test_scaling_abbreviative() {
        dataProcessor.playingDuration = .short
        
        let inputFrequencies: [Double] = [1, 2, 3]
        let inputTimes = [0.0, 5, 10]
        
        let inputInformation = AudioInformation(relativeTimes: inputTimes, frequencies: inputFrequencies)
        
        let result = try! dataProcessor.scaledInFrequencyAndTime(information: inputInformation)
        assertFrequenciesAndTime(in: result, haveDurationOf: 2.0)
    }
    func test_scaling_longEnough() {
        dataProcessor.playingDuration = .recommended
        
        let inputFrequencies: [Double] = [1, 2, 3]
        let inputTimes = [0.0, 5, 10]
        
        let inputInformation = AudioInformation(relativeTimes: inputTimes, frequencies: inputFrequencies)
        
        let result = try! dataProcessor.scaledInFrequencyAndTime(information: inputInformation)
        assertFrequenciesAndTime(in: result, haveDurationOf: 3.0)
    }
    func test_scaling_10seconds() {
        dataProcessor.playingDuration = .exactly(.seconds(10))
        
        let inputFrequencies: [Double] = [1, 2, 3]
        let inputTimes = [0.0, 5, 10]
        
        let inputInformation = AudioInformation(relativeTimes: inputTimes, frequencies: inputFrequencies)
        
        let result = try! dataProcessor.scaledInFrequencyAndTime(information: inputInformation)
        assertFrequenciesAndTime(in: result, haveDurationOf: 10.0)
    }
    func test_scaling_veryLong() {
        dataProcessor.playingDuration = .long
        
        let inputFrequencies: [Double] = [1, 2, 3]
        let inputTimes = [0.0, 5, 10]
        
        let inputInformation = AudioInformation(relativeTimes: inputTimes, frequencies: inputFrequencies)
        
        let result = try! dataProcessor.scaledInFrequencyAndTime(information: inputInformation)
        assertFrequenciesAndTime(in: result, haveDurationOf: 20.0)
    }
    
    // MARK: Caping at maximum Frequencies
    func test_scaling_capingAtMaximum_abbreviative() {
        dataProcessor.playingDuration = .short
        
        var inputFrequencies: [Double] = []
        var inputTimes: [TimeInterval] = []
        for index in 0...200 {
            inputFrequencies.append(Double(index))
            inputTimes.append(TimeInterval(index) / 10.0)
        }
        
        let inputInformation = AudioInformation(relativeTimes: inputTimes, frequencies: inputFrequencies)
        
        let result = try! dataProcessor.scaledInFrequencyAndTime(information: inputInformation)
        XCTAssertEqual(result.count, 51)
        // For .abbreviative, maximum duration is 3
        assertFrequenciesAndTime(in: result, haveDurationOf: 3.0)
    }
    func test_scaling_capingAtMaximum_longEnough() {
        dataProcessor.playingDuration = .recommended
        
        var inputFrequencies: [Double] = []
        var inputTimes: [TimeInterval] = []
        for index in 0...2000 {
            inputFrequencies.append(Double(index))
            inputTimes.append(TimeInterval(index) / 10.0)
        }
        
        let inputInformation = AudioInformation(relativeTimes: inputTimes, frequencies: inputFrequencies)
        
        let result = try! dataProcessor.scaledInFrequencyAndTime(information: inputInformation)
        XCTAssertEqual(result.count, 126)
        assertFrequenciesAndTime(in: result, haveDurationOf: 10)
    }
    func test_scaling_capingAtMaximum_10seconds() {
        dataProcessor.playingDuration = .exactly(.seconds(10))
        
        var inputFrequencies: [Double] = []
        var inputTimes: [TimeInterval] = []
        for index in 0...2000 {
            inputFrequencies.append(Double(index))
            inputTimes.append(TimeInterval(index) / 10.0)
        }
        
        let inputInformation = AudioInformation(relativeTimes: inputTimes, frequencies: inputFrequencies)
        
        let result = try! dataProcessor.scaledInFrequencyAndTime(information: inputInformation)
        XCTAssertEqual(result.count, 126)

        assertFrequenciesAndTime(in: result, haveDurationOf: 10)
    }
    func test_scaling_capingAtMaximum_whateverItTakes() {
        dataProcessor.playingDuration = .long
        
        var inputFrequencies: [Double] = []
        var inputTimes: [TimeInterval] = []
        for index in 0...2000 {
            inputFrequencies.append(Double(index))
            inputTimes.append(TimeInterval(index) / 10.0)
        }
        
        let inputInformation = AudioInformation(relativeTimes: inputTimes, frequencies: inputFrequencies)
        
        let result = try! dataProcessor.scaledInFrequencyAndTime(information: inputInformation)
        XCTAssertEqual(result.count, 251)

        assertFrequenciesAndTime(in: result, haveDurationOf: 20)
    }
    
    private func assertFrequenciesAndTime(in result: AudioInformation, haveDurationOf duration: TimeInterval) {
        XCTAssertEqual(result.first?.frequency ?? -1, dataProcessor.minFrequency, accuracy: 0.01)
        
        XCTAssertEqual(result.last?.frequency ?? -1, dataProcessor.maxFrequency, accuracy: 0.01)
        
        XCTAssertEqual(result.first?.relativeTime, 0)
        XCTAssertEqual(result.last?.relativeTime ?? -1, duration, accuracy: 0.11)
    }
    
    // MARK: Exeption Handling
    
    func test_edgeCase_emptyInput() {
        let inputFrequencies: [Double] = []
        let inputTimes: [Frequency] = []
        
        let inputInformation = AudioInformation(relativeTimes: inputTimes, frequencies: inputFrequencies)
        
        XCTAssertNoThrow(try dataProcessor.scaledInFrequencyAndTime(information: inputInformation))
    }
    func test_edgeCase_oneInput() {
        let inputFrequencies: [Double] = [10]
        let inputTimes: [Frequency] = [10]
        
        let inputInformation = AudioInformation(relativeTimes: inputTimes, frequencies: inputFrequencies)
        
        XCTAssertNoThrow(try dataProcessor.scaledInFrequencyAndTime(information: inputInformation))
    }
    
    func test_edgeCase_inputZero() {
        let inputFrequencies: [Double] = [0]
        let inputTimes: [Frequency] = [0]
        
        let inputInformation = AudioInformation(relativeTimes: inputTimes, frequencies: inputFrequencies)
        
        XCTAssertNoThrow(try dataProcessor.scaledInFrequencyAndTime(information: inputInformation))
    }
    
    func test_edgeCase_inputTimes_negative() {
        let inputFrequencies: [Double] = [0]
        let inputTimes: [Frequency] = [-10]
        
        let inputInformation = AudioInformation(relativeTimes: inputTimes, frequencies: inputFrequencies)
        
        XCTAssertNoThrow(try dataProcessor.scaledInFrequencyAndTime(information: inputInformation))
    }
    
    func test_edgeCase_noTimeDifference() {
        let inputFrequencies: [Double] = [1, 2]
        let inputTimes: [Frequency] = [10, 10]
        
        let inputInformation = AudioInformation(relativeTimes: inputTimes, frequencies: inputFrequencies)
        
        XCTAssertNoThrow(try dataProcessor.scaledInFrequencyAndTime(information: inputInformation))
    }
    
    func test_edgeCase_noFrequencyDifference() {
        let inputFrequencies: [Double] = [1, 1]
        let inputTimes: [Frequency] = [10, 20]
        
        let inputInformation = AudioInformation(relativeTimes: inputTimes, frequencies: inputFrequencies)
        
        XCTAssertNoThrow(try dataProcessor.scaledInFrequencyAndTime(information: inputInformation))
    }
    
    func test_edgeCase_sameDataMultipleTimes() {
        let inputFrequencies: [Double] = [1, 1, 2]
        let inputTimes: [Frequency] = [10, 10, 20]
        
        let inputInformation = AudioInformation(relativeTimes: inputTimes, frequencies: inputFrequencies)
        
        XCTAssertNoThrow(try dataProcessor.scaledInFrequencyAndTime(information: inputInformation))
    }
    
    func test_edgeCase_inputNotSorted() {
        let inputFrequencies: [Double] = [10, 5, 20]
        let inputTimes: [Frequency] = [10, 10, 20]
        
        let inputInformation = AudioInformation(relativeTimes: inputTimes, frequencies: inputFrequencies)
        do {
            let _ = try dataProcessor.scaledInFrequencyAndTime(information: inputInformation)
        } catch let error as SanityCheckError {
            XCTAssertEqual(error, SanityCheckError.negativeContentInTimestamps)
        } catch {
            XCTFail("Wrong type of error thrown.")
        }
    }
    
}
