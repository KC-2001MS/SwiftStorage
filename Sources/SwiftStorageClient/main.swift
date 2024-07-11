//
//  main.swift
//
//
//  Created by Keisuke Chinone on 2024/07/06.
//

import Observation
import Foundation
import SwiftStorage

@Storage
final class Client {
    var bool: Bool {
        didSet {
            int += 1
            print("Int: \(int)")
            double += 0.1
            print("Double: \(double)")
            float += 0.1
            print("Float: \(float)")
            string += "1"
            print("String: \(string)")
            date = Date.now
            print("Date: \(date)")
            attribute.toggle()
            print("Attribute: \(attribute)")
            transient.toggle()
            print("Transient: \(transient)")
            observationIgnored.toggle()
            print("ObservationIgnored: \(observationIgnored)")
        }
    }
    
    var int: Int
    
    var double: Double
    
    var float: Float
    
    var string: String
    
    var date: Date
    @Attribute(key: "Attribute")
    var attribute: Bool
    @Transient
    var transient: Bool
    @ObservationIgnored
    var observationIgnored: Bool
    
    init() {
        self.bool = false
        self.int = 1
        self.double = 0.0
        self.float = 0.0
        self.string = ""
        self.date = Date.now
        self.attribute = false
        self.transient = false
        self.observationIgnored = false
    }
}

var client = Client()

client.bool.toggle()

try await Task.sleep(nanoseconds: 2000000000)
