//
//  SettingsObject.swift
//  Sample
//  
//  Created by Keisuke Chinone on 2024/07/07.
//

import SwiftStorage

@Storage
final class SettingsObject {
    var isObservationSupported: Bool
    
    var isDisabledOnAPerPropertyLevel: Bool
    
    var isStoredInUserDefaults: Bool
    
    var isStoredInKeyValueStore: Bool
    
    var isSpecifiedIndividually: Bool
    
    var isPossibleToUseKeyValueStoreAndUserDefaultsTogether: Bool
    
    var sampleBool: Bool
    
    var sampleInt: Int
    
    var sampleDouble: Double
    
    var sampleFloat: Float
    
    var sampleString: String
    
    var sampleDate: Date
    @Attribute(key: "Attribute")
    var attribute: Bool
    @Transient
    var transient: Bool
    @ObservationIgnored
    var observationIgnored: Bool

    init() {
        self.isObservationSupported = true
        self.isDisabledOnAPerPropertyLevel = true
        self.isStoredInUserDefaults = false
        self.isStoredInKeyValueStore = false
        self.isSpecifiedIndividually = true
        self.isPossibleToUseKeyValueStoreAndUserDefaultsTogether = false
        self.sampleBool = false
        self.sampleString = ""
        self.sampleInt = 0
        self.sampleDouble = 0.0
        self.sampleFloat = 0.0
        self.sampleDate = Date.now
        self.attribute = true
        self.transient = true
        self.observationIgnored = true
    }
}
