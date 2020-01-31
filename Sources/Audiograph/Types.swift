//
//  Types.swift
//  ChartAndSound
//
//  Created by Andreas Neusüß on 22.12.19.
//  Copyright © 2019 Anerma. All rights reserved.
//

import Foundation
#if !os(macOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

typealias Frequency = Float32
typealias RelativeTime = Double
typealias Sample = Float32
typealias Samples = [Sample]

extension NSNotification.Name {
    static let StopAudiograph = "de.anerma.stopAudiograph"
}

struct GraphElement {
    let relativeTime: RelativeTime
    let frequency: Frequency
    
    init(from point: CGPoint) {
        relativeTime = Double(point.x)
        frequency = Float(point.y)
    }
    init(relativeTime: RelativeTime, frequency: Frequency) {
        self.relativeTime = relativeTime
        self.frequency = frequency
    }
}

struct AudioInformation: RandomAccessCollection, CustomDebugStringConvertible {
    let storage: [GraphElement]
    
    var frequencies: [Frequency]
    var relativeTimes: [RelativeTime]
    
    init(points: [CGPoint]) {
        storage = points.map { return GraphElement(from: $0) }
        frequencies = storage.map { $0.frequency }
        relativeTimes = storage.map { $0.relativeTime }
    }
    
    init(relativeTimes: [RelativeTime], frequencies: [Frequency]) {
        self.frequencies = frequencies
        self.relativeTimes = relativeTimes
        
        storage = zip(relativeTimes, frequencies).map { GraphElement(relativeTime: $0, frequency: $1) }
    }
    
    // MARK: Collection Requirements
    typealias Element = GraphElement
    typealias Index = Int
    
    var startIndex: Index { storage.startIndex }
    var endIndex: Index { storage.endIndex }
    subscript(position: Index) -> Element { storage[position] }
    func index(after i: Index) -> Index { storage.index(after: i) }
    
    var debugDescription: String {
        var description: String = "\(count) elements: "
        for element in storage {
            description.append("at \(element.relativeTime):\t\(element.frequency)Hz")
        }
        return description
    }
}

enum SanityCheckError: Error {
    case negativeContentInTimestamps
    /// Timestamps need to to be in increasing order.
    case noMonotonousInput
    case inputEmpty
    case inputTooShort
}

extension TimeInterval {
    
    init(dispatchTimeInterval: DispatchTimeInterval) {
        switch dispatchTimeInterval {
        case .seconds(let value):
            self = Double(value)
        case .milliseconds(let value):
            self = Double(value) * 0.001
        case .microseconds(let value):
            self = Double(value) * 0.000_001
        case .nanoseconds(let value):
            self = Double(value) * 0.000_000_001
        case .never:
            fatalError("This time interval is not supported as playing duration. Please use a different one.")
        @unknown default:
            fatalError("This time interval is not supported as playing duration. Please use a different one.")
        }
    }
}

extension Samples {
    /** Ends the samples on a zero and cuts off elements to achieve that.
     The samples are cut where the sign changes from negative to positive. A trailing 0 is also added to improve perceived audio quality.
     */
    mutating func postprocess() {
        
        let numberOfElementsToRemove = numberOfElementsToRemoveAtEnd()
        
        removeLast(numberOfElementsToRemove)
        append(0)
    }
    
    func numberOfElementsToRemoveAtEnd() -> Int {
        // Find the last transition from <0 to >= 0
        guard let last = last else { return 0 }
        
        let latestNumberIsPositive = last > 0
        if latestNumberIsPositive {
            // Next negative number is the right one
            let indexOfLatestNegative = indexOfLatestNegativeNumber() ?? index(before: endIndex)
            let numberOfElementsToRemove = index(before: endIndex) - indexOfLatestNegative
            return numberOfElementsToRemove
        } else {
            // Find latest tansition from -· to +·
            return numberOfElementsToRemovedUntilLatestChangeInSignTowardsPositive() ?? 0
        }
    }
    
    func indexOfLatestNegativeNumber() -> Int? {
        return lastIndex(where: { $0 < 0 })
    }
    
    /// Counts the number of elements that need to be removed in order to end on the latest contained negative number. One element after that number the sign is positive again.
    ///
    /// The result might be `nil` indicating that there is no change in sign and not enough elements can be removed.
    /// The result should not be interpreted using zero-based-counting, when the last 3 elements should be removed, start counting from 1 to 3.
    func numberOfElementsToRemovedUntilLatestChangeInSignTowardsPositive() -> Int? {
        var elementsToRemove: Int = 0
        
        for startAndEnd in zip(self, dropFirst()).reversed() {
            let prior = startAndEnd.0
            let after = startAndEnd.1
            
            elementsToRemove += 1
            if prior < 0 && after > 0 {
                return elementsToRemove
            }
        }
        
        return nil
    }
}
