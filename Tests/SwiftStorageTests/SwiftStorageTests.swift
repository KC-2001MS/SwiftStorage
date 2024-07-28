//
//  SwiftStorageTests.swift
//  SwiftStorage
//  
//  Created by Keisuke Chinone on 2024/07/29.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

#if canImport(SwiftStorageMacros)
import SwiftStorageMacros

extension Tag {
    @Tag static var storage: Self
    @Tag static var localStorageProperty: Self
    @Tag static var attribute: Self
    @Tag static var transient: Self
    
    @Tag static var executable: Self
    @Tag static var normalBehavior: Self
}

let testMacros: [String: Macro.Type] = [
    "Storage": StorageMacro.self,
    "LocalStorageProperty": LocalStoragePropertyMacro.self,
    "Attribute": AttributeMacro.self,
    "Transient": TransientMacro.self,
]

@Suite("Storage Macro Testing",.tags(.storage))
struct StorageMacrotests {
    @Test("Does it work as expected with variables that do not have macros attached?")
    func variableExpansionWithoutAMacroTests() async throws {
        assertMacroExpansion(
            """
            @Storage
            class TestClass {
                var value: Bool = false
            }
            """,
            expandedSource: """
            class TestClass {
                @LocalStorageProperty
                var value: Bool = false
                @Transient private let _$observationRegistrar = Observation.ObservationRegistrar()

                internal nonisolated func access<Member>(
                    keyPath: KeyPath<SettingsObject, Member>
                ) {
                    _$observationRegistrar.access(self, keyPath: keyPath)
                }

                internal nonisolated func withMutation<Member, MutationResult>(
                    keyPath: KeyPath<SettingsObject, Member>,
                    _ mutation: () throws -> MutationResult
                ) rethrows -> MutationResult {
                    try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
                }

                @Transient private let className = "TestClass"
            }
            """,
            macros: testMacros
        )
    }
    
    @Test("Does the constant work as expected?")
    func constantTesting() async throws {
        assertMacroExpansion(
            """
            @Storage
            class TestClass {
                let value: Bool = false
            }
            """,
            expandedSource: """
            class TestClass {
                let value: Bool = false
                @Transient private let _$observationRegistrar = Observation.ObservationRegistrar()

                internal nonisolated func access<Member>(
                    keyPath: KeyPath<SettingsObject, Member>
                ) {
                    _$observationRegistrar.access(self, keyPath: keyPath)
                }

                internal nonisolated func withMutation<Member, MutationResult>(
                    keyPath: KeyPath<SettingsObject, Member>,
                    _ mutation: () throws -> MutationResult
                ) rethrows -> MutationResult {
                    try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
                }

                @Transient private let className = "TestClass"
            }
            """,
            macros: testMacros
        )
    }
    
    @Test("Does the variable with Transient macro work as expected?")
    func variableWithTransientMacroTesting() async throws {
        assertMacroExpansion(
            """
            @Storage
            class TestClass {
                @Transient
                var value: Bool = false
            }
            """,
            expandedSource: """
            class TestClass {
                @Transient
                var value: Bool = false
                @Transient private let _$observationRegistrar = Observation.ObservationRegistrar()

                internal nonisolated func access<Member>(
                    keyPath: KeyPath<SettingsObject, Member>
                ) {
                    _$observationRegistrar.access(self, keyPath: keyPath)
                }

                internal nonisolated func withMutation<Member, MutationResult>(
                    keyPath: KeyPath<SettingsObject, Member>,
                    _ mutation: () throws -> MutationResult
                ) rethrows -> MutationResult {
                    try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
                }

                @Transient private let className = "TestClass"
            }
            """,
            macros: testMacros
        )
    }
    
    @Test("Does the variable with ObservationIgnored macro work as expected?")
    func variableWithObservationIgnoredMacroTesting() async throws {
        assertMacroExpansion(
            """
            @Storage
            class TestClass {
                @ObservationIgnored
                var value: Bool = false
            }
            """,
            expandedSource: """
            class TestClass {
                @ObservationIgnored
                var value: Bool = false
                @Transient private let _$observationRegistrar = Observation.ObservationRegistrar()

                internal nonisolated func access<Member>(
                    keyPath: KeyPath<SettingsObject, Member>
                ) {
                    _$observationRegistrar.access(self, keyPath: keyPath)
                }

                internal nonisolated func withMutation<Member, MutationResult>(
                    keyPath: KeyPath<SettingsObject, Member>,
                    _ mutation: () throws -> MutationResult
                ) rethrows -> MutationResult {
                    try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
                }

                @Transient private let className = "TestClass"
            }
            """,
            macros: testMacros
        )
    }
}

@Suite("LocalStorageProperty Macro Testing",.tags(.localStorageProperty))
struct LocalStorageProperty {
    @Test("Does the variable with LocalStorageProperty macro work as expected?")
    func variableWithLocalStoragePropertyMacroTesting() async throws {
        assertMacroExpansion(
            """
            @LocalStorageProperty
            var value: Bool
            """,
            expandedSource: """
            @LocalStorageProperty
            var value: Bool
            {
                @storageRestrictions(initializes: _value)
                init(initialValue) {
                    _value = initialValue
                }
                get {
                    access(keyPath: \\.value)
                    return UserDefaults.standard.value(forKey: "\\(className).value") as? Bool ?? _value
                }
                set {
                    withMutation(keyPath: \\.isObservationSupported) {
                        UserDefaults.standard.set(newValue, forKey: "\\(className).value")
                        _value = newValue
                    }
                }
                _modify {
                    access(keyPath: \\.isObservationSupported)
                    _$observationRegistrar.willSet(self, keyPath: \\.value)
                    defer {
                        _$observationRegistrar.didSet(self, keyPath: \\.value)
                    }
                    yield &_value
                }
            }
            @Transient private  var _value: Bool
            """,
            macros: testMacros
        )
    }
    
    @Test("Does the constant with LocalStorageProperty macro work as expected?")
    func constantWithLocalStoragePropertyMacroTesting() async throws {
        assertMacroExpansion(
            """
            @LocalStorageProperty
            let value: Bool
            """,
            expandedSource: """
            let value: Bool
            """,
            macros: testMacros
        )
    }
}

@Suite("Attribute Macro Testing",.tags(.attribute))
struct AttributeTests {
    @Test("Does the variable with Attribute macro work as expected?")
    func variableWitAttributeMacroTesting() async throws {
        assertMacroExpansion(
            """
            @LocalStorageProperty
            @Attribute(key: "value")
            var value: Bool
            """,
            expandedSource: """
            @LocalStorageProperty
            var value: Bool
            {
                @storageRestrictions(initializes: _value)
                init(initialValue) {
                    _value = initialValue
                }
                get {
                    access(keyPath: \\.value)
                    return UserDefaults.standard.value(forKey: "value") as? Bool ?? _value
                }
                set {
                    withMutation(keyPath: \\.isObservationSupported) {
                        UserDefaults.standard.set(newValue, forKey: "value")
                        _value = newValue
                    }
                }
                _modify {
                    access(keyPath: \\.isObservationSupported)
                    _$observationRegistrar.willSet(self, keyPath: \\.value)
                    defer {
                        _$observationRegistrar.didSet(self, keyPath: \\.value)
                    }
                    yield &_value
                }
            }
            @Transient private  var _value: Bool
            """,
            macros: testMacros
        )
    }
    
    @Test("Does the constant with Attribute macro work as expected?")
    func constantWithAttributeMacroTesting() async throws {
        assertMacroExpansion(
            """
            @LocalStorageProperty
            @Attribute(key: "value")
            let value: Bool
            """,
            expandedSource: """
            let value: Bool
            """,
            macros: testMacros
        )
    }
}

@Suite("Transient Macro Testing",.tags(.transient))
struct Transient {
    @Test("Does the variable with Transient macro work as expected?")
    func variableWithTransientMacroTesting() async throws {
        assertMacroExpansion(
            """
            @Transient
            var value: Bool
            """,
            expandedSource: """
            var value: Bool
            """,
            macros: testMacros
        )
    }
    
    @Test("Does the constant with Transient macro work as expected?")
    func constantWithTransientMacroTesting() async throws {
        assertMacroExpansion(
            """
            @Transient
            let value: Bool
            """,
            expandedSource: """
            let value: Bool
            """,
            macros: testMacros
        )
    }
}
#endif
