//
//  NewSoundGenerator.swift
//  ChartAndSound
//
//  Created by Andreas Neusüß on 20.11.19.
//  Copyright © 2019 Anerma. All rights reserved.
//

import Foundation

typealias Samples = [Frequency]

extension Samples {
    /** Ends the samples on a zero and cuts off elements to achieve that.
        The samples are cut where the sign changes from negative to positive. A trailing 0 is also added to improve perceived audio quality.
     */
    mutating func postprocess() {

        let numberOfElementsToRemove = numberOfElementsToRemoveAtEnd()
        
        removeLast(numberOfElementsToRemove)
        append(0)
    }
    
    func numberOfElementsToRemoveAtEnd() -> Int {
        // Find the last transition from <0 to >= 0
        
        let latestNumberIsPositive = last! > 0
        if latestNumberIsPositive {
            // Next negative number is the right one
            let indexOfLatestNegative = indexOfLatestNegativeNumber() ?? index(before: endIndex)
            let numberOfElementsToRemove = index(before: endIndex) - indexOfLatestNegative
            return numberOfElementsToRemove
        } else {
            // Find latest tansition from -· to +·
            return numberOfElementsToRemovedUntilLatestChangeInSignTowardsPositive() ?? 0
        }
    }
    
    func indexOfLatestNegativeNumber() -> Int? {
        return lastIndex(where: { $0 < 0 })
    }

    /// Counts the number of elements that need to be removed in order to end on the latest contained negative number. One element after that number the sign is positive again.
    ///
    /// The result might be `nil` indicating that there is no change in sign and not enough elements can be removed.
    /// The result should not be interpreted using zero-based-counting, when the last 3 elements should be removed, start counting from 1 to 3.
    func numberOfElementsToRemovedUntilLatestChangeInSignTowardsPositive() -> Int? {
        var elementsToRemove: Int = 0
        
        for startAndEnd in zip(self, dropFirst()).reversed() {
            let prior = startAndEnd.0
            let after = startAndEnd.1
            
            elementsToRemove += 1
            if prior < 0 && after > 0 {
                return elementsToRemove
            }
        }
        
        return nil
    }
}

final class SoundGenerator {
    private let sampleRate: Double
    
    private var currentPhi: Float32 = 0
    
    init(sampleRate: Double) {
        self.sampleRate = sampleRate
    }
    
    func sweep(_ content: AudioInformation) -> [Float32] {
        
        let generator = FrequencyGenerator(sampleRate: sampleRate)
        generator.prepare(using: content)
        
        var buffer = [Float32]()
        buffer.reserveCapacity(generator.numberOfFrequencies)
        
        currentPhi = 0
        for frequency in generator {
            let sample = generateSample()
            let deltaPhi = updatedDeltaPhi(at: frequency)
            updateCurrentPhi(using: deltaPhi)
            
            buffer.append(sample)
        }
        
        // Avoid a clipping sound at the end
        buffer.postprocess()
        
        return buffer
    }

    private func generateSample() -> Float32 {
        0.5 * sin(currentPhi)
    }
    
    private func updatedDeltaPhi(at currentF: Float32) -> Float32 {
        2 * Float32.pi * currentF / Float32(sampleRate)
    }
    
    private func updateCurrentPhi(using delta: Float32) {
        currentPhi += delta
    }
}

class FrequencyGenerator: Sequence, IteratorProtocol {
    
    typealias Element = Frequency
    typealias Iterator = FrequencyGenerator
    
    private let sampleRate: Double
    
    private var frequencies: [Frequency] = []
    private var currentFrequencyIndex = 0
    
    var numberOfFrequencies: Int {
        frequencies.count
    }
    
    init(sampleRate: Double) {
        self.sampleRate = sampleRate
    }

    func prepare(using audioInformation: AudioInformation) {
        
        var frequencies = [Frequency]()
        // Reserve enough room so that the system does not need to shift the array content around to make more space.
        let totalNumberOfFrequencies = computeNumberOfNecssaryFrequencies(in: audioInformation)
        frequencies.reserveCapacity(totalNumberOfFrequencies)
        
        // For detemining durations:
        var segmentDurations = [Double]()
        
        // Compute the linear array of frequencies:
        for (start, end) in zip(audioInformation, audioInformation.dropFirst()) {
            let segmentDuration = end.relativeTime - start.relativeTime
            segmentDurations.append(segmentDuration)
            
            let f1 = start.frequency
            var currentF: Frequency = f1
            let f2 = end.frequency
            
            let segmentDeltaF = deltaFBetween(f1: f1, f2: f2, in: segmentDuration)
            
            let numberOfSamplesInSegment = Int(segmentDuration * sampleRate)
            
            for _ in 1...numberOfSamplesInSegment {
                currentF += segmentDeltaF
                frequencies.append(currentF)
            }
        }
        
        print("Min segment duration: \(segmentDurations.min()!)")
        print("max segment duration: \(segmentDurations.max()!)")
        self.frequencies = frequencies
    }
    
    private func computeNumberOfNecssaryFrequencies(in information: AudioInformation) -> Int {
        var numberOfComputedFrequencies = 0
        for (start, end) in zip(information, information.dropFirst()) {
            let segmentDuration = end.relativeTime - start.relativeTime
            let numberOfSamplesInSegment = Int(segmentDuration * sampleRate)
            numberOfComputedFrequencies += numberOfSamplesInSegment
        }
        
        return numberOfComputedFrequencies
    }
    
    private func deltaFBetween(f1: Float32, f2: Float32, in duration: Double) -> Float32 {
        (f2 - f1) / Float32(sampleRate * duration)
    }
    
    func next() -> Frequency? {
        guard currentFrequencyIndex < numberOfFrequencies else { return nil }
        defer { currentFrequencyIndex += 1 }
        
        return frequencies[currentFrequencyIndex]
    }
}
