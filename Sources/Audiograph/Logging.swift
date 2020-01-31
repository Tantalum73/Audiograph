//
//  Logging.swift
//  
//
//  Created by Andreas Neusüß on 31.01.20.
//

import Foundation

struct Logger {
    static var shared = Logger()
    private init() {
        // Initially empty to prevent wrong usage of this singleton.
    }
    
    var loggingEnabled: Bool = false
    
    func log(message: String) {
        print(message)
    }
}
