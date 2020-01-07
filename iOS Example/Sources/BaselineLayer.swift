//
//  BaselineLayer.swift
//  iOS Example
//
//  Created by Andreas Neusüß on 05.01.20.
//  Copyright © 2020 Anerma. All rights reserved.
//

import UIKit

final class BaselineLayer: CAShapeLayer {
    var timingFunction = CAMediaTimingFunction(controlPoints: 0.64, 0, 0, 1)
    var animationDuration = 1.2
        
    override init(layer: Any) {
        super.init(layer: layer)
        setupLayer()
    }
    override init() {
        super.init()
        setupLayer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Only use this layer as a part of `ChartView`.")
    }
    
    private func setupLayer() {
        backgroundColor = UIColor.clear.cgColor
        opacity = 1
        strokeColor = UIColor.lightGray.cgColor
        lineWidth = 1.0
        lineJoin = .round
        lineDashPattern = [2, 3]
        contentsScale = UIScreen.main.scale
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        
        let baselinePath = CGMutablePath()
        baselinePath.move(to: bounds.origin)
        baselinePath.addLine(to: CGPoint(x: bounds.maxX, y: bounds.origin.y))
        path = baselinePath
    }
    
    func transformPosition(to newPosition: CGPoint, animated: Bool) {
        
        if animated {
            add(positionAnimation(to: newPosition), forKey: "BaselineAnimation")
        }
        
        // In any case set the final values to the model layer without having an implicit animation:
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        position = newPosition
        
        CATransaction.commit()
    }
    
    private func positionAnimation(to newPosition: CGPoint) -> CABasicAnimation {
        let baselineAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.position))
        baselineAnimation.fromValue = presentation()?.position
        baselineAnimation.toValue = newPosition
        baselineAnimation.timingFunction = timingFunction
        baselineAnimation.duration = animationDuration
        return baselineAnimation
    }
}
