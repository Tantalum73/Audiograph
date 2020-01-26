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
    let audiograph: Audiograph = {
        let completion = NSLocalizedString("CHART_ACCESSIBILITY_AUDIOGRAPH_COMPLETION_PHREASE", comment: "This phrase is read when the Audiograph has completed describing the chart using audio. Should be something like 'complete'.")
        let indication = NSLocalizedString("CHART_PLAY_AUDIOGRAPH_ACTION", comment: "The title of the accessibility action that starts playing the audiograph. 'Play audiograph.' for example.")
        let localizations = AudiographLocalizations(completionIndicationUtterance: completion, accessibilityIndicationTitle: indication)
        
        return Audiograph(localizations: localizations)
    }()
    
    /// The color of the graph. Changes will be animated.
    var chartColor: UIColor = .red {
        didSet {
            graphLayer.strokeColor = chartColor.cgColor
        }
    }
    
    /// Stores the scaled points that exactly fit whithin the view's bounds. Also updates the `touchesMovedThreshold` when set.
    private (set) var scaledPoints = [CGPoint]() {
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
    private let baselineLayer: BaselineLayer = {
        let layer = BaselineLayer()
        layer.name = "BaselineOfGraph"
        layer.animationDuration = 1.2
        layer.timingFunction = ChartView.timingFunction
        return layer
    }()
    
    /// Layer that draws the graph.
    private let graphLayer: GraphLayer = {
        let layer = GraphLayer()
        layer.name = "GraphLayer"
        
        return layer
    }()
    
    private static let timingFunction = CAMediaTimingFunction(controlPoints: 0.64, 0, 0, 1)
    
    private let dataProcessor = ChartViewDataProcessor()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
        setupAccessibility()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayers()
        setupAccessibility()
    }
    
    private func setupLayers() {
        layer.isGeometryFlipped = true
        layer.addSublayer(baselineLayer)
        layer.addSublayer(graphLayer)
        layer.addSublayer(touchindicatorLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        graphLayer.frame = bounds
        touchindicatorLayer.frame = CGRect(origin: touchindicatorLayer.frame.origin, size: CGSize(width: 2.0, height: bounds.height))
        
        baselineLayer.frame = CGRect(x: 0, y: baselineLayer.frame.origin.y, width: bounds.width, height: 1.0)
        
        CATransaction.commit()
    }
    
    private func updateBaselineLayerPosition(animated: Bool) {
        guard let significantPoint = scaledPoints.first else { return }
        let newBaselinePosition = CGPoint(x: baselineLayer.position.x, y: significantPoint.y)
        baselineLayer.transformPosition(to: newBaselinePosition, animated: animated)
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
        layoutIfNeeded()
        guard newPoints.count > 0 else { return }
        
        scaledPoints = dataProcessor.scaledPoints(for: newPoints, toFitInto: bounds)
        let newPath = dataProcessor.path(for: scaledPoints)
        
        updateBaselineLayerPosition(animated: true)
        graphLayer.transform(towards: newPath, animated: true)
    }
    
    // MARK: - Touch handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard !scaledPoints.isEmpty else { return }
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
        guard !scaledPoints.isEmpty else { return nil }
        
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
        
        return (point: pointNextToTouchLocation, indexInData: indexOfFoundPoint)
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
