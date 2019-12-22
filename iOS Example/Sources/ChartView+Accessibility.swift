//
//  ChartView+Accessibility.swift
//  ChartAndSound
//
//  Created by Andreas Neusüß on 22.12.19.
//  Copyright © 2019 Anerma. All rights reserved.
//

import UIKit

// MARK: - Accessibility
extension ChartView {
    
    func setupAccessibility() {
        isAccessibilityElement = true
        shouldGroupAccessibilityChildren = true
        
        accessibilityTraits = .button
        accessibilityLabel = "Chart"
        accessibilityHint = "Double tap for audiograph."
    }
    
    override func accessibilityActivate() -> Bool {
        // Remove label and hint because they are read when activated. That intefers with audiograph.
        accessibilityLabel = ""
        accessibilityHint = ""
        
        playAudiograph()
        return true
    }
    
    override func accessibilityElementDidLoseFocus() {
        // Restore usual accessibility attributes.
        accessibilityLabel = "Chart"
        accessibilityHint = "Double tap for audiograph."
    }
    
    @objc private func playAudiograph() {
        audiograph.play(graphContent: points)
    }
}
