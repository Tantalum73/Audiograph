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

public enum PlayingDuration {
    case short
    case recommended
    case long
    case exactly(DispatchTimeInterval)
}

public class Audiograph {
    public private (set) var minFrequency: Float32 = 150 {
        didSet {
            dataProcessor.minFrequency = minFrequency
        }
    }
    public private (set) var maxFrequency: Float32 = 2800 {
        didSet {
            dataProcessor.maxFrequency = maxFrequency
        }
    }
    
    public var playingDuration: PlayingDuration = .recommended {
        didSet {
            dataProcessor.playingDuration = playingDuration
        }
    }
    
    public var printDiagnostics = true
    
    private let synthesizer = Synthesizer()
    private let dataProcessor = DataProcessor()
    
    public init() {
        
    }
    
    public func play(graphContent: [CGPoint]) {
        //TODO: Do the computation in seperate queue.
        let audioInformation = AudioInformation(points: graphContent)
        
        guard sanityCheckPassing(for: audioInformation) else { return }
        
        do {
            
            let scaledAudioInformation = try dataProcessor.scaledInFrequencyAndTime(information: audioInformation)
            synthesizer.playScaledContent(scaledAudioInformation)
            
        } catch let error as SanityCheckError {
            printSanityCheckDiagnostics(for: error)
        } catch {
            assertionFailure("The sanity check threw an unknown error.")
        }
        
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
        
        //TODO: Fill with value
        let errorDescription: String
        switch error {
        case .inputEmpty:
            errorDescription = "The input was empty and thus no sound could be produced: please provide at least two elements."
        case .inputTooShort:
            errorDescription = "The input was too short and thus no sound could be produced: please provide at least two elements."
        case .negativeContentInTimestamps:
            errorDescription = "The X-values contain negative values. Currently the system can not handle negative X-values, yet."
        case .noMonotonousInput:
            errorDescription = "The X-values need to grow monotonous: values on the X-axis must be greater than or equal to the previous value. Otherwise you graph propably won't make sense either. Did you pass in the wrong data?"
        }
        
        let diagnosticsPrefix = "Audiograph: Input validation Failed."
        let diagnosticsString = diagnosticsPrefix + " " + errorDescription
        
        print(diagnosticsString)
        
    }
}
