//
//  Audiograph.swift
//  ChartAndSound
//
//  Created by Andreas Neusüß on 26.10.19.
//  Copyright © 2019 Anerma. All rights reserved.
//

import Foundation
#if !os(macOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

/// Specify the desired playing duration of the Audiograph.
public enum PlayingDuration {
    /// The shortest possible playing duration. It might drop some values in order to keep the sound abbreviative.
    case short
    /// The recommended length. Long enough to avoid the feeling of a rush.
    case recommended
    /// Longest possible playing duration. Might feel too long to the user but might be what you need.
    case long
    /// Plays the Audiograph excatly as long as described.  Some data-points might need to be dropped in order to archieve that playing duration.
    case exactly(DispatchTimeInterval)
}

/**
 Provides API to create and play an Audiograph from a given set of points. Those points define given frequencies at given times.
 
 The duration of the audio can be spacified by setting `playingDuration`. Use `Audiograph.play(graphContent:)` to play the graph-content by passing an array of `CGPoint`, which is most likely your UI representation of the chart.
 
 When asked to play a graph-content all samples are computed at once. Please be careful about the duration that's specified so that memory and time consumption is kept low.
 
 The input is scaled to fit the desired duration and in between `minFrequency` and `maxFrequency`, which can be configured as well.
 */
public class Audiograph {
    /// The minimum frequency of the Audiograph. The lowest data point will be represented using this frequency.
    public var minFrequency: Float32 {
        get { dataProcessor.minFrequency }
        set { dataProcessor.minFrequency = newValue }
    }
    /// The maximum frequency of the Audiograph. The largest data point will be represented using this frequency.
    public var maxFrequency: Float32 {
        get { dataProcessor.maxFrequency }
        set { dataProcessor.maxFrequency = newValue }
    }
    
    /**
     Playing duration of the input used for the next data points given.
     
     That duration serves as a guideline. It may be the case that points need to be dropped in order to achieve the requested duration.
     Also the duration might be enlarged in order to fit the data points into.
     */
    public var playingDuration: PlayingDuration {
        get { dataProcessor.playingDuration }
        set { dataProcessor.playingDuration = newValue }
    }
    
    /**
     This value can be used to control the final loudness volume.
     
     The final volume is computed by multiplying the default volume by that value. Default is `1.0` to apply standard loundness.
     
     When running unit tests, for example, that value might be set to 0 in order to avoid unnecessary sound.
     */
    public var volumeCorrectionFactor: Float32 {
        get { synthesizer.volumeCorrectionFactor }
        set { synthesizer.volumeCorrectionFactor = newValue }
    }
    
    /// If set, errors are printed to standard-output for the programmer to diagnose what went wrong. Those log statements can be suppressed as needed.
    public var printDiagnostics = true
    
    /// Called when processing data is completed.
    var processingCompletion: (() -> Void)? {
        set {
            dataProcessor.completion = newValue
        }
        get { dataProcessor.completion }
    }
        
    private let synthesizer = Synthesizer()
    private let dataProcessor = DataProcessor()
    
    public init() {
        
    }
    
    /// Call this function to compute and play the Audiograph for the given input. Playing starts immediately.
    /// - Parameters:
    ///   - graphContent: Call this function to compute and play the Audiograph for the given input. Playing starts immediately.
    ///   - completion: This block is executed when playing the Audiograph is completed. If done so successfully, `true` is passed into the completion block as argument. If any error occured or the playback was stopped, `false` is passed into.
    public func play(graphContent: [CGPoint], completion: ((_ success: Bool) -> Void)? = nil) {
        //TODO: Do the computation in seperate queue.
        let audioInformation = AudioInformation(points: graphContent)
        
        guard sanityCheckPassing(for: audioInformation) else {
            completion?(false)
            return
        }
        
        do {
            
            let scaledAudioInformation = try dataProcessor.scaledInFrequencyAndTime(information: audioInformation)
            synthesizer.completion = completion
            synthesizer.playScaledContent(scaledAudioInformation)
            
        } catch let error as SanityCheckError {
            printSanityCheckDiagnostics(for: error)
            completion?(false)
        } catch {
            assertionFailure("The sanity check threw an unknown error.")
        }
        
    }
    
    public func stop() {
        // TODO: also stop processing when async processing is implemented.
        synthesizer.stop()
    }
    
    private func sanityCheckPassing(for information: AudioInformation) -> Bool {
        do {
            try dataProcessor.inputSanityCheck(for: information)
        } catch let error as SanityCheckError {
            printSanityCheckDiagnostics(for: error)
            return false
        } catch {
            assertionFailure("The sanity check threw an unknown error.")
            return false
        }
        
        return true
    }
    
    private func printSanityCheckDiagnostics(for error: SanityCheckError) {
        guard printDiagnostics else { return }
        
        let errorDescription: String
        switch error {
        case .inputEmpty:
            errorDescription = "The input was empty and thus no sound could be produced: please provide at least two elements."
        case .inputTooShort:
            errorDescription = "The input was too short and thus no sound could be produced: please provide at least two elements."
        case .negativeContentInTimestamps:
            errorDescription = "The X-values contain negative numbers. Currently the system can not handle negative X-values, yet."
        case .noMonotonousInput:
            errorDescription = "The X-values need to grow monotonous: values on the X-axis must be greater than or equal to the previous value. Otherwise your graph propably won't make sense either. Did you pass in the wrong data?"
        }
        
        let diagnosticsPrefix = "Audiograph: Input computation failed."
        let diagnosticsString = diagnosticsPrefix + " " + errorDescription
        
        print(diagnosticsString)
        
    }
}
