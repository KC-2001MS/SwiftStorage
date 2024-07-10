//
//  SettingsObject.swift
//  Sample
//  
//  Created by Keisuke Chinone on 2024/07/07.
//


import Observation
import Foundation
import SwiftStorage

@Storage
final class SettingsObject {
    var isObservationSupported: Bool
    
    var isDisabledOnAPerPropertyLevel: Bool
    
    var isStoredInUserDefaults: Bool
    
    var isStoredInKeyValueStore: Bool
    
    var isPossibleToUseKeyValueStoreAndUserDefaultsTogether: Bool
    
    var sampleBool: Bool
    
    var sampleString: String
    
    init() {
        self.isObservationSupported = true
        self.isDisabledOnAPerPropertyLevel = true
        self.isStoredInUserDefaults = false
        self.isStoredInKeyValueStore = false
        self.isPossibleToUseKeyValueStoreAndUserDefaultsTogether = false
        self.sampleBool = false
        self.sampleString = ""
    }
}
