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
    
}
