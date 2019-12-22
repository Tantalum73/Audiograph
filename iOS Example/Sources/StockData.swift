//
//  StockData.swift
//  ChartTest1
//
//  Created by Andreas Neusüß on 10.05.19.
//  Copyright © 2019 Anerma. All rights reserved.
//

import Foundation

struct StockData {
    let date: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let adjustedClose: Double
    let volume: Double
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // 2014-05-12
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    init?(from input: [String]) {
        guard input.count > 5 else { return nil }
        let possibleDate = input[0]
        let possibleOpen = input [1]
        let possibleHigh = input [2]
        let possibleLow  = input [3]
        let possibleClose = input [4]
        let possibleAdjustedClose = input [5]
        let possibleVolume = input [6]
        
        guard let date = StockData.date(from: possibleDate) else { return nil }
        guard let open = Double(possibleOpen) else { return nil }
        guard let high = Double(possibleHigh) else { return nil }
        guard let low = Double(possibleLow) else { return nil }
        guard let close = Double(possibleClose) else { return nil }
        guard let adjustedClose = Double(possibleAdjustedClose) else { return nil }
        guard let volume = Double(possibleVolume) else { return nil }
        
        self.date = date
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.adjustedClose = adjustedClose
        self.volume = volume
    }
    
    private static func date(from input: String) -> Date? {
        let formatter = StockData.dateFormatter
        return formatter.date(from: input)
    }
}
