//
//  DataProcessor.swift
//  ChartAndSound
//
//  Created by Andreas Neusüß on 26.11.19.
//  Copyright © 2019 Anerma. All rights reserved.
//

import Foundation

/**
 This class is responsible for pre-processing chart data so that `AudioInformation` are produced, that are directly interpretable by the `Synthesizer`.
 
 By scaling the frequencies, the configurable `minFrequency` and `maxFrequency` is used. For scaling the time, a `playingDuration` can give suggestions to the playing duration. When scaling time, it is ensured that each chart segment (the line between two points) will have enough playback duration to per perceivable by the user.
 If that's not possible, the entire playback duration is increased until every segment is long enough.
 Eventually the entire duration would simply take too long. In this case, some graph points are dropped in order to fulfill the requirements.
 
 Stoppable by receiving `Notification.Name.stopAudiograph`. After that event no more frequencies will be produced.
 */
final class DataProcessor {
    var minFrequency: Frequency = 150
    var maxFrequency: Frequency = 2600
    
    var playingDuration: PlayingDuration = .recommended
    var smoothing: SmoothingOption = .default
    
    /// Executed when processing is completed.
    var completion: (() -> Void)?
    
    private var maximumPlayingDuration: TimeInterval {
        switch playingDuration {
        case .short:
            return TimeInterval(dispatchTimeInterval: .seconds(3))
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
    private var shouldStopComputation = false

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(stopNotificationReceived), name: .stopAudiograph, object: nil)
    }
    
    /// Sclaes the given `AudioInformation` so that the currently specified `playbackDuration` is met.
    ///
    /// The frequencies are scaled linearly betwee [`minFrequency`, `maxFrequency`]. For scaling the absolute timestamps of a frequency a more complicated heuristic is applied so that
    /// 1. Each segment (the time between two frequencies) is long enough to be distinguishable.
    /// 2. The entire playback duration does not superceed a maximum specified in `maximumPlayingDuration`.
    ///
    /// Stoppable by receiving `Notification.Name.stopAudiograph`. After that event no more frequencies will be produced.
    /// - Parameter information: The content that should be scaled.
    func scaledInFrequencyAndTime(information: AudioInformation) throws -> AudioInformation {
        shouldStopComputation = false
        
        defer {
            DispatchQueue.main.async {
                self.completion?()
                self.completion = nil
            }
        }
        currentFrequencies = information.frequencies
        currentRelativeTimes = information.relativeTimes
        
        applySmoothingIfRequested()
        try startScalingRelativeTimesIteratively(desiredDuration: requestedPlayingDuration())
        scaleCurrentFrequencies()
        
        return AudioInformation(relativeTimes: currentRelativeTimes, frequencies: currentFrequencies)
    }
    
    /// Ensures that the input contains valid data. A `SanityCheckError` is thrown otherwise.
    /// - Parameter information: The content that will be processed in the next step so it should be checked for sanity.
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
    
    @objc private func stopNotificationReceived() {
        shouldStopComputation = true
    }
    
    /// When the current `smoothing` is set, this function applies it to the `currentFrequencies`.
    private func applySmoothingIfRequested() {
        guard !shouldStopComputation else { return }
        
        let alpha: Double
        switch smoothing {
        case .default:
            alpha = 0.35
        case .custom(let value):
            alpha = max(min(value, 1), 0.0001)
        case .none:
            return
        }
        
        // Exponential moving average, more recent values are valued more than older data points:
        var output = currentFrequencies.first ?? 0
        currentFrequencies = currentFrequencies.map({ frequency -> Frequency in
            output += alpha * (frequency - output)
            return output
        })
    }
    
    /// **Starts** the scaling process of `currentRelativeTimes` into the specified `desiredDuration`. The parameter is only a suggestion as the final duration will be computed in progress.
    /// - Parameter desiredDuration: The duration that the entire playback should take. Clamped to `maximumPlayingDuration`.
    private func startScalingRelativeTimesIteratively(desiredDuration: TimeInterval) throws {
        guard !shouldStopComputation else { return }
        
        // 1. Boundary check for playing duration
        let duration = min(desiredDuration, maximumPlayingDuration)
        Logger.shared.log(message: "Setting desired duration to \(duration) instead of requested \(desiredDuration)")
        
        // 2. Scale into the desired duration
        scaleCurrentTimes(toFit: duration)
        if Logger.shared.isLoggingEnabled {
            let playingDuration = currentRelativeTimes.playingDuration()
            Logger.shared.log(message: "After scaling, duration is \(playingDuration)s")
        }
        
        // 3. Check if minimum segment-playing duration is not violated and iterate on playing duration if so
        try checkForMinimumSegmentDurationAndRestartIfNeeded(desiredDuration: duration)
    }
    
    /// Checks if the `currentRelativeTimes` contain only segments whose duration do not violate the minimum segment duration.
    /// - Parameter desiredDuration: The duration of the `currentRelativeTimes` so that it does not need to be computed again.
    /// - Throws: May throw if invalid data was passed set as `currentRelativeTimes`.
    private func checkForMinimumSegmentDurationAndRestartIfNeeded(desiredDuration: TimeInterval) throws {
        
        guard let necessaryExtension = try currentPlayingDurationExtensionIfNeccessary(toMeet: desiredDuration) else {
            // Scaling has worked fine, no extension needed.
            return
        }
        
        Logger.shared.log(message: "Duration of \(desiredDuration)s was too short to match minimum segment size.")
        let expandedDuration = desiredDuration + necessaryExtension
        Logger.shared.log(message: "Enlarging it to \(expandedDuration)s")
        
        // Boundary check:
        if expandedDuration > maximumPlayingDuration {
            // It's necessary to remove elements:
            
            let numberOfSamplesBeforeScaling = currentRelativeTimes.count
            reduceNumberOfElements(level: 2)
            
            Logger.shared.log(message: "Removed \(numberOfSamplesBeforeScaling - currentRelativeTimes.count) elements from \(numberOfSamplesBeforeScaling)")
        }
        
        // Try to scale again but now into the suggested/instrinsic duration:
        try startScalingRelativeTimesIteratively(desiredDuration: expandedDuration)
    }
    
    /// Removes elements from `currentRelativeTimes` and `currentFrequencies`. Call this method when the data do not fit into the maximum playing duration. Consider it as last resort as it decreases resolution of the output.
    /// - Parameter level: Determines how many elements should be removed. The bigger the more elements are deleted.
    private func reduceNumberOfElements(level: Int) {
        // Combine two (or `level`) data points to one, in both time and frequency.
        
        currentRelativeTimes = currentRelativeTimes.chunked(into: level).map{ $0.average() }
        currentFrequencies = currentFrequencies.chunked(into: level).map{ $0.average() }
    }
    
    private func scaleCurrentFrequencies() {
        var maxContainedFrequency = currentFrequencies.max() ?? 0
        var minContainedFrequency = currentFrequencies.min() ?? 0
        
        if abs(maxContainedFrequency - minContainedFrequency) < 0.003 {
            Logger.shared.log(message: "⚠️ The data does not contain frequencies that are distinct enough from each other!")
            
            maxContainedFrequency = 1
            minContainedFrequency = 0
        }
        
        currentFrequencies = currentFrequencies.map { frequency -> Frequency in
            var newFrequency = (frequency - minContainedFrequency) * (maxFrequency - minFrequency) / (maxContainedFrequency - minContainedFrequency)
            newFrequency += minFrequency
            return newFrequency
        }
    }
    
    private func scaleCurrentTimes(toFit duration: TimeInterval) {
        var maxContainedRelativeTime = currentRelativeTimes.max() ?? 0
        var minContainedRelativeTime = currentRelativeTimes.min() ?? 0
        
        if abs(maxContainedRelativeTime - minContainedRelativeTime) < 0.003 {
            Logger.shared.log(message: "⚠️ The data does not contain timestamps that are distinct enough from each other!")
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
    ///
    /// By applying that extenstion to the requested duration the requirement should be closer to a match.
    ///
    /// When a segment violates the minimum playing duration, it is guaranteed that at least a small amount of time is returned to prevent infinite recursion by adding a too-small value to the entire duration.
    /// - Parameter requestedDuaration: The duration the `currentRelativeTimes` should take, used to compute the difference needed to match the threshold.
    /// - Returns: A time interval that must be added to `requestedDuaration` or `nil` if no extension needs to be applied to match the threshold.
    func currentPlayingDurationExtensionIfNeccessary(toMeet requestedDuaration: TimeInterval) throws -> TimeInterval? {
        /// Between each segment there should be at least 0.035 seconds == 35ms to get a good result.
        let minimumSegmentDuration: TimeInterval = 0.035
        
        /// Minimum enlargement produced by this function:
        let minimalNecessaryEnlargement: TimeInterval = 0.03
        
        /// Used for comparing float values
        let comparisonPercision: TimeInterval = 0.005
        
        /// Stores result of this function.
        var suggestedPlayingDuration: TimeInterval = 0
        
        /// For diagnostics, the shortest time interval is stored.
        var minSegmentDurationForDiagnostics: TimeInterval = 10000
        
        
        for (start, end) in zip(currentRelativeTimes, currentRelativeTimes.dropFirst()) {
            let segmentDuration = end - start
            
            guard segmentDuration > 0 else { throw SanityCheckError.negativeContentInTimestamps }
            
            if segmentDuration + comparisonPercision < minimumSegmentDuration {
                suggestedPlayingDuration += minimumSegmentDuration
            } else {
                suggestedPlayingDuration += segmentDuration
            }
            
            minSegmentDurationForDiagnostics = min(minSegmentDurationForDiagnostics, segmentDuration)
        }
        
        Logger.shared.log(message: "Minimum segment duration: \(minSegmentDurationForDiagnostics)")
        Logger.shared.log(message: "suggesting a playing duration of \(suggestedPlayingDuration), requested: \(requestedDuaration)")
        let difference = suggestedPlayingDuration - requestedDuaration
        
        return difference > 0 ?
            Swift.max(difference, minimalNecessaryEnlargement)
            :
            nil
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

private extension Array where Element: FloatingPoint {
    
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
    
    func average() -> Element {
        guard !isEmpty else { return 0 }
        let sum = reduce(0, +)
        return sum / Element(count)
    }
}
