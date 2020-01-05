//
//  BaselineLayer.swift
//  iOS Example
//
//  Created by Andreas Neusüß on 05.01.20.
//  Copyright © 2020 Anerma. All rights reserved.
//

import UIKit

final class BaselineLayer: CALayer {
    var timingFunction = CAMediaTimingFunction(controlPoints: 0.64, 0, 0, 1)
    var animationDuration = 1.2
    
    private let shape = CAShapeLayer()
    private var latestBaselineYPosition: CGFloat = .zero
    
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
        isGeometryFlipped = true
        addSublayer(shape)
        backgroundColor = UIColor.clear.cgColor
        opacity = 1
        shape.strokeColor = UIColor.lightGray.cgColor
        shape.lineWidth = 1.0
        shape.lineJoin = .round
        shape.lineDashPattern = [2, 3]
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        
        let baselinePath = CGMutablePath()
        baselinePath.move(to: CGPoint(x: 0, y: latestBaselineYPosition))
        baselinePath.addLine(to: CGPoint(x: bounds.maxX, y: latestBaselineYPosition))
        shape.path = baselinePath
    }
    
    func transformPosition(to newPosition: CGPoint, animated: Bool) {
        latestBaselineYPosition = newPosition.y
        
        // In any case set the final values to the model layer without having an implicit animation:
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        if animated {
            shape.add(positionAnimation(to: newPosition), forKey: "BaselineAnimation")
        }
        shape.position = newPosition
        
        CATransaction.commit()
    }
    
    private func positionAnimation(to newPosition: CGPoint) -> CABasicAnimation {
        let baselineAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.position))
        baselineAnimation.fromValue = shape.presentation()?.position
        baselineAnimation.toValue = newPosition
        baselineAnimation.timingFunction = timingFunction
        baselineAnimation.duration = animationDuration
        return baselineAnimation
    }
}
