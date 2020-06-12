//
//  ObjcInterface.swift
//  Audiograph
//
//  Created by Andreas Neusüß on 11.06.20.
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
import UIKit

@available(swift, obsoleted: 1.0) // Make it only available to Objective-C, not from Swift.
/**
 Provides API to create and play an Audiograph from a given set of points. Those points define given frequencies at given times.
 
 The duration of the audio can be spacified by setting `playingDuration`. Use `Audiograph.play(graphContent:)` to play the graph-content by passing an array of `CGPoint`, which is most likely your UI representation of the chart.
 
 When asked to play a graph-content all samples are computed at once. Please be careful about the duration that's specified so that memory and time consumption is kept low.
 
 The input is scaled to fit the desired duration and in between `minFrequency` and `maxFrequency`, which can be configured as well.
 */
@objc(ANNAudiograph) public class _Audiograph: NSObject {
    
    // MARK: - Objective-C Helper Types
    /// Specify the desired playing duration of the Audiograph.
    @objc(ANNPlayingDuration) public enum _PlayingDuration: Int {
        /// The shortest possible playing duration. It might drop some values in order to keep the sound abbreviative.
        case short
        /// The recommended length. Long enough to avoid the feeling of a rush.
        case recommended
        /// Longest possible playing duration. Might feel too long to the user but might be what you need.
        case long
    }
    
    /// Provides a set of smoothing options to control this step of prepreocessing before an Audiograph is played.
    @objc(ANNSmoothingOption) public enum _SmoothingOption: Int {
        /// Do not use any smoothing. The input data is not altered.
        case none
        /// Use the default smoothing setting.
        case `default`
    }
    
    // MARK: - Internal
    /// Internal, wrapped instance.
    internal var audiograph: Audiograph
    
    
    // MARK: - Public Properties
    
    /// The minimum frequency of the Audiograph. The lowest data point will be represented using this frequency.
    @objc public var minFrequency: Double {
        get { audiograph.minFrequency }
        set { audiograph.minFrequency = newValue }
    }
    /// The maximum frequency of the Audiograph. The largest data point will be represented using this frequency.
    @objc public var maxFrequency: Double {
        get { audiograph.maxFrequency }
        set { audiograph.maxFrequency = newValue }
    }
    
    /**
     This value can be used to control the final loudness volume.
     
     The final volume is computed by multiplying the default volume by that value. Default is `1.0` to apply standard loundness.
     
     It gets clamped between `0` and `2`.
     
     When running unit tests, for example, that value might be set to 0 in order to avoid unnecessary sound.
     */
    @objc public var volumeCorrectionFactor: Double {
        get { audiograph.volumeCorrectionFactor }
        set { audiograph.volumeCorrectionFactor = newValue }
    }
    
    /// If set, errors are printed to standard-output for the programmer to diagnose what went wrong. Those log statements can be suppressed as needed.
    @objc public var printDiagnostics: Bool = false {
        didSet {
            Logger.shared.isLoggingEnabled = printDiagnostics
        }
    }
    
    // MARK: - Public Init
    /// Creates an instance of Audiograph. The localizations passed in are used to improve the Audiograph experience.
    ///
    /// Use a custom accessibility action retrieved from `Audiograph.createCustomAccessibilityAction(using:)` or `Audiograph.createCustomAccessibilityAction(for:)` in your view. Those will play the Audiograph automatically.
    ///
    ///Audiograph can also be started by calling `Audiograph.play(graphContent:completion:)` passing in the points that are used to draw the UI.
    /// - Parameter localizations: Information to fill the parts that are not providable by the library such as interaction indication phrases.
    @objc public init(localizations: AudiographLocalizations) {
        audiograph = Audiograph(localizations: localizations)
    }
    
    // MARK: - Public Functions
    /**
    Playing duration of the input used for the next data points given.
    
    That duration serves as a guideline. It may be the case that points need to be dropped in order to achieve the requested duration.
    Also the duration might be enlarged in order to fit the data points into.
     
     **Note:** There's also `setExactPlayingDuration(_:)` for setting a custom duration value.
     - Parameter duration: The duration option chosen from an enum.
    */
    @objc public func setPlayingDuration(_ duration: _PlayingDuration) {
        switch duration {
        case .long:
            audiograph.playingDuration = .long
        case .recommended:
            audiograph.playingDuration = .recommended
        case .short:
            audiograph.playingDuration = .short
        }
    }
    
    /**
     Playing duration of the input used for the next data points given.
     
     In contrast to `setPlayingDuration(_:)`, this duration is used as exact value.
     
     **Note:** There's also `setPlayingDuration(_:)` for setting a pre-defined duration value.
     - Parameter duration: The duration in seconds.
     */
    @objc public func setExactPlayingDuration(_ duration: TimeInterval) {
        // We lose percision here.
        let durationInMicroseconds = Int(round(duration * 100))
        audiograph.playingDuration = .exactly(.microseconds(durationInMicroseconds))
    }
    
    /**
     Before playing the chart data as Audiograph, the input can be smoothened to give the user a sound with less volatility to large spikes.
     
     This step is useful in cases where the user rather is interested in a trend, not in every detail of the chart.
     The value is in between `[0, 1]` where `1` means the original data is used and `0` indicates maximal smoothness *(most likely a steady line)*.
     
     Image it as an moving average where values in the past matter less than the more recent ones.
     It's recommended to use the `.default` value but it can be turned off completely (`.none`) or fine-tuned to a custom value by calling `setExactSmoothing`.
     
     Before the Audiograph is produced, the library makes the curve smoother in order to produce an audio file that is not that volatile to large spikes. This step is useful in cases where the user rather is interested in a trend, not in every detail of the chart.
     
     **For example** this input graph:
     ```
     
                               _   /
                              / \_/
              _   _   _     _/
         -   / \_/ \_/ \   /
        / \_/           \_/
      _/
     /
     
     ```
     Will be sound more like this:
     ```
                             /
                           _/
                          /
          ____________   /
        _/            \_/
       /
      /
     /
     
     ```
     
     **Note:** There's also `setExactSmoothing(_:)` for setting a custom smoothing value.
     - Parameter option: The smoothening option chosen from an enum.
     */
    @objc public func setSmoothing(_ option: _SmoothingOption) {
        switch option {
        case .default:
            audiograph.smoothing = .default
        case .none:
            audiograph.smoothing = .none
        }
    }
    
    /// Configures a custom value for the smoothing processing step.
    ///
    /// In contrast to that, `setSmoothing(_:)` can be used to use one of the pre-defined options.
    /// - Parameter smoothing: The smoothing value that should be applied in an exact way. Must be between `[0, 1]` or will be clamped.
    @objc public func setExactSmoothing(_ smoothing: Double) {
        audiograph.smoothing = .custom(smoothing)
    }
    
    /// Creates an accessibility-action that can be applied to the chart-view. The action is configured with the given `AudiographLocalizations` and triggers the Audiograph when activated.
    ///
    /// Rather use `Audiograph.createCustomAccessibilityAction(forView:)` when you have direct access to the view.
    /// - Parameter dataProvider: The object that is able to deliver the chart data to the Audiograph-System.
    /// - Returns: An action that can be used to populate `accessibilityCustomActions` of a view.
    @objc public func createCustomAccessibilityAction(withProvider dataProvider: AudiographProvider) -> UIAccessibilityCustomAction {
        return audiograph.createCustomAccessibilityAction(using: dataProvider)
    }
    
    /// Creates an accessibility-action that can be applied to the view. The action is configured with the given `AudiographLocalizations` and triggers the Audiograph when activated.
    /// - Parameter chartView: The view that can deliver chart data and will receive the created accessibility action.
    /// - Returns: An action that can be used to populate `accessibilityCustomActions` of a view.
    @objc public func createCustomAccessibilityAction(forView chartView: AudiographPlayingView) -> UIAccessibilityCustomAction {
        audiograph.createCustomAccessibilityAction(for: chartView)
    }
    
    /// Call this function to compute and play the Audiograph for the given input. Computation of the data is done on a separate worker queue. Playback start immediately after processing data is done.
    /// - Parameters:
    ///   - graphContent: Call this function to compute and play the Audiograph for the given input. Playing starts immediately.
    ///   - completion: This block is executed when playing the Audiograph is completed. If done so successfully, `true` is passed into the completion block as argument. If any error occured or the playback was stopped, `false` is passed into.
    ///   Will be called on the main queue.
    @objc public func play(graphContent: [CGPoint], completion: ((_ success: Bool) -> Void)? = nil) {
        audiograph.play(graphContent: graphContent, completion: completion)
    }
    
    /// Stops the preprocessing or audio playback.
    @objc public func stop() {
        audiograph.stop()
    }
}
