//
//  ObjcInterface.swift
//  Audiograph
//
//  Created by Andreas Neusüß on 11.06.20.
//  Copyright © 2019 Anerma. All rights reserved.

import Foundation
import UIKit

@objc(ANNPlayingDuration) public enum _PlayingDuration: Int {
    case short
    case recommended
    case long
}

@objc(ANNSmoothingOption) public enum _SmoothingOption: Int {
    case none
    case `default`
}


@available(swift 99.9.9) // Make it only available in Objective-C, not from Swift:
@objc(ANNAudiograph) public class _Audiograph: NSObject {
    var audiograph: Audiograph
    
    @objc public var minFrequency: Double {
        get { audiograph.minFrequency }
        set { audiograph.minFrequency = newValue }
    }
    
    @objc public var maxFrequency: Double {
        get { audiograph.maxFrequency }
        set { audiograph.maxFrequency = newValue }
    }
    
    @objc public var volumeCorrectionFactor: Double {
        get { audiograph.volumeCorrectionFactor }
        set { audiograph.volumeCorrectionFactor = newValue }
    }
    
    @objc public init(localizations: AudiographLocalizations) {
        audiograph = Audiograph(localizations: localizations)
    }
    
    // MARK: Playing Duration
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
    
    //TODO: in seconds
    @objc public func setExactPlayingDuration(_ duration: TimeInterval) {
        // We lose percision here.
        let durationInMicroseconds = Int(round(duration * 100))
        audiograph.playingDuration = .exactly(.microseconds(durationInMicroseconds))
    }
    
    // MARK: Smoothing Option
    @objc public func setSmoothing(_ option: _SmoothingOption) {
        switch option {
        case .default:
            audiograph.smoothing = .default
        case .none:
            audiograph.smoothing = .none
        }
    }
    
    @objc public func setExactSmoothing(_ smoothing: Double) {
        audiograph.smoothing = .custom(smoothing)
    }
}
