//
//  DataStore.swift
//  ChartTest1
//
//  Created by Andreas Neusüß on 10.05.19.
//  Copyright © 2019 Anerma. All rights reserved.
//

import Foundation

struct DataStore {
    /// Holds the data as it was parsed.
    private let rawData: [StockData]
    
    /// Init the DataStore with content of a given string. That string will be parsed and transformed into `[StockData]`. If that fails, no error or warning is thrown, so please watch your steps.
    ///
    /// - Parameter input: The content of a file that should be converted into `[StockData]`.
    init(contentsOfCSV input: String) {
        let lines = input.components(separatedBy: .newlines)
        var resut = [StockData]()
        for line in lines {
            let components = line.components(separatedBy: ",")
            if let data = StockData(from: components) {
                resut.append(data)
            }
        }
        
        rawData = resut
    }
    
    /// Data for the first day.
    lazy var firstDay: [StockData] = {
        var result = [StockData]()
        
        guard let newestDate = rawData.last?.date else { return result }
        result = rawData.filter( { $0.date.isInSameDay(date: newestDate) } )
        
        return result
    }()
    
    /// Data for the first five days.
    lazy var firstFiveDays: [StockData] = {
        var result = [StockData]()
        
         guard let newestDate = rawData.last?.date else { return result }
        guard let deadline = Calendar.current.date(byAdding: .day, value: -5, to: newestDate)?.endOfDay else { return result }
        // Get every element whose date is before or on the same date as the deadline.
        
        result = rawData.filter( { $0.date > deadline } )
        
        return result
    }()

    /// Data for the first month.
    lazy var month: [StockData] = {
        var result = [StockData]()
        
         guard let newestDate = rawData.last?.date else { return result }
        guard let deadline = Calendar.current.date(byAdding: .month, value: -1, to: newestDate)?.endOfDay else { return result }
        // Get every element whose date is before or on the same date as the deadline.
        
        result = rawData.filter( { $0.date > deadline } )
        
        return result
    }()
    
    /// Data for the first six months.
    lazy var sixMonths: [StockData] = {
        var result = [StockData]()
        
         guard let newestDate = rawData.last?.date else { return result }
        guard let deadline = Calendar.current.date(byAdding: .month, value: -6, to: newestDate)?.endOfDay else { return result }
        // Get every element whose date is before or on the same date as the deadline.
        
        result = rawData.filter( { $0.date > deadline } )
        
        return result
    }()
    
    /// Data for the first year.
    lazy var year: [StockData] = {
        var result = [StockData]()
        
         guard let newestDate = rawData.last?.date else { return result }
        guard let deadline = Calendar.current.date(byAdding: .year, value: -1, to: newestDate)?.endOfDay else { return result }
        // Get every element whose date is before or on the same date as the deadline.
        
        result = rawData.filter( { $0.date > deadline } )
        
        return result
    }()
    
    /// Data for the first five years.
    lazy var fiveYears: [StockData] = {
        var result = [StockData]()

         guard let newestDate = rawData.last?.date else { return result }
        guard let deadline = Calendar.current.date(byAdding: .year, value: -5, to: newestDate)?.endOfDay else { return result }
        // Get every element whose date is before or on the same date as the deadline.
        
        result = rawData.filter( { $0.date > deadline } )
        
        return result
    }()
    
    var currentDataSet = [StockData]()
    
}
extension Date {
    func isInSameDay(date: Date) -> Bool {
        return Calendar.current.isDate(self, equalTo: date, toGranularity: .day)
    }

    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
    
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: startOfDay)
        return Calendar.current.date(from: components)!
    }
    
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth)!
    }
}
