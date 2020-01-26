//
//  DataProcessor.swift
//  ChartAndSound
//
//  Created by Andreas Neusüß on 26.11.19.
//  Copyright © 2019 Anerma. All rights reserved.
//

import Foundation

final class DataProcessor {
    var minFrequency: Frequency = 150
    var maxFrequency: Frequency = 2600
    
    var playingDuration: PlayingDuration = .short
    
    var completion: (() -> Void)?
    
    private var maximumPlayingDuration: TimeInterval {
        switch playingDuration {
        case .short:
            return TimeInterval(dispatchTimeInterval: .seconds(2))
        case .recommended:
            return TimeInterval(dispatchTimeInterval: .seconds(10))
        case .exactly(let duration):
            return TimeInterval(dispatchTimeInterval: duration)
        case .long:
            return TimeInterval(dispatchTimeInterval: .seconds(20))
        }
    }
        
    private var currentRelativeTimes = [RelativeTime]()
    private var currentFrequencies = [Frequency]()
    
    func scaledInFrequencyAndTime(information: AudioInformation) throws -> AudioInformation {
        
        defer {
            completion?()
        }
        
        currentFrequencies = information.frequencies
        currentRelativeTimes = information.relativeTimes

        try scaleTimesInPlace(desiredDuration: requestedPlayingDuration())
        scaleCurrentFrequenciesInPlace()
        
        return AudioInformation(relativeTimes: currentRelativeTimes, frequencies: currentFrequencies)
    }
    
    func inputSanityCheck(for information: AudioInformation) throws {
        guard !information.isEmpty else {
            throw SanityCheckError.inputEmpty
        }
        guard information.relativeTimes.min() ?? -1 >= 0 else {
            throw SanityCheckError.negativeContentInTimestamps
        }
        guard information.count > 1 else {
            throw SanityCheckError.inputTooShort
        }
    }
   
    private func scaleTimesInPlace(desiredDuration: TimeInterval) throws {
        let duration = min(desiredDuration, maximumPlayingDuration)
        print("Setting desired duration to \(duration) instead of \(desiredDuration)")
        
        try performScalingInPlace(toFit: duration)
    }
    
    private func performScalingInPlace(toFit desiredDuration: TimeInterval) throws {
        // At this point the desired duration is already <= maximum duration
        
        print("Before scaling, duration is \(currentRelativeTimes.playingDuration())s")
        scaleCurrentTimesInPlace(toFit: desiredDuration)
        print("After scaling, duration is \(currentRelativeTimes.playingDuration())s")
        
        try enlargedAndScaledSoThatSegmentDurationIsLongEnoughInPlace(desiredDuration: desiredDuration)
    }
    
    private func enlargedAndScaledSoThatSegmentDurationIsLongEnoughInPlace(desiredDuration: TimeInterval) throws {

        if let neccessaryExtension = try currentPlayingDurationExtensionIfNeccessary(toMeet: desiredDuration) {
            let newDesiredDuration = desiredDuration + neccessaryExtension
            print("Duration of \(desiredDuration)s was too short to match minimum segment size.")
            print("Enlarging it to \(newDesiredDuration)s")
            
            // Trim if the neccessary duration would be too long:
            if newDesiredDuration > maximumPlayingDuration {
                let beforeCount = currentRelativeTimes.count
                removeElementsInPlace(level: 10)
                
                print("Removed \(beforeCount - currentRelativeTimes.count) elements from \(beforeCount)")
                
                try scaleTimesInPlace(desiredDuration: newDesiredDuration)
            }
        }
    }
    
    private func removeElementsInPlace(level: Int) {
        let intermediary = zip(currentRelativeTimes, currentFrequencies).enumerated().compactMap { (offset, element) -> (RelativeTime, Frequency)? in
            return offset % level == 0 ? nil : element
        }
        
        currentRelativeTimes = intermediary.map { $0.0 }
        currentFrequencies = intermediary.map { $0.1 }
    }
    
    private func scaleCurrentFrequenciesInPlace() {
        var maxContainedFrequency = currentFrequencies.max() ?? 0
        var minContainedFrequency = currentFrequencies.min() ?? 0
        
        if abs(maxContainedFrequency - minContainedFrequency) < 0.003 {
            print("⚠️ The data does not contain frequencies that are distinct enough from each other!")
            maxContainedFrequency = 1
            minContainedFrequency = 0
        }
        
        currentFrequencies = currentFrequencies.map { frequency -> Frequency in
            var newFrequency = (frequency - minContainedFrequency) * (maxFrequency - minFrequency) / (maxContainedFrequency - minContainedFrequency)
            newFrequency += minFrequency
            return newFrequency
        }
    }
    
    private func scaleCurrentTimesInPlace(toFit duration: TimeInterval) {
        var maxContainedRelativeTime = currentRelativeTimes.max() ?? 0
        var minContainedRelativeTime = currentRelativeTimes.min() ?? 0
        
        if abs(maxContainedRelativeTime - minContainedRelativeTime) < 0.003 {
            print("⚠️ The data does not contain timestamps that are distinct enough from each other!")
            maxContainedRelativeTime = 1
            minContainedRelativeTime = 0
        }
        
        currentRelativeTimes = currentRelativeTimes.map { relativeTime -> RelativeTime in
            
            return (relativeTime - minContainedRelativeTime) * (duration) / (maxContainedRelativeTime - minContainedRelativeTime)
        }
    }

    private func requestedPlayingDuration() -> TimeInterval {
        switch playingDuration {
        case .exactly(let duration):
            return TimeInterval(dispatchTimeInterval: duration)
        case .short:
            return TimeInterval(dispatchTimeInterval: .seconds(2))
        case .recommended:
            return TimeInterval(dispatchTimeInterval: .seconds(3))
        case .long:
            return maximumPlayingDuration - 0.1
        }
    }
    
    /// Checks if each segment plays long enough to hear (a minimum-playing-duration-threshold needs to be superceeded). If that is not the case, a suggestion of an extension is made.
    /// By applying that extenstion to the requested duration the requirement should be matched (xcept some rounding issues).
    /// - Parameter requestedDuaration: The duration the `currentRelativeTimes` should take, used to compute the difference needed to match the threshold.
    /// - Returns: A time interval that must be added to `requestedDuaration` or `nil` if no extension needs to be applied to match the threshold.
    private func currentPlayingDurationExtensionIfNeccessary(toMeet requestedDuaration: TimeInterval) throws -> TimeInterval? {
        // Between each segment there should be at least 0.025 seconds == 250ms to get a good result.
        let minimumPlayingSegmentDuration: TimeInterval = 0.025
        let comparisonThreshold: TimeInterval = 0.0001
        var suggestedPlayingDuration: TimeInterval = 0
        
        var minSegmentDurationForDiagnostics: TimeInterval = 10000
        for (start, end) in zip(currentRelativeTimes, currentRelativeTimes.dropFirst()) {
            let segmentDuration = end - start
            
            guard segmentDuration > 0 else { throw SanityCheckError.negativeContentInTimestamps }
            
            if segmentDuration + comparisonThreshold < minimumPlayingSegmentDuration {
                suggestedPlayingDuration += minimumPlayingSegmentDuration
            } else {
                suggestedPlayingDuration += segmentDuration
            }
            
            minSegmentDurationForDiagnostics = min(minSegmentDurationForDiagnostics, segmentDuration)
        }
        
        print("Minimum segment duration: \(minSegmentDurationForDiagnostics)")
        print("suggesting a playing duration of \(suggestedPlayingDuration), requested: \(requestedDuaration)")
        let difference = requestedDuaration - suggestedPlayingDuration
        return difference < 0 ? -difference : nil
    }
}

private extension Array where Element == RelativeTime {
    func playingDuration() -> TimeInterval {
        var duration: TimeInterval = 0
        for (start, end) in zip(self, dropFirst()) {
            let segmentDuration = end - start
            duration += segmentDuration
        }
        
        return duration
    }
}
