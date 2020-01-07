//
//  ChartViewDataProcessor.swift
//  iOS Example
//
//  Created by Andreas Neusüß on 05.01.20.
//  Copyright © 2020 Anerma. All rights reserved.
//

import UIKit

/**
 This class is responsible for pre-processing points in order to be presented by the chart view. It performs scaling points to fit a given frame and also is able to create a path that connects the scaled points. That graph can be directly used to draw the chart.
 */
final class ChartViewDataProcessor {
    typealias ScaledPoints = [CGPoint]
    
    /// Scales a given set of points to fit into the provided frame. The first point will be at location `(0|0)` and the last one at `(xMax|yMax)`.
    /// - Parameters:
    ///   - rawPoints: The points that should be scaled to fit the frame.
    ///   - frame: The frame the points should fit into.
    func scaledPoints(for rawPoints: [CGPoint], toFitInto frame: CGRect) -> ScaledPoints {
        scale(rawPoints, for: frame.size)
    }
    
    /// Creates a path from a given set of scaled points. That path connects the points and can be directly used to draw the chart if the scaled points match the layer's frame.
    /// - Parameter scaledPoints: The scaled points that should be connected to a path.
    func path(for scaledPoints: ScaledPoints) -> CGPath {
        let path = CGMutablePath()
        
        guard !scaledPoints.isEmpty else {
            assertionFailure("Chart View asked for a path with not enough elements.")
            return path
        }
        path.move(to: scaledPoints.last!)
        for point in scaledPoints.dropLast().reversed() {
            path.addLine(to: point)
        }
        
        return path
    }
    
    
    /// Scales given points so that their values fit the given frame exactly. The smallest x-value will be on position x=0, the smallest y-value will be on position y=0, the maximum x-value will be on x=size.width and the maximum y-value will be on y=size.height.
    ///
    /// - Parameters:
    ///   - points: The points that should be scaled.
    ///   - size: The size in which the points should fit into.
    /// - Returns: The points scaled in respect to their releative distance to one-another.
    private func scale(_ points: [CGPoint], for size: CGSize) -> [CGPoint] {
        let xValues = points.map( { $0.x } )
        let yValues = points.map( { $0.y } )
        
        let max = (x: xValues.max() ?? 0, y: yValues.max() ?? 0)
        let min = (x: xValues.min() ?? 0, y: yValues.min() ?? 0)
        
        let scaleFactorX: CGFloat
        if max.x - min.x == 0 {
            scaleFactorX = 0
        } else {
            scaleFactorX = size.width / (max.x - min.x)
        }
        
        let scaleFactorY: CGFloat
        if max.y - min.y == 0 {
            scaleFactorY = 0
        } else {
            scaleFactorY = size.height / (max.y - min.y)
        }
        
        let scaledPoints = points.map { point -> CGPoint in
            let scaledX = scaleFactorX * (point.x - min.x)
            let scaledY = scaleFactorY * (point.y - min.y)
            
            return CGPoint(x: scaledX, y: scaledY)
        }
        return scaledPoints
    }
}
