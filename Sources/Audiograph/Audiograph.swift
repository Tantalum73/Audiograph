//
//  Audiograph.swift
//  ChartAndSound
//
//  Created by Andreas Neusüß on 26.10.19.
//  Copyright © 2019 Anerma. All rights reserved.
//

import Foundation
import UIKit

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

/// Indicates that this view is capable of playing an Audiograph. If so, it must provide the right data to the system but stopping the playback when the view loses focus is done automatically.
public protocol AudiographPlayable: UIView, AudiographProvider {
}

/// The conformant object can provide the correct set of chart data to the Audiograph.
public protocol AudiographProvider: AnyObject {
    /// The points that will participate in the Audiograph. They most likely will be the same as used to draw the chart UI.
    var graphContent: [CGPoint] { get }
}

/// A wrapper around localized strings used during discovery and playback of the chart.
///
/// Because Swift-PM projects can not contain .strings-files at the time of implementation, the phrase needs to be localized by the containing app.
public struct AudiographLocalizations {
    /// A phrase that is read when the Audiograph completes. Should say something like "complete".
    let completionIndicationUtterance: String
    /// This title is used as custom accessibility action title. Should say something like "Play Audiograph".
    let accessibilityIndicationTitle: String
    
    public init(completionIndicationUtterance: String, accessibilityIndicationTitle: String) {
        self.completionIndicationUtterance = completionIndicationUtterance
        self.accessibilityIndicationTitle = accessibilityIndicationTitle
    }
    
    public static let defaultEnglish = AudiographLocalizations(completionIndicationUtterance: "Complete", accessibilityIndicationTitle: "Play Audiograph")
}

/**
 Provides API to create and play an Audiograph from a given set of points. Those points define given frequencies at given times.
 
 The duration of the audio can be spacified by setting `playingDuration`. Use `Audiograph.play(graphContent:)` to play the graph-content by passing an array of `CGPoint`, which is most likely your UI representation of the chart.
 
 When asked to play a graph-content all samples are computed at once. Please be careful about the duration that's specified so that memory and time consumption is kept low.
 
 The input is scaled to fit the desired duration and in between `minFrequency` and `maxFrequency`, which can be configured as well.
 */
public final class Audiograph {
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
     
     It gets clamped between `0` and `2`.
     
     When running unit tests, for example, that value might be set to 0 in order to avoid unnecessary sound.
     */
    public var volumeCorrectionFactor: Float32 {
        get { synthesizer.volumeCorrectionFactor }
        set { synthesizer.volumeCorrectionFactor = max(min(newValue, 2), 0) }
    }
    
    /// If set, errors are printed to standard-output for the programmer to diagnose what went wrong. Those log statements can be suppressed as needed.
    public var printDiagnostics = true {
        didSet {
            Logger.shared.loggingEnabled = printDiagnostics
        }
    }
    
    /// Called when processing data is completed. Will be called on the main queue.
    var processingCompletion: (() -> Void)? {
        set {
            dataProcessor.completion = newValue
        }
        get { dataProcessor.completion }
    }
        
    private let preprocessingQueue = DispatchQueue(label: "de.anerma.Audiograph.PreprocessingQueue", qos: .userInteractive, attributes: [], autoreleaseFrequency: .inherit, target: .global())
    private let synthesizer = Synthesizer()
    private let dataProcessor = DataProcessor()
    private let localizationConfigurations: AudiographLocalizations
    
    private weak var chartView: AudiographPlayable?
    private weak var chartDataProvider: AudiographProvider?

    
    /// Creates an instance of Audiograph. The localizations passed in are used to improve the Audiograph experience.
    ///
    /// Use a custom accessibility action retrieved from `Audiograph.createCustomAccessibilityAction(using:)` or `Audiograph.createCustomAccessibilityAction(for:)` in your view. This will play the Audiograph automatically.
    ///
    ///Audiograph can also be started by calling `Audiograph.play(graphContent:completion:)` passing in the points that are used to draw the UI.
    /// - Parameter localizations: <#localizations description#>
    public init(localizations: AudiographLocalizations) {
        self.localizationConfigurations = localizations
        synthesizer.completionIndicationString = localizations.completionIndicationUtterance
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    // MARK: - Public Functions
    public func createCustomAccessibilityAction(using dataProvider: AudiographProvider) -> UIAccessibilityCustomAction {
        chartDataProvider = dataProvider
        let title = localizationConfigurations.accessibilityIndicationTitle
        
        return UIAccessibilityCustomAction(name: title, target: self, selector: #selector(playAudiographUsingDataProvider))
    }
    
    public func createCustomAccessibilityAction(for chartView: AudiographPlayable) -> UIAccessibilityCustomAction {
        self.chartView = chartView
        return createCustomAccessibilityAction(using: chartView)
    }
    
    /// Call this function to compute and play the Audiograph for the given input. Computation of the data is done on a separate worker queue. Playback start immediately after processing data is done.
    /// - Parameters:
    ///   - graphContent: Call this function to compute and play the Audiograph for the given input. Playing starts immediately.
    ///   - completion: This block is executed when playing the Audiograph is completed. If done so successfully, `true` is passed into the completion block as argument. If any error occured or the playback was stopped, `false` is passed into.
    ///   Will be called on the main queue.
    @objc public func play(graphContent: [CGPoint], completion: ((_ success: Bool) -> Void)? = nil) {
        
        preprocessingQueue.async {
            
            let audioInformation = AudioInformation(points: graphContent)
            
            guard self.sanityCheckPassing(for: audioInformation) else {
                completion?(false)
                return
            }
            
            do {
                
                let scaledAudioInformation = try self.dataProcessor.scaledInFrequencyAndTime(information: audioInformation)
                self.synthesizer.completion = completion
                
                self.synthesizer.playScaledContent(scaledAudioInformation)
                
            } catch let error as SanityCheckError {
                self.printSanityCheckDiagnostics(for: error)
                completion?(false)
            } catch {
                assertionFailure("The sanity check threw an unknown error.")
            }
            
        }
    }
    
    public func stop() {
        NotificationCenter.default.post(name: .stopAudiograph, object: nil)
    }
    
    // MARK: - Private Configurations
    
    /// Plays the Audiograph using the data points presented by the current `chartDataProvider`.
    @objc private func playAudiographUsingDataProvider() {
        guard let provider = chartDataProvider,
            !provider.graphContent.isEmpty else { return }
        
        play(graphContent: provider.graphContent)
    }
    
    /// Adds a receiver to the notification that changes focus of the accessibility element. When the current `chartView` loses focus playing the Audiograph is stopped.
    /// Only works when `chartView` is set to the correct view.
    private func setupLoseFocusNotificationObservation() {
        if #available(iOS 9.0, *) {
            NotificationCenter.default.addObserver(forName: UIAccessibility.elementFocusedNotification, object: nil, queue: nil) { [weak self] notification in
                
                guard let chartView = self?.chartView,
                    let viewThatLostFocus =
                    notification.userInfo?[UIAccessibility.unfocusedElementUserInfoKey] as? UIView,
                    viewThatLostFocus === chartView else { return }
                self?.stop()
            }
        }
    }
    
    
    // MARK: - Sanity Checking
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
