//
//  FrequencyGenerator.swift
//  
//
//  Created by Andreas Neusüß on 26.12.19.
//

import Foundation

/// This class generates the frequencies from which samples are derived. After calling `.prepare(using:)` the generator has produced its result. Those frequencies can be retrieved by calling `.next()`.
final class FrequencyGenerator: Sequence, IteratorProtocol {
    
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
    
    private func deltaFBetween(f1: Frequency, f2: Frequency, in duration: Double) -> Frequency {
        (f2 - f1) / Frequency(sampleRate * duration)
    }
    
    func next() -> Frequency? {
        guard currentFrequencyIndex < numberOfFrequencies else { return nil }
        defer { currentFrequencyIndex += 1 }
        
        return frequencies[currentFrequencyIndex]
    }
}
