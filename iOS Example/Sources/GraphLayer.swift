//
//  GraphLayer.swift
//  iOS Example
//
//  Created by Andreas Neusüß on 05.01.20.
//  Copyright © 2020 Anerma. All rights reserved.
//

import UIKit

final class GraphLayer: CAShapeLayer {
    var timingFunction = CAMediaTimingFunction(controlPoints: 0.64, 0, 0, 1)
    var animationDuration = 1.2
    var graphColor: UIColor = .blue {
        didSet {
            strokeColor = graphColor.cgColor
        }
    }
    
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
        fillColor = UIColor.clear.cgColor
        lineWidth = 1
        lineJoin = .bevel
    }
    
    func transform(towards newPath: CGPath, animated: Bool) {
        
        // In any case set the final values to the model layer without having an implicit animation:
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        if animated {
            add(pathAnimatio(towards: newPath), forKey: "PathAnimation")
        }
        path = newPath
        
        CATransaction.commit()
    }
    
    private func pathAnimatio(towards newPath: CGPath) -> CABasicAnimation {
        let pathAnimation = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.path))
        pathAnimation.fromValue = presentation()?.path
        pathAnimation.toValue = newPath
        pathAnimation.duration = animationDuration
        pathAnimation.timingFunction = timingFunction
        
        return pathAnimation
    }
}
