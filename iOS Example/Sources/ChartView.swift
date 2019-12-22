//
//  ChartView.swift
//  ChartTest1
//
//  Created by Andreas Neusüß on 09.05.19.
//  Copyright © 2019 Anerma. All rights reserved.
//

import UIKit
import Audiograph

/// Defines methods to inform the viewController about interactions.
protocol ChartViewDelegate: AnyObject {
    
    /// The user interacts with the chart either by starting the gesture or moving the finger. Should be used to update the current-price-label using the element at the given index.
    /// The gesture is continueing until `hightlightDidEnd` is called.
    ///
    /// - Parameter elementAtIndex: The index that is currently highlighted.
    func highlightDidChanged(to elementAtIndex: Int)
    /// Indicates that the user has lifted their thumb. The UI can be restored to the initial state.
    func hightlightDidEnd()
}

/// Responsible for drawing a chart in the entire view's bounds. New points are passed in via `ChartView.transform(to:)` where the points are scaled accordingly and the chart is morped to display the new graph.
/// During interactions, the `delegate` will be informed about the currently selected element.
/// Changing the chart's color is possible by setting `chartColor` (animated).
final class ChartView: UIView {
    
    weak var delegate: ChartViewDelegate?
    
    /// Responsible for playing audiograph. Must be held in memory.
    let audiograph = Audiograph()
    
    /// The color of the graph. Changes will be animated.
    var chartColor: UIColor = .red {
        didSet {
            graphLayer.strokeColor = chartColor.cgColor
        }
    }

    /// The raw points that were added to the chart before scaling. Might be used in the future to accomodate for changing bounds.
    var points = [CGPoint]()
    
    /// Stores the scaled points that exactly fit whithin the view's bounds. Also updates the `touchesMovedThreshold` when set.
    private var scaledPoints = [CGPoint]() {
        didSet {
            // Update the threshold for moving the finger
            if scaledPoints.count > 1 {
                touchesMovedThreshold = abs(scaledPoints[0].x - scaledPoints[1].x) / 4
            }
        }
    }
    
    /// Layer that indicates the selected element. Starts with opacity of 0.
    private var touchindicatorLayer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor.lightGray.cgColor
        layer.opacity = 0
        return layer
    }()
    
    /// This threshold defines the numer of points the user's finger has to move until a new element can be highlighted. Part of an optimization where a new nearest-to-touch-point is not calculated on every update of the gesture's location. The finger must be moved more than this threshold in order to compute a nearest point again. Should be about 1/4 to 1/3 of the distance bewteen two data points.
    private var touchesMovedThreshold: CGFloat = 10
    
    /// Last location of user's gesture. Used to avoid re-calculations.
    private var lastTouchLocation: CGPoint? = nil
    
    /// The currently selected element or `nil` if nothing is selected.
    private var selectedElement: (point: CGPoint, indexInData: Int)?
    
    /// The layer that highlights the baseline.
    private let baselineLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.backgroundColor = UIColor.clear.cgColor
        layer.name = "BaselineOfGraph"
        layer.opacity = 1
        layer.strokeColor = UIColor.lightGray.cgColor
        layer.lineWidth = 1.0
        layer.lineJoin = .round
        layer.lineDashPattern = [2, 3]
        return layer
    }()

    /// Layer that draws the graph.
    private let graphLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.name = "GraphLayer"
        layer.strokeColor = UIColor.red.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 1
        layer.lineJoin = .bevel
        layer.isGeometryFlipped = true
        
        return layer
    }()
    
    private let timingFunction = CAMediaTimingFunction(controlPoints: 0.64, 0, 0, 1)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViewHierarchy()
        setupAccessibility()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViewHierarchy()
        setupAccessibility()
    }
    
    private func setupViewHierarchy() {
        layer.addSublayer(graphLayer)
        layer.addSublayer(touchindicatorLayer)
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        graphLayer.frame = bounds
        touchindicatorLayer.frame = CGRect(origin: touchindicatorLayer.frame.origin, size: CGSize(width: 2.0, height: bounds.height))
        
        // Set the width and the new positions of baseline layer
        updateBaselineLayer()
    }
    
    /// Updates the frame and the path of the baseline layer. Will be set to y-position of leftmost point.
    private func updateBaselineLayer() {
        baselineLayer.removeFromSuperlayer()
        if let leftmostPoint = scaledPoints.last {
            baselineLayer.frame = CGRect(x: 0, y: leftmostPoint.y, width: bounds.width, height: 2.0)
        } else {
            baselineLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 2.0)
        }
        let baselinePath = CGMutablePath()
        baselinePath.move(to: CGPoint(x: 0, y: baselineLayer.bounds.midY))
        baselinePath.addLine(to: CGPoint(x: baselineLayer.bounds.maxX, y: baselineLayer.bounds.midY))
        baselineLayer.path = baselinePath
        
        graphLayer.addSublayer(baselineLayer)
    }
    
    
    /// Adds random points of a given amount to the graph.
    ///
    /// - Parameter newAmount: The number of random points.
    func updateRandomPoints(to newAmount: Int) {
        let newRandomPoints = randomPoints(amount: newAmount, in: 0...200)
        transform(to: newRandomPoints)
    }

    
    /// Draws a graph consisting of `newPoints` in an animated way.
    ///
    /// Drawing consists of three steps:
    /// 1. Scaling the points to fit the view's frame
    /// 2. Drawing a path between the points, starting on the right.
    /// 3. Animate the transition to the new graph and update baseline position.
    ///
    /// - Parameter newPoints: The new points the graph view should display.
    func transform(to newPoints: [CGPoint]) {
        guard newPoints.count > 0 else { return }
        
        let newPath = CGMutablePath()
        let scaledPoints = scale(newPoints, for: frame.size).reversed()
        
        newPath.move(to: scaledPoints.first!)
        for point in scaledPoints.dropFirst() {
            newPath.addLine(to: point)
        }
        
        let newBaselinePosition = CGPoint(x: baselineLayer.position.x, y: scaledPoints.last!.y)
        
        let pathAnimation = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.path))
        pathAnimation.fromValue = graphLayer.presentation()?.path
        pathAnimation.toValue = newPath
        pathAnimation.duration = 1.2
        pathAnimation.timingFunction = timingFunction
        
        let baselineAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.position))
        baselineAnimation.fromValue = baselineLayer.presentation()?.position
        baselineAnimation.toValue = newBaselinePosition
        baselineAnimation.timingFunction = timingFunction
        baselineAnimation.duration = 1.2
        
        graphLayer.add(pathAnimation, forKey: "PathAnimation")
        baselineLayer.add(baselineAnimation, forKey: "BaselineAnimation")
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        baselineLayer.position = newBaselinePosition
        graphLayer.path = newPath
        CATransaction.commit()
        
        points = newPoints
        self.scaledPoints = Array(scaledPoints)
    }
    
    
    /// Generates random points with a given amount in a given range. The result is sorted by the x-value of the points.
    ///
    /// - Parameters:
    ///   - amount: The number of random points there should be.
    ///   - range: The range in between which the random points should be.
    /// - Returns: Random points of a given amount. Sorted by their x-value.
    private func randomPoints(amount: Int, in range: ClosedRange<Int>) -> [CGPoint] {
        var random = [CGPoint]()
        for _ in 1...amount {
            let randomY = range.randomElement()!
            let randomX = range.randomElement()!
            let randomPoint = CGPoint(x: randomX, y: randomY)
            random.append(randomPoint)
        }
        return random.sorted(by: { $0.x < $1.x })
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
    
    // MARK: - Touch handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard !points.isEmpty, !scaledPoints.isEmpty else { return }
        guard let location = touches.first?.location(in: self) else { return }
        
        // Store where the finger hit the screen to calculate relative movement.
        lastTouchLocation = location
        
        guard let selected = pointNextTo(touch: location) else { return }
        self.selectedElement = selected
        
        showSelectedPointHandle()
        moveSelectedPointHandle()
        
        delegate?.highlightDidChanged(to: selected.indexInData)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let location = touches.first?.location(in: self) else { return }
        
        if abs((lastTouchLocation?.x ?? CGFloat.greatestFiniteMagnitude) - location.x) < touchesMovedThreshold {
            //Do not perform the calculations and stop here because the user's finger has not moved a significant deistance.
            return
        }
        guard let selected = pointNextTo(touch: location) else { return }
        
        // Move the handle, store new data and call delegate functions if changed.
        if selectedElement?.indexInData != selected.indexInData {
            selectedElement = selected
            
            moveSelectedPointHandle()
            delegate?.highlightDidChanged(to: selected.indexInData)
            // Safe this location to enforce minimum moved distance
            lastTouchLocation = location
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        // Bookkeeping and removing the highlight indicator.
        selectedElement = nil
        lastTouchLocation = nil
        hideSelectedPointHandle()
        delegate?.hightlightDidEnd()
    }
    
    
    /// Computes the point the is next to the given touch location. `O(n)` but tries to iterate only until the nearest point is found but avoid calling this function too often.
    ///
    /// - Parameter touch: The location of the touch.
    /// - Returns: The point that is closest to the users interaction and its index in the `scaledPoints` array.
    private func pointNextTo(touch: CGPoint) -> (point: CGPoint, indexInData: Int)? {
        guard !points.isEmpty, !scaledPoints.isEmpty else { return nil }
        
        
        var pointNextToTouchLocation: CGPoint = .zero
        var bestDistancePointToLocationOfTouch: CGFloat?
        var indexOfFoundPoint: Int = 0
        
        for (index, displayedPoint) in scaledPoints.enumerated() {
            let distance = abs(displayedPoint.x - touch.x)
            
            if bestDistancePointToLocationOfTouch != nil && distance > bestDistancePointToLocationOfTouch! {
                // scaledPoints is sorted regarding their x value. So a local minimum is also a global minimum.
                // We can break the loop when a minimum was found (bestDistancePointToLocationOfTouch != nil) and the next distance is greater than this.
                break
            }
            if distance < bestDistancePointToLocationOfTouch ?? .greatestFiniteMagnitude {
                bestDistancePointToLocationOfTouch = distance
                pointNextToTouchLocation = displayedPoint
                indexOfFoundPoint = index
            }
        }
        
        let indexInModelOrder = scaledPoints.count - 1 - indexOfFoundPoint
        return (point: pointNextToTouchLocation, indexInData: indexInModelOrder)
    }
    
    /// Shows the highlight indicator. Implicitly animated.
    private func showSelectedPointHandle() {
        touchindicatorLayer.opacity = 1
    }
    
    /// Moves the highlight indicator to the currently selected element. The `selectedElement` needs to be set before this method is called. Moving the handle is not animated.
    private func moveSelectedPointHandle() {
        guard let selectedPoint = selectedElement else { return }
        
        // Disable implicit animations because moving should exactly follow the users thumb.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        touchindicatorLayer.position.x = selectedPoint.point.x
        CATransaction.commit()
    }
    
    /// Fades out and removes the handle. Implicitly animated.
    private func hideSelectedPointHandle() {
        touchindicatorLayer.opacity = 0
    }
}
