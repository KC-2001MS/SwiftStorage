//
//  SwiftStorageTests.swift
//  SwiftStorage
//
//  Created by Keisuke Chinone on 2024/07/29.
//

#if canImport(SwiftStorageMacros)
import MacroTesting
import SwiftSyntaxMacros
import Testing
import SwiftStorageMacros

extension Tag {
    @Tag static var storage: Self
    @Tag static var storedProperty: Self
    @Tag static var attribute: Self
    @Tag static var transient: Self
    @Tag static var cloud: Self

    @Tag static var executable: Self
    @Tag static var normalBehavior: Self
}

nonisolated(unsafe) let testMacros: [String: Macro.Type] = [
    "Storage": StorageMacro.self,
    "_StoredProperty": StoredPropertyMacro.self,
    "Attribute": AttributeMacro.self,
    "Transient": TransientMacro.self,
]

@Suite("Storage Macro Testing",.tags(.storage))
struct StorageMacrotests {
    @Test("Does it work as expected with variables that do not have macros attached?")
    func variableExpansionWithoutAMacroTests() async throws {
        assertMacro(testMacros) {
            """
            @Storage
            class TestClass {
                var value: Bool = false
            }
            """
        } expansion: {
            """
            class TestClass {
                var value: Bool {
                    @storageRestrictions(initializes: _value)
                    init(initialValue) {
                        _value = initialValue
                    }
                    get {
                        access(keyPath: \\.value)
                        return _$store.persistedValue(forKey: #hashify("TestClass.value"), default: _value)
                    }
                    set {
                        if shouldNotifyObservers(_$store.persistedValue(forKey: #hashify("TestClass.value"), default: _value), newValue) {
                            withMutation(keyPath: \\.value) {
                                _$store.setPersisted(newValue, forKey: #hashify("TestClass.value"))
                            }
                        }
                    }
                    _modify {
                        access(keyPath: \\.value)
                        _$observationRegistrar.willSet(self, keyPath: \\.value)
                        var value = _$store.persistedValue(forKey: #hashify("TestClass.value"), default: _value)
                        defer {
                            _$store.setPersisted(value, forKey: #hashify("TestClass.value"))
                            _$observationRegistrar.didSet(self, keyPath: \\.value)
                        }
                        yield &value
                    }
                }

                private let _$observationRegistrar = Observation.ObservationRegistrar()

                internal nonisolated func access<Member>(
                    keyPath: KeyPath<TestClass, Member>
                ) {
                    _$observationRegistrar.access(self, keyPath: keyPath)
                }

                internal nonisolated func withMutation<Member, MutationResult>(
                    keyPath: KeyPath<TestClass, Member>,
                    _ mutation: () throws -> MutationResult
                ) rethrows -> MutationResult {
                    try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
                }

                private let className = "TestClass"

                private nonisolated func shouldNotifyObservers<Member>(_ lhs: Member, _ rhs: Member) -> Bool {
                    true
                }

                private nonisolated func shouldNotifyObservers<Member: Equatable>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs != rhs
                }

                private nonisolated func shouldNotifyObservers<Member: AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs !== rhs
                }

                private nonisolated func shouldNotifyObservers<Member: Equatable & AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs != rhs
                }

                private let _$store: any StorageBackend = (StorageType.local).backend
            }
            """
        }
    }

    @Test("Does the constant work as expected?")
    func constantTesting() async throws {
        assertMacro(testMacros) {
            """
            @Storage
            class TestClass {
                let value: Bool = false
            }
            """
        } expansion: {
            """
            class TestClass {
                let value: Bool = false

                private let _$observationRegistrar = Observation.ObservationRegistrar()

                internal nonisolated func access<Member>(
                    keyPath: KeyPath<TestClass, Member>
                ) {
                    _$observationRegistrar.access(self, keyPath: keyPath)
                }

                internal nonisolated func withMutation<Member, MutationResult>(
                    keyPath: KeyPath<TestClass, Member>,
                    _ mutation: () throws -> MutationResult
                ) rethrows -> MutationResult {
                    try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
                }

                private let className = "TestClass"

                private nonisolated func shouldNotifyObservers<Member>(_ lhs: Member, _ rhs: Member) -> Bool {
                    true
                }

                private nonisolated func shouldNotifyObservers<Member: Equatable>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs != rhs
                }

                private nonisolated func shouldNotifyObservers<Member: AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs !== rhs
                }

                private nonisolated func shouldNotifyObservers<Member: Equatable & AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs != rhs
                }

                private let _$store: any StorageBackend = (StorageType.local).backend
            }
            """
        }
    }

    @Test("Does the variable with Transient macro work as expected?")
    func variableWithTransientMacroTesting() async throws {
        assertMacro(testMacros) {
            """
            @Storage
            class TestClass {
                @Transient
                var value: Bool = false
            }
            """
        } expansion: {
            """
            class TestClass {
                var value: Bool = false

                private let _$observationRegistrar = Observation.ObservationRegistrar()

                internal nonisolated func access<Member>(
                    keyPath: KeyPath<TestClass, Member>
                ) {
                    _$observationRegistrar.access(self, keyPath: keyPath)
                }

                internal nonisolated func withMutation<Member, MutationResult>(
                    keyPath: KeyPath<TestClass, Member>,
                    _ mutation: () throws -> MutationResult
                ) rethrows -> MutationResult {
                    try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
                }

                private let className = "TestClass"

                private nonisolated func shouldNotifyObservers<Member>(_ lhs: Member, _ rhs: Member) -> Bool {
                    true
                }

                private nonisolated func shouldNotifyObservers<Member: Equatable>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs != rhs
                }

                private nonisolated func shouldNotifyObservers<Member: AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs !== rhs
                }

                private nonisolated func shouldNotifyObservers<Member: Equatable & AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs != rhs
                }

                private let _$store: any StorageBackend = (StorageType.local).backend
            }
            """
        }
    }

    @Test("Does the variable with Attribute(.ephemeral) macro work as expected?")
    func variableWithAttributeEphemeralMacroTesting() async throws {
        assertMacro(testMacros) {
            """
            @Storage
            class TestClass {
                @Attribute(.ephemeral)
                var value: Bool = false
            }
            """
        } expansion: {
            """
            class TestClass {
                @ObservationTracked
                var value: Bool = false

                private let _$observationRegistrar = Observation.ObservationRegistrar()

                internal nonisolated func access<Member>(
                    keyPath: KeyPath<TestClass, Member>
                ) {
                    _$observationRegistrar.access(self, keyPath: keyPath)
                }

                internal nonisolated func withMutation<Member, MutationResult>(
                    keyPath: KeyPath<TestClass, Member>,
                    _ mutation: () throws -> MutationResult
                ) rethrows -> MutationResult {
                    try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
                }

                private let className = "TestClass"

                private nonisolated func shouldNotifyObservers<Member>(_ lhs: Member, _ rhs: Member) -> Bool {
                    true
                }

                private nonisolated func shouldNotifyObservers<Member: Equatable>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs != rhs
                }

                private nonisolated func shouldNotifyObservers<Member: AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs !== rhs
                }

                private nonisolated func shouldNotifyObservers<Member: Equatable & AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs != rhs
                }

                private let _$store: any StorageBackend = (StorageType.local).backend
            }
            """
        }
    }

    @Test("Does the variable with ObservationIgnored macro work as expected?")
    func variableWithObservationIgnoredMacroTesting() async throws {
        assertMacro(testMacros) {
            """
            @Storage
            class TestClass {
                @ObservationIgnored
                var value: Bool = false
            }
            """
        } expansion: {
            """
            class TestClass {
                @ObservationIgnored
                var value: Bool = false

                private let _$observationRegistrar = Observation.ObservationRegistrar()

                internal nonisolated func access<Member>(
                    keyPath: KeyPath<TestClass, Member>
                ) {
                    _$observationRegistrar.access(self, keyPath: keyPath)
                }

                internal nonisolated func withMutation<Member, MutationResult>(
                    keyPath: KeyPath<TestClass, Member>,
                    _ mutation: () throws -> MutationResult
                ) rethrows -> MutationResult {
                    try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
                }

                private let className = "TestClass"

                private nonisolated func shouldNotifyObservers<Member>(_ lhs: Member, _ rhs: Member) -> Bool {
                    true
                }

                private nonisolated func shouldNotifyObservers<Member: Equatable>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs != rhs
                }

                private nonisolated func shouldNotifyObservers<Member: AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs !== rhs
                }

                private nonisolated func shouldNotifyObservers<Member: Equatable & AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs != rhs
                }

                private let _$store: any StorageBackend = (StorageType.local).backend
            }
            """
        }
    }
}

@Suite("StoredProperty Macro Testing",.tags(.storedProperty))
struct StoredPropertyTests {
    @Test("Does the variable with _StoredProperty macro work as expected?")
    func variableWithStoredPropertyMacroTesting() async throws {
        assertMacro(testMacros) {
            """
            @_StoredProperty
            var value: Bool
            """
        } expansion: {
            """
            var value: Bool {
                @storageRestrictions(initializes: _value)
                init(initialValue) {
                    _value = initialValue
                }
                get {
                    access(keyPath: \\.value)
                    return _$store.persistedValue(forKey: #hashify("\\(className).value"), default: _value)
                }
                set {
                    if shouldNotifyObservers(_$store.persistedValue(forKey: #hashify("\\(className).value"), default: _value), newValue) {
                        withMutation(keyPath: \\.value) {
                            _$store.setPersisted(newValue, forKey: #hashify("\\(className).value"))
                        }
                    }
                }
                _modify {
                    access(keyPath: \\.value)
                    _$observationRegistrar.willSet(self, keyPath: \\.value)
                    var value = _$store.persistedValue(forKey: #hashify("\\(className).value"), default: _value)
                    defer {
                        _$store.setPersisted(value, forKey: #hashify("\\(className).value"))
                        _$observationRegistrar.didSet(self, keyPath: \\.value)
                    }
                    yield &value
                }
            }
            """
        }
    }

    @Test("Does the constant with _StoredProperty macro work as expected?")
    func constantWithStoredPropertyMacroTesting() async throws {
        assertMacro(testMacros) {
            """
            @_StoredProperty
            let value: Bool
            """
        } expansion: {
            """
            let value: Bool
            """
        }
    }
}

@Suite("Attribute(.ephemeral) Macro Testing",.tags(.attribute))
struct AttributeEphemeralTests {
    @Test("Does @Attribute(.ephemeral) prevent persistence in @Storage context?")
    func attributeEphemeralInStorageContextTest() async throws {
        assertMacro(testMacros) {
            """
            @Storage
            class TestClass {
                @Attribute(.ephemeral)
                var value: Bool = false

                var persisted: Bool = false
            }
            """
        } expansion: {
            """
            class TestClass {
                @ObservationTracked
                var value: Bool = false

                var persisted: Bool {
                    @storageRestrictions(initializes: _persisted)
                    init(initialValue) {
                        _persisted = initialValue
                    }
                    get {
                        access(keyPath: \\.persisted)
                        return _$store.persistedValue(forKey: #hashify("TestClass.persisted"), default: _persisted)
                    }
                    set {
                        if shouldNotifyObservers(_$store.persistedValue(forKey: #hashify("TestClass.persisted"), default: _persisted), newValue) {
                            withMutation(keyPath: \\.persisted) {
                                _$store.setPersisted(newValue, forKey: #hashify("TestClass.persisted"))
                            }
                        }
                    }
                    _modify {
                        access(keyPath: \\.persisted)
                        _$observationRegistrar.willSet(self, keyPath: \\.persisted)
                        var value = _$store.persistedValue(forKey: #hashify("TestClass.persisted"), default: _persisted)
                        defer {
                            _$store.setPersisted(value, forKey: #hashify("TestClass.persisted"))
                            _$observationRegistrar.didSet(self, keyPath: \\.persisted)
                        }
                        yield &value
                    }
                }

                private let _$observationRegistrar = Observation.ObservationRegistrar()

                internal nonisolated func access<Member>(
                    keyPath: KeyPath<TestClass, Member>
                ) {
                    _$observationRegistrar.access(self, keyPath: keyPath)
                }

                internal nonisolated func withMutation<Member, MutationResult>(
                    keyPath: KeyPath<TestClass, Member>,
                    _ mutation: () throws -> MutationResult
                ) rethrows -> MutationResult {
                    try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
                }

                private let className = "TestClass"

                private nonisolated func shouldNotifyObservers<Member>(_ lhs: Member, _ rhs: Member) -> Bool {
                    true
                }

                private nonisolated func shouldNotifyObservers<Member: Equatable>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs != rhs
                }

                private nonisolated func shouldNotifyObservers<Member: AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs !== rhs
                }

                private nonisolated func shouldNotifyObservers<Member: Equatable & AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs != rhs
                }

                private let _$store: any StorageBackend = (StorageType.local).backend
            }
            """
        }
    }
}

@Suite("Attribute Macro Testing",.tags(.attribute))
struct AttributeTests {
    @Test("Does the variable with Attribute macro work as expected?")
    func variableWitAttributeMacroTesting() async throws {
        assertMacro(testMacros) {
            """
            @_StoredProperty
            @Attribute(key: "value")
            var value: Bool
            """
        } expansion: {
            """
            var value: Bool {
                @storageRestrictions(initializes: _value)
                init(initialValue) {
                    _value = initialValue
                }
                get {
                    access(keyPath: \\.value)
                    return _$store.persistedValue(forKey: #hashify("value"), default: _value)
                }
                set {
                    if shouldNotifyObservers(_$store.persistedValue(forKey: #hashify("value"), default: _value), newValue) {
                        withMutation(keyPath: \\.value) {
                            _$store.setPersisted(newValue, forKey: #hashify("value"))
                        }
                    }
                }
                _modify {
                    access(keyPath: \\.value)
                    _$observationRegistrar.willSet(self, keyPath: \\.value)
                    var value = _$store.persistedValue(forKey: #hashify("value"), default: _value)
                    defer {
                        _$store.setPersisted(value, forKey: #hashify("value"))
                        _$observationRegistrar.didSet(self, keyPath: \\.value)
                    }
                    yield &value
                }
            }
            """
        }
    }

    @Test("Does the variable with Attribute macro and hashed: false work as expected?")
    func variableWithAttributeMacroUnhashedTesting() async throws {
        assertMacro(testMacros) {
            """
            @_StoredProperty
            @Attribute(key: "value", hashed: false)
            var value: Bool
            """
        } expansion: {
            """
            var value: Bool {
                @storageRestrictions(initializes: _value)
                init(initialValue) {
                    _value = initialValue
                }
                get {
                    access(keyPath: \\.value)
                    return _$store.persistedValue(forKey: "value", default: _value)
                }
                set {
                    if shouldNotifyObservers(_$store.persistedValue(forKey: "value", default: _value), newValue) {
                        withMutation(keyPath: \\.value) {
                            _$store.setPersisted(newValue, forKey: "value")
                        }
                    }
                }
                _modify {
                    access(keyPath: \\.value)
                    _$observationRegistrar.willSet(self, keyPath: \\.value)
                    var value = _$store.persistedValue(forKey: "value", default: _value)
                    defer {
                        _$store.setPersisted(value, forKey: "value")
                        _$observationRegistrar.didSet(self, keyPath: \\.value)
                    }
                    yield &value
                }
            }
            """
        }
    }

    @Test("Does the constant with Attribute macro work as expected?")
    func constantWithAttributeMacroTesting() async throws {
        assertMacro(testMacros) {
            """
            @_StoredProperty
            @Attribute(key: "value")
            let value: Bool
            """
        } expansion: {
            """
            let value: Bool
            """
        }
    }
}

@Suite("Transient Macro Testing",.tags(.transient))
struct Transient {
    @Test("Does the variable with Transient macro work as expected?")
    func variableWithTransientMacroTesting() async throws {
        assertMacro(testMacros) {
            """
            @Transient
            var value: Bool
            """
        } expansion: {
            """
            var value: Bool
            """
        }
    }

    @Test("Does the constant with Transient macro work as expected?")
    func constantWithTransientMacroTesting() async throws {
        assertMacro(testMacros) {
            """
            @Transient
            let value: Bool
            """
        } expansion: {
            """
            let value: Bool
            """
        }
    }
}

@Suite("LocalWith Suite Testing",.tags(.attribute))
struct LocalWithSuiteTests {
    @Test("Does @Storage(type: .localWith(suite:)) generate cached store variable?")
    func storageWithLocalWithSuiteTest() async throws {
        assertMacro(testMacros) {
            """
            @Storage(type: .localWith(suite: "group.com.example"))
            class TestClass {
                var value: Bool = false
            }
            """
        } expansion: {
            """
            class TestClass {
                var value: Bool {
                    @storageRestrictions(initializes: _value)
                    init(initialValue) {
                        _value = initialValue
                    }
                    get {
                        access(keyPath: \\.value)
                        return _$store.persistedValue(forKey: #hashify("TestClass.value"), default: _value)
                    }
                    set {
                        if shouldNotifyObservers(_$store.persistedValue(forKey: #hashify("TestClass.value"), default: _value), newValue) {
                            withMutation(keyPath: \\.value) {
                                _$store.setPersisted(newValue, forKey: #hashify("TestClass.value"))
                            }
                        }
                    }
                    _modify {
                        access(keyPath: \\.value)
                        _$observationRegistrar.willSet(self, keyPath: \\.value)
                        var value = _$store.persistedValue(forKey: #hashify("TestClass.value"), default: _value)
                        defer {
                            _$store.setPersisted(value, forKey: #hashify("TestClass.value"))
                            _$observationRegistrar.didSet(self, keyPath: \\.value)
                        }
                        yield &value
                    }
                }

                private let _$observationRegistrar = Observation.ObservationRegistrar()

                internal nonisolated func access<Member>(
                    keyPath: KeyPath<TestClass, Member>
                ) {
                    _$observationRegistrar.access(self, keyPath: keyPath)
                }

                internal nonisolated func withMutation<Member, MutationResult>(
                    keyPath: KeyPath<TestClass, Member>,
                    _ mutation: () throws -> MutationResult
                ) rethrows -> MutationResult {
                    try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
                }

                private let className = "TestClass"

                private nonisolated func shouldNotifyObservers<Member>(_ lhs: Member, _ rhs: Member) -> Bool {
                    true
                }

                private nonisolated func shouldNotifyObservers<Member: Equatable>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs != rhs
                }

                private nonisolated func shouldNotifyObservers<Member: AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs !== rhs
                }

                private nonisolated func shouldNotifyObservers<Member: Equatable & AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs != rhs
                }

                private let _$store: any StorageBackend = (StorageType.localWith(suite: "group.com.example")).backend
            }
            """
        }
    }

    @Test("Does @Attribute(type: .localWith(suite:)) generate cached store variable?")
    func attributeLocalWithSuiteTest() async throws {
        assertMacro(testMacros) {
            """
            @Storage
            class TestClass {
                @Attribute(type: .localWith(suite: "test"), key: "custom")
                var value: Bool = false
            }
            """
        } expansion: {
            """
            class TestClass {
                var value: Bool {
                    @storageRestrictions(initializes: _value)
                    init(initialValue) {
                        _value = initialValue
                    }
                    get {
                        access(keyPath: \\.value)
                        return _$store_value.persistedValue(forKey: #hashify("custom"), default: _value)
                    }
                    set {
                        if shouldNotifyObservers(_$store_value.persistedValue(forKey: #hashify("custom"), default: _value), newValue) {
                            withMutation(keyPath: \\.value) {
                                _$store_value.setPersisted(newValue, forKey: #hashify("custom"))
                            }
                        }
                    }
                    _modify {
                        access(keyPath: \\.value)
                        _$observationRegistrar.willSet(self, keyPath: \\.value)
                        var value = _$store_value.persistedValue(forKey: #hashify("custom"), default: _value)
                        defer {
                            _$store_value.setPersisted(value, forKey: #hashify("custom"))
                            _$observationRegistrar.didSet(self, keyPath: \\.value)
                        }
                        yield &value
                    }
                }

                private let _$observationRegistrar = Observation.ObservationRegistrar()

                internal nonisolated func access<Member>(
                    keyPath: KeyPath<TestClass, Member>
                ) {
                    _$observationRegistrar.access(self, keyPath: keyPath)
                }

                internal nonisolated func withMutation<Member, MutationResult>(
                    keyPath: KeyPath<TestClass, Member>,
                    _ mutation: () throws -> MutationResult
                ) rethrows -> MutationResult {
                    try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
                }

                private let className = "TestClass"

                private nonisolated func shouldNotifyObservers<Member>(_ lhs: Member, _ rhs: Member) -> Bool {
                    true
                }

                private nonisolated func shouldNotifyObservers<Member: Equatable>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs != rhs
                }

                private nonisolated func shouldNotifyObservers<Member: AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs !== rhs
                }

                private nonisolated func shouldNotifyObservers<Member: Equatable & AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs != rhs
                }

                private let _$store: any StorageBackend = (StorageType.local).backend

                private let _$store_value: any StorageBackend = (StorageType.localWith(suite: "test")).backend
            }
            """
        }
    }
}

@Suite("Cloud Storage Testing",.tags(.cloud))
struct CloudStorageTests {
    @Test("Does @Storage(type: .cloud) generate cloud sync code?")
    func storageWithCloudTypeTest() async throws {
        assertMacro(testMacros) {
            """
            @Storage(type: .cloud)
            class TestClass {
                var value: Bool = false
            }
            """
        } expansion: {
            """
            class TestClass {
                var value: Bool {
                    @storageRestrictions(initializes: _value)
                    init(initialValue) {
                        _value = initialValue
                    }
                    get {
                        _$startCloudSync()
                        access(keyPath: \\.value)
                        return _$store.persistedValue(forKey: #hashify("TestClass.value"), default: _value)
                    }
                    set {
                        if shouldNotifyObservers(_$store.persistedValue(forKey: #hashify("TestClass.value"), default: _value), newValue) {
                            withMutation(keyPath: \\.value) {
                                _$store.setPersisted(newValue, forKey: #hashify("TestClass.value"))
                            }
                        }
                    }
                    _modify {
                        access(keyPath: \\.value)
                        _$observationRegistrar.willSet(self, keyPath: \\.value)
                        var value = _$store.persistedValue(forKey: #hashify("TestClass.value"), default: _value)
                        defer {
                            _$store.setPersisted(value, forKey: #hashify("TestClass.value"))
                            _$observationRegistrar.didSet(self, keyPath: \\.value)
                        }
                        yield &value
                    }
                }

                private let _$observationRegistrar = Observation.ObservationRegistrar()

                internal nonisolated func access<Member>(
                    keyPath: KeyPath<TestClass, Member>
                ) {
                    _$observationRegistrar.access(self, keyPath: keyPath)
                }

                internal nonisolated func withMutation<Member, MutationResult>(
                    keyPath: KeyPath<TestClass, Member>,
                    _ mutation: () throws -> MutationResult
                ) rethrows -> MutationResult {
                    try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
                }

                private let className = "TestClass"

                private nonisolated func shouldNotifyObservers<Member>(_ lhs: Member, _ rhs: Member) -> Bool {
                    true
                }

                private nonisolated func shouldNotifyObservers<Member: Equatable>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs != rhs
                }

                private nonisolated func shouldNotifyObservers<Member: AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs !== rhs
                }

                private nonisolated func shouldNotifyObservers<Member: Equatable & AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs != rhs
                }

                private func _$cloudKeys(_ key: String) -> Bool {
                    switch key {
                    case #hashify("TestClass.value"):
                        _$observationRegistrar.willSet(self, keyPath: \\.value)
                        _$observationRegistrar.didSet(self, keyPath: \\.value)
                    default:
                        return false
                    }
                    return true
                }

                private var _$cloudNotificationObserver: (any NSObjectProtocol)? = nil

                private func _$startCloudSync() {
                    guard _$cloudNotificationObserver == nil else {
                        return
                    }
                    NSUbiquitousKeyValueStore.default.synchronize()
                    let _$weakRef = _$WeakSendableRef(self)
                    _$cloudNotificationObserver = NotificationCenter.default.addObserver(
                        forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                        object: NSUbiquitousKeyValueStore.default,
                        queue: .main
                    ) { notification in
                        guard let _$self = _$weakRef.value,
                        let userInfo = notification.userInfo,
                        let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else {
                            return
                        }
                        for key in changedKeys {
                            _ = _$self._$cloudKeys(key)
                        }
                    }
                }

                private let _$store: any StorageBackend = (StorageType.cloud).backend
            }
            """
        }
    }

    @Test("Does @Attribute(type:) override @Storage(type:)?")
    func attributeTypeOverrideTest() async throws {
        assertMacro(testMacros) {
            """
            @Storage(type: .cloud)
            class TestClass {
                var cloudValue: Bool = false

                @Attribute(type: .local, key: "localKey")
                var localValue: Bool = false
            }
            """
        } expansion: {
            """
            class TestClass {
                var cloudValue: Bool {
                    @storageRestrictions(initializes: _cloudValue)
                    init(initialValue) {
                        _cloudValue = initialValue
                    }
                    get {
                        _$startCloudSync()
                        access(keyPath: \\.cloudValue)
                        return _$store.persistedValue(forKey: #hashify("TestClass.cloudValue"), default: _cloudValue)
                    }
                    set {
                        if shouldNotifyObservers(_$store.persistedValue(forKey: #hashify("TestClass.cloudValue"), default: _cloudValue), newValue) {
                            withMutation(keyPath: \\.cloudValue) {
                                _$store.setPersisted(newValue, forKey: #hashify("TestClass.cloudValue"))
                            }
                        }
                    }
                    _modify {
                        access(keyPath: \\.cloudValue)
                        _$observationRegistrar.willSet(self, keyPath: \\.cloudValue)
                        var value = _$store.persistedValue(forKey: #hashify("TestClass.cloudValue"), default: _cloudValue)
                        defer {
                            _$store.setPersisted(value, forKey: #hashify("TestClass.cloudValue"))
                            _$observationRegistrar.didSet(self, keyPath: \\.cloudValue)
                        }
                        yield &value
                    }
                }
                var localValue: Bool {
                    @storageRestrictions(initializes: _localValue)
                    init(initialValue) {
                        _localValue = initialValue
                    }
                    get {
                        access(keyPath: \\.localValue)
                        return _$store_localValue.persistedValue(forKey: #hashify("localKey"), default: _localValue)
                    }
                    set {
                        if shouldNotifyObservers(_$store_localValue.persistedValue(forKey: #hashify("localKey"), default: _localValue), newValue) {
                            withMutation(keyPath: \\.localValue) {
                                _$store_localValue.setPersisted(newValue, forKey: #hashify("localKey"))
                            }
                        }
                    }
                    _modify {
                        access(keyPath: \\.localValue)
                        _$observationRegistrar.willSet(self, keyPath: \\.localValue)
                        var value = _$store_localValue.persistedValue(forKey: #hashify("localKey"), default: _localValue)
                        defer {
                            _$store_localValue.setPersisted(value, forKey: #hashify("localKey"))
                            _$observationRegistrar.didSet(self, keyPath: \\.localValue)
                        }
                        yield &value
                    }
                }

                private let _$observationRegistrar = Observation.ObservationRegistrar()

                internal nonisolated func access<Member>(
                    keyPath: KeyPath<TestClass, Member>
                ) {
                    _$observationRegistrar.access(self, keyPath: keyPath)
                }

                internal nonisolated func withMutation<Member, MutationResult>(
                    keyPath: KeyPath<TestClass, Member>,
                    _ mutation: () throws -> MutationResult
                ) rethrows -> MutationResult {
                    try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
                }

                private let className = "TestClass"

                private nonisolated func shouldNotifyObservers<Member>(_ lhs: Member, _ rhs: Member) -> Bool {
                    true
                }

                private nonisolated func shouldNotifyObservers<Member: Equatable>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs != rhs
                }

                private nonisolated func shouldNotifyObservers<Member: AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs !== rhs
                }

                private nonisolated func shouldNotifyObservers<Member: Equatable & AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs != rhs
                }

                private func _$cloudKeys(_ key: String) -> Bool {
                    switch key {
                    case #hashify("TestClass.cloudValue"):
                        _$observationRegistrar.willSet(self, keyPath: \\.cloudValue)
                        _$observationRegistrar.didSet(self, keyPath: \\.cloudValue)
                    default:
                        return false
                    }
                    return true
                }

                private var _$cloudNotificationObserver: (any NSObjectProtocol)? = nil

                private func _$startCloudSync() {
                    guard _$cloudNotificationObserver == nil else {
                        return
                    }
                    NSUbiquitousKeyValueStore.default.synchronize()
                    let _$weakRef = _$WeakSendableRef(self)
                    _$cloudNotificationObserver = NotificationCenter.default.addObserver(
                        forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                        object: NSUbiquitousKeyValueStore.default,
                        queue: .main
                    ) { notification in
                        guard let _$self = _$weakRef.value,
                        let userInfo = notification.userInfo,
                        let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else {
                            return
                        }
                        for key in changedKeys {
                            _ = _$self._$cloudKeys(key)
                        }
                    }
                }

                private let _$store: any StorageBackend = (StorageType.cloud).backend

                private let _$store_localValue: any StorageBackend = (StorageType.local).backend
            }
            """
        }
    }

    @Test("Does @Storage without cloud properties skip sync code?")
    func storageWithoutCloudSkipsSyncTest() async throws {
        assertMacro(testMacros) {
            """
            @Storage
            class TestClass {
                var value: Bool = false
            }
            """
        } expansion: {
            """
            class TestClass {
                var value: Bool {
                    @storageRestrictions(initializes: _value)
                    init(initialValue) {
                        _value = initialValue
                    }
                    get {
                        access(keyPath: \\.value)
                        return _$store.persistedValue(forKey: #hashify("TestClass.value"), default: _value)
                    }
                    set {
                        if shouldNotifyObservers(_$store.persistedValue(forKey: #hashify("TestClass.value"), default: _value), newValue) {
                            withMutation(keyPath: \\.value) {
                                _$store.setPersisted(newValue, forKey: #hashify("TestClass.value"))
                            }
                        }
                    }
                    _modify {
                        access(keyPath: \\.value)
                        _$observationRegistrar.willSet(self, keyPath: \\.value)
                        var value = _$store.persistedValue(forKey: #hashify("TestClass.value"), default: _value)
                        defer {
                            _$store.setPersisted(value, forKey: #hashify("TestClass.value"))
                            _$observationRegistrar.didSet(self, keyPath: \\.value)
                        }
                        yield &value
                    }
                }

                private let _$observationRegistrar = Observation.ObservationRegistrar()

                internal nonisolated func access<Member>(
                    keyPath: KeyPath<TestClass, Member>
                ) {
                    _$observationRegistrar.access(self, keyPath: keyPath)
                }

                internal nonisolated func withMutation<Member, MutationResult>(
                    keyPath: KeyPath<TestClass, Member>,
                    _ mutation: () throws -> MutationResult
                ) rethrows -> MutationResult {
                    try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
                }

                private let className = "TestClass"

                private nonisolated func shouldNotifyObservers<Member>(_ lhs: Member, _ rhs: Member) -> Bool {
                    true
                }

                private nonisolated func shouldNotifyObservers<Member: Equatable>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs != rhs
                }

                private nonisolated func shouldNotifyObservers<Member: AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs !== rhs
                }

                private nonisolated func shouldNotifyObservers<Member: Equatable & AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
                    lhs != rhs
                }

                private let _$store: any StorageBackend = (StorageType.local).backend
            }
            """
        }
    }
}

@Suite("Diagnostic Testing", .tags(.storage))
struct DiagnosticTests {
    @Test("Does @Storage on enum produce an error?")
    func storageOnEnumTest() async throws {
        assertMacro(testMacros) {
            """
            @Storage
            enum TestEnum {
                case a
            }
            """
        } diagnostics: {
            """
            @Storage
            ┬───────
            ╰─ 🛑 '@Storage' cannot be applied to enumeration type 'TestEnum' because enumerations cannot store properties
            enum TestEnum {
                case a
            }
            """
        }
    }

    @Test("Does @Storage on struct produce an error?")
    func storageOnStructTest() async throws {
        assertMacro(testMacros) {
            """
            @Storage
            struct TestStruct {
                var value: Bool = false
            }
            """
        } diagnostics: {
            """
            @Storage
            ┬───────
            ╰─ 🛑 '@Storage' cannot be applied to struct type 'TestStruct' because structs use value semantics, which is incompatible with observation and persistence
            struct TestStruct {
                var value: Bool = false
            }
            """
        }
    }

    @Test("Does @Storage on actor produce an error?")
    func storageOnActorTest() async throws {
        assertMacro(testMacros) {
            """
            @Storage
            actor TestActor {
                var value: Bool = false
            }
            """
        } diagnostics: {
            """
            @Storage
            ┬───────
            ╰─ 🛑 '@Storage' cannot be applied to actor type 'TestActor' because actor isolation is not yet supported
            actor TestActor {
                var value: Bool = false
            }
            """
        }
    }

    @Test("Does a stored property without type annotation produce an error?")
    func storedPropertyWithoutTypeAnnotationTest() async throws {
        assertMacro(testMacros) {
            """
            @_StoredProperty
            var value = false
            """
        } diagnostics: {
            """
            @_StoredProperty
            ╰─ 🛑 stored property 'value' requires an explicit type annotation to be persisted by '@Storage'
            var value = false
            """
        }
    }
}
#endif
