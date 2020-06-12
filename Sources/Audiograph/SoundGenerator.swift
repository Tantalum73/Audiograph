//
//  SoundGenerator.swift
//  Audiograph
//
//  Created by Andreas Neusüß on 20.11.19.
//
//  MIT License
//
//  Copyright (c) 2019 Andreas Neusüß
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
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
