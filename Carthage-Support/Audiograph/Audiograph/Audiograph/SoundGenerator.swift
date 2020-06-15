//
//  NewSoundGenerator.swift
//  ChartAndSound
//
//  Created by Andreas Neusüß on 20.11.19.
//  Copyright © 2019 Anerma. All rights reserved.
//

import Foundation

/// This class is responsible for translating `Audioinformation` into `Samples` that can then be used by the synthesizer to play the audio.
/// An internal frequency generator emits the frequencies used to generate samples.
///
/// Stoppable because the internal frequency generator is stoppable and won't produce any more frequencies after `Notification.Name.stopAudiograph` was received.
final class SoundGenerator {
    
    /// Final volume is set to a default level. This property can be changed to influence that loudness volume. The final volume is computed by multiplying the default volumen by that correction.
    var volumeCorrectionFactor: Double
    
    private let sampleRate: Double
    
    private var currentPhi: Sample = 0
    
    init(sampleRate: Double, volumeCorrectionFactor: Double) {
        self.sampleRate = sampleRate
        self.volumeCorrectionFactor = volumeCorrectionFactor
    }
    
    func sweep(_ content: AudioInformation) -> Samples {
        
        let generator = FrequencyGenerator(sampleRate: sampleRate)
        generator.prepare(using: content)
        
        var buffer = [Frequency]()
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

    private func generateSample() -> Sample {
        volumeCorrectionFactor * 0.5 * sin(currentPhi)
    }
    
    private func updatedDeltaPhi(at currentF: Frequency) -> Sample {
        2 * Sample.pi * currentF / Sample(sampleRate)
    }
    
    private func updateCurrentPhi(using delta: Sample) {
        currentPhi += delta
    }
}
