//
//  SwiftStorage.swift
//
//
//  Created by Keisuke Chinone on 2024/07/06.
//


// The Swift Programming Language
// https://docs.swift.org/swift-book
#if canImport(Observation) && canImport(Foundation)
@_exported import Observation
@_exported import Foundation
@_exported import Hashify

/// Macros to adapt persistence and observation to properties in a class
///
/// Add this macro to the class as follows
/// ```swift
/// @Storage
/// final class SomeClass {
///     var someValue: Bool
///
///     init() {
///         self.someValue = false
///     }
/// }
/// ```
/// When expanded, it looks like this
/// ```swift
/// final class SomeClass {
///     @_StoredProperty
///     var someValue: Bool
///
///     init() {
///         self.someValue = false
///     }
///
///     @Transient private let _$observationRegistrar = Observation.ObservationRegistrar()
///
///     internal nonisolated func access<Member>(
///         keyPath: KeyPath<SomeClass, Member>
///     ) {
///         _$observationRegistrar.access(self, keyPath: keyPath)
///     }
///
///     internal nonisolated func withMutation<Member, MutationResult>(
///         keyPath: KeyPath<SomeClass, Member>,
///         _ mutation: () throws -> MutationResult
///     ) rethrows -> MutationResult {
///         try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
///     }
///
///     @Transient private let className = "SomeClass"
/// }
/// ```
/// Use the ``Transient`` macro if there are properties you do not want to preserve. You can also use the [ObservationIgnored](https://developer.apple.com/documentation/observation/observationignored()) macro instead.
/// Use ``Attribute(_:)`` with `.ephemeral` for properties that should be observed but not persisted.
@attached(
    member,
    names: named(_$id), named(_$observationRegistrar), named(access), named(withMutation), named(className), named(shouldNotifyObservers), named(_$cloudKeys), named(_$cloudNotificationObserver), named(_$startCloudSync), named(_$store), arbitrary
)
@attached(memberAttribute)
@attached(extension, conformances: Observable)
public macro Storage(type: StorageType = .local) = #externalMacro(module: "SwiftStorageMacros", type: "StorageMacro")

/// Macro for specifying the property whose value is to be persisted
///
/// This property is automatically added by the Storage macro. It is not necessary to describe it.
@attached(accessor, names: named(init), named(get), named(set), named(_modify))
@attached(peer, names: prefixed(_))
public macro _StoredProperty(type: StorageType = .local) = #externalMacro(module: "SwiftStorageMacros", type: "StoredPropertyMacro")
/// Macro to customize storage attributes for a property
/// - Parameters:
///  - options: Storage attribute options (e.g., `.ephemeral` for observation-only properties)
///  - type: The storage type to use
///  - key: A key to associate values
///  - hashed: Whether to hash the key with `#hashify` for security (default: `true`)
///
/// Customize storage behavior as follows
/// ```swift
/// @Storage
/// final class SomeClass {
///     @Attribute(key: "SomeValue")
///     var someValue: Bool
///
///     @Attribute(key: "PlainKey", hashed: false)
///     var plainValue: Bool
///
///     @Attribute(.ephemeral)
///     var observedOnly: Bool
///
///     init() {
///         self.someValue = false
///         self.plainValue = false
///         self.observedOnly = false
///     }
/// }
/// ```
@attached(peer)
public macro Attribute(_ options: StorageAttributeOption..., type: StorageType = .local, key: String = "", hashed: Bool = true) = #externalMacro(module: "SwiftStorageMacros", type: "AttributeMacro")

/// Macro for specifying properties that are not observed and persisted
///
/// Add the following to the properties that you want to make non-persistent
/// ```swift
/// @Storage
/// final class SomeClass {
///     @Transient
///     var someValue: Bool
///
///     init() {
///         self.someValue = false
///     }
/// }
/// ```
@attached(accessor, names: named(willSet))
public macro Transient() = #externalMacro(module: "SwiftStorageMacros", type: "TransientMacro")
#endif
