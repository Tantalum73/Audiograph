//
//  ChartView+Accessibility.swift
//  ChartAndSound
//
//  Created by Andreas Neusüß on 22.12.19.
//  Copyright © 2019 Anerma. All rights reserved.
//

import UIKit
import Audiograph

// MARK: - Accessibility

/*
 **************
 Solution using custom accessibility actions (user needs to chose the action to play Audiograph)
 **************
 */
extension ChartView: AudiographPlayable {
    var graphContent: [CGPoint] {
        scaledPoints
    }
    
    var accessibilityLabelText: String { "Chart, price over time" }
    var accessibilityHintText: String { "Actions for playing Audiograph available." }
    
    func setupAccessibility() {
        isAccessibilityElement = true
        shouldGroupAccessibilityChildren = true
        accessibilityLabel = accessibilityLabelText
        accessibilityHint = accessibilityHintText
        
        accessibilityCustomActions = [audiograph.createCustomAccessibilityAction(for: self)]
    }
}


/*
 **************
 Solution that plays Audiograph when activated (user only needs to double-tap the chart).
 **************
 */
//extension ChartView {
//
//    var accessibilityLabelText: String { "Chart, price over time" }
//    var accessibilityHintText: String { "Double tap for audiograph." }
//    var completionPhrase: String { NSLocalizedString("CHART_ACCESSIBILITY_AUDIOGRAPH_COMPLETION_PHREASE", comment: "This phrase is read when the Audiograph has completed describing the chart using audio. Should be something like 'complete'.") }
//
//    func setupAccessibility() {
//        isAccessibilityElement = true
//        shouldGroupAccessibilityChildren = true
//
//        accessibilityLabel = accessibilityLabelText
//        accessibilityHint = accessibilityHintText
//    }
//
//    override func accessibilityActivate() -> Bool {
//        // Remove label and hint because they are read when activated. That intefers with audiograph.
//        accessibilityLabel = nil
//        accessibilityHint = nil
//
//        playAudiograph()
//        return true
//    }
//
//    override func accessibilityElementDidLoseFocus() {
//        // Restore usual accessibility attributes.
//        accessibilityLabel = accessibilityLabelText
//        accessibilityHint = accessibilityHintText
//        audiograph.stop()
//    }
//
//    @objc private func playAudiograph() {
//        // Optional, read "complete" after playing Audiograph.
//        audiograph.completionIndicationUtterance = completionPhrase
//        audiograph.play(graphContent: scaledPoints)
//    }
//}
