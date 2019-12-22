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
