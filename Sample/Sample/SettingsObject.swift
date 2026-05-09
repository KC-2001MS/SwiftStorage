//
//  SettingsObject.swift
//  Sample
//  
//  Created by Keisuke Chinone on 2024/07/07.
//

import SwiftStorage

@Storage
final class SettingsObject {
    // MARK: - Feature Showcase
    var isObservationSupported: Bool

    var isDisabledOnAPerPropertyLevel: Bool

    var isStoredInUserDefaults: Bool

    var isStoredInKeyValueStore: Bool

    var isSpecifiedIndividually: Bool

    var isPossibleToUseKeyValueStoreAndUserDefaultsTogether: Bool

    // MARK: - Storable Types
    var sampleBool: Bool

    var sampleInt: Int

    var sampleDouble: Double

    var sampleFloat: Float

    var sampleString: String

    var sampleDate: Date

    // MARK: - Property Macros
    @Attribute(type: .localWith(suite: "test"), key: "Attribute")
    var attribute: Bool

    @Attribute(key: "UnhashedKey", hashed: false)
    var unhashed: Bool

    @Attribute(.ephemeral)
    var observed: Bool

    @ObservationTracked
    var observationTracked: Bool

    @Transient
    var transient: Bool

    @ObservationIgnored
    var observationIgnored: Bool

    #if os(macOS)
    var macOnlyFeature: Bool
    #endif

    #if os(iOS)
    var iosOnlyFeature: Bool
    #endif

    #if os(macOS)
    @Attribute(type: .localWith(suite: "platformTest"), key: "MacAttribute")
    var macAttributeFeature: Bool
    #endif

    init() {
        self.isObservationSupported = true
        self.isDisabledOnAPerPropertyLevel = true
        self.isStoredInUserDefaults = true
        self.isStoredInKeyValueStore = true
        self.isSpecifiedIndividually = true
        self.isPossibleToUseKeyValueStoreAndUserDefaultsTogether = true
        self.sampleBool = false
        self.sampleString = ""
        self.sampleInt = 0
        self.sampleDouble = 0.0
        self.sampleFloat = 0.0
        self.sampleDate = Date.now
        self.attribute = true
        self.unhashed = false
        self.observed = false
        self.observationTracked = false
        self.transient = true
        self.observationIgnored = true
        #if os(macOS)
        self.macOnlyFeature = false
        #endif
        #if os(iOS)
        self.iosOnlyFeature = false
        #endif
        #if os(macOS)
        self.macAttributeFeature = false
        #endif
    }
}

@Storage(type: .cloud)
final class CloudSettingsObject {
    var cloudBool: Bool

    var cloudString: String

    var cloudInt: Int

    var cloudDouble: Double

    @Attribute(type: .local, key: "localOverride")
    var localOverride: Bool

    #if os(macOS)
    var cloudMacOnly: Bool
    #endif

    init() {
        self.cloudBool = false
        self.cloudString = ""
        self.cloudInt = 0
        self.cloudDouble = 0.0
        self.localOverride = false
        #if os(macOS)
        self.cloudMacOnly = false
        #endif
    }
}
